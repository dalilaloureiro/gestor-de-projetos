{-|
Module      : Domain
Description : Núcleo funcional puro - regras de domínio e operações sobre o modelo


Funções puras que implementam a lógica de domínio:
- Criação e validação de entidades
- Consultas (pesquisa por ID, listagens)
- Filtros combináveis
- Cálculos de progresso (recursão justificada)
- Deteção de bloqueios por dependências
- Transições de estado válidas

Todas as funções são puras (sem IO) e usam Maybe/Either para
tratamento explícito de ausência e erro.
-}
module Domain
  ( -- * Criação de entidades (smart constructors)
    mkProject
  , mkSprint
  , mkTask
  , mkMember
    -- * Consultas básicas (retornam Maybe)
  , findProject
  , findSprint
  , findTask
  , findMember
    -- * Listagens
  , listProjects
  , listSprintsOfProject
  , listTasksOfSprint
  , listMembersOfProject
    -- * Filtros simples (predicados combináveis)
  , filterByStatus
  , filterByPriority
  , filterByAssignee
    -- * Recursão justificada #1: progresso de sprint
  , progressSprint
    -- * Recursão justificada #2: progresso de projeto
  , progressProject
    -- * Recursão justificada #3: verificação de bloqueios
  , isBlocked
  , allDependenciesDone
    -- * Transições de estado
  , validTransitions
  , canTransition
  , transitionTask
    -- * Formatação pura
  , showStatus
  , showPriority
  ) where

import Data.List (find)
import Model

-- Smart constructors ----------------------------------------------------------

-- | Cria um projeto válido (validação básica: nome não vazio, ID > 0)
mkProject :: ProjectId -> String -> String -> [Member] -> Either String Project
mkProject pid name desc members
  | pid <= 0           = Left "ID do projeto deve ser positivo"
  | null name          = Left "Nome do projeto não pode ser vazio"
  | otherwise          = Right $ Project pid name desc members []

-- | Cria um sprint válido
mkSprint :: SprintId -> String -> String -> String -> Either String Sprint
mkSprint sid name start end
  | sid <= 0      = Left "ID do sprint deve ser positivo"
  | null name     = Left "Nome do sprint não pode ser vazio"
  | null start    = Left "Data de início não pode ser vazia"
  | null end      = Left "Data de fim não pode ser vazia"
  | otherwise     = Right $ Sprint sid name start end []

-- | Cria uma tarefa válida
mkTask :: TaskId -> String -> String -> Priority -> [TaskId] -> Either String Task
mkTask tid title desc priority deps
  | tid <= 0      = Left "ID da tarefa deve ser positivo"
  | null title    = Left "Título da tarefa não pode ser vazio"
  | otherwise     = Right $ Task tid title desc ToDo priority Nothing deps

-- | Cria um membro
mkMember :: MemberId -> String -> Either String Member
mkMember mid name
  | mid <= 0   = Left "ID do membro deve ser positivo"
  | null name  = Left "Nome do membro não pode ser vazio"
  | otherwise  = Right $ Member mid name

-- Consultas básicas -----------------------------------------------------------

-- | Encontra um projeto por ID
findProject :: ProjectId -> [Project] -> Maybe Project
findProject pid = find ((== pid) . projectId)

-- | Encontra um sprint por ID dentro de um projeto
findSprint :: SprintId -> Project -> Maybe Sprint
findSprint sid project = find ((== sid) . sprintId) (projectSprints project)

-- | Encontra uma tarefa por ID dentro de um sprint
findTask :: TaskId -> Sprint -> Maybe Task
findTask tid sprint = find ((== tid) . taskId) (sprintTasks sprint)

-- | Encontra um membro por ID dentro de um projeto
findMember :: MemberId -> Project -> Maybe Member
findMember mid project = find ((== mid) . memberId) (projectMembers project)

-- Listagens -------------------------------------------------------------------

-- | Lista todos os projetos
listProjects :: [Project] -> [Project]
listProjects = id

-- | Lista sprints de um projeto
listSprintsOfProject :: Project -> [Sprint]
listSprintsOfProject = projectSprints

-- | Lista tarefas de um sprint
listTasksOfSprint :: Sprint -> [Task]
listTasksOfSprint = sprintTasks

-- | Lista membros de um projeto
listMembersOfProject :: Project -> [Member]
listMembersOfProject = projectMembers

-- Filtros simples (predicados) ------------------------------------------------

-- | Filtra tarefas por estado
filterByStatus :: TaskStatus -> [Task] -> [Task]
filterByStatus status = filter (\t -> taskStatus t == status)

-- | Filtra tarefas por prioridade
filterByPriority :: Priority -> [Task] -> [Task]
filterByPriority priority = filter (\t -> taskPriority t == priority)

-- | Filtra tarefas por responsável
filterByAssignee :: MemberId -> [Task] -> [Task]
filterByAssignee mid = filter (\t -> taskAssignee t == Just mid)

-- Recursão justificada #1: progresso de sprint --------------------------------

-- | Calcula o progresso de um sprint (percentagem de tarefas 'Done').
--   Justificação: percorre a lista de tarefas recursivamente para contar
--   quantas estão 'Done' e o total. Não usa fold para demonstrar recursão
--   estrutural explícita sobre listas (requisito da Fase 1).
progressSprint :: Sprint -> Double
progressSprint sprint =
  let tasks = sprintTasks sprint
      (done, total) = countDoneAndTotal tasks
  in if total == 0 then 0.0 else fromIntegral done / fromIntegral total * 100.0

-- | Auxiliar recursivo: conta tarefas 'Done' e total.
--   Recursão estrutural sobre a lista de tarefas.
countDoneAndTotal :: [Task] -> (Int, Int)
countDoneAndTotal [] = (0, 0)
countDoneAndTotal (t:ts) =
  let (done, total) = countDoneAndTotal ts
  in if taskStatus t == Done
        then (done + 1, total + 1)
        else (done, total + 1)

-- Recursão justificada #2: progresso de projeto -------------------------------

-- | Calcula o progresso de um projeto (média do progresso dos sprints).
--   Justificação: recursão sobre a lista de sprints do projeto,
--   reutilizando 'progressSprint' para cada sprint.
progressProject :: Project -> Double
progressProject project =
  case sumSprintProgress (projectSprints project) of
    (_, 0) -> 0.0
    (total, count) -> total / fromIntegral count

-- | Percorre recursivamente os sprints para somar o progresso e contar quantos existem.
sumSprintProgress :: [Sprint] -> (Double, Int)
sumSprintProgress [] = (0.0, 0)
sumSprintProgress (s:ss) =
  let (total, count) = sumSprintProgress ss
  in (progressSprint s + total, count + 1)

-- Recursão justificada #3: verificação de bloqueios ---------------------------

-- | Verifica se uma tarefa está bloqueada (tem dependências não concluídas).
--   Justificação: percorre a lista de dependências recursivamente,
--   consultando o estado de cada dependência na lista de todas as tarefas.
isBlocked :: TaskId -> [Task] -> Bool
isBlocked tid allTasks =
  case findTaskById tid allTasks of
    Nothing -> False  -- tarefa não existe, não está bloqueada
    Just task -> not (allDependenciesDone (taskDependsOn task) allTasks)

-- | Verifica se todas as dependências (lista de TaskId) estão 'Done'.
--   Recursão estrutural sobre a lista de IDs de dependência.
allDependenciesDone :: [TaskId] -> [Task] -> Bool
allDependenciesDone [] _ = True
allDependenciesDone (depId:deps) allTasks =
  case findTaskById depId allTasks of
    Nothing   -> False  -- dependência inexistente considera-se não feita
    Just dep  -> taskStatus dep == Done && allDependenciesDone deps allTasks

-- | Busca auxiliar por TaskId numa lista de tarefas (recursiva)
findTaskById :: TaskId -> [Task] -> Maybe Task
findTaskById tid = find ((== tid) . taskId)

-- Transições de estado --------------------------------------------------------

-- | Transições válidas: ToDo -> InProgress -> Review -> Done
validTransitions :: TaskStatus -> [TaskStatus]
validTransitions ToDo        = [InProgress]
validTransitions InProgress  = [Review, ToDo]       -- pode voltar para ToDo
validTransitions Review      = [Done, InProgress]   -- pode voltar para InProgress
validTransitions Done        = []                   -- estado terminal

-- | Verifica se uma transição é válida
canTransition :: TaskStatus -> TaskStatus -> Bool
canTransition from to = to `elem` validTransitions from

-- | Tenta fazer a transição de estado de uma tarefa
--   Retorna Either com erro ou a tarefa atualizada
transitionTask :: Task -> TaskStatus -> Either String Task
transitionTask task newStatus
  | canTransition (taskStatus task) newStatus = Right task { taskStatus = newStatus }
  | otherwise = Left $ "Transição inválida: " ++ show (taskStatus task) ++ " -> " ++ show newStatus

-- Formatação pura -------------------------------------------------------------

-- | Representação textual do estado
showStatus :: TaskStatus -> String
showStatus ToDo       = "📋 ToDo"
showStatus InProgress = "🔄 InProgress"
showStatus Review     = "👀 Review"
showStatus Done       = "✅ Done"

-- | Representação textual da prioridade
showPriority :: Priority -> String
showPriority Low      = "🟢 Low"
showPriority Medium   = "🟡 Medium"
showPriority High     = "🟠 High"
showPriority Critical = "🔴 Critical"