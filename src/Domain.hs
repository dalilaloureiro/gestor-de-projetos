{-|
Module      : Domain
Description : Núcleo funcional puro - consultas, listagens, filtros e recursão


Funções puras que implementam as regras de domínio da Fase 1:
- Consultas por ID (retornam Maybe)
- Listagens de entidades
- Filtros por estado, prioridade e responsável
- Cálculos de progresso (recursão justificada)
- Deteção de bloqueios por dependências (recursão justificada)
- Formatação textual de estados e prioridades

Todas as funções são puras (sem IO) e usam Maybe para
tratamento explícito de ausência.
-}
module Domain
  ( -- * Consultas básicas (retornam Maybe)
    findProject
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
    -- * Prioridade efetiva
  , effectivePriority
    -- * Transições de estado
  , validTransitions
  , canTransition
  , transitionTask
  , validateDependencies
    -- * Agregações
  , countByStatus
  , totalPriorityScore
    -- * Recursão justificada #1: progresso de sprint
  , progressSprint
    -- * Recursão justificada #2: progresso de projeto
  , progressProject
    -- * Recursão justificada #3: verificação de bloqueios
  , isBlocked
  , allDependenciesDone
    -- * Formatação pura
  , showStatus
  , showPriority
  ) where

import Data.List (find)
import Model

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

-- | Sobe um nível de prioridade quando faltam três dias ou menos para o fim.
effectivePriority :: Task -> Int -> Priority
effectivePriority task daysRemaining
  | daysRemaining > 3 = taskPriority task
  | otherwise =
      case taskPriority task of
        Low      -> Medium
        Medium   -> High
        High     -> Critical
        Critical -> Critical

-- | Pares de estados cuja transição é permitida.
validTransitions :: [(TaskStatus, TaskStatus)]
validTransitions =
  [ (ToDo, InProgress)
  , (InProgress, Review)
  , (Review, Done)
  ]

-- | Verifica se a transição entre dois estados é permitida.
canTransition :: TaskStatus -> TaskStatus -> Bool
canTransition current target = (current, target) `elem` validTransitions

-- | Atualiza o estado de uma tarefa ou devolve uma mensagem de erro.
transitionTask :: Task -> TaskStatus -> Either String Task
transitionTask task target
  | canTransition (taskStatus task) target =
      Right (task { taskStatus = target })
  | otherwise =
      Left
        ( "Transição de estado inválida: "
            ++ showStatus (taskStatus task)
            ++ " -> "
            ++ showStatus target
        )

-- | Confirma que todos os IDs de dependência existem na lista de tarefas.
validateDependencies :: [TaskId] -> [Task] -> Either String [TaskId]
validateDependencies [] _ = Right []
validateDependencies (depId:depIds) allTasks =
  case findTaskById depId allTasks of
    Nothing ->
      Left ("ID de dependência inexistente: " ++ show depId)
    Just _ ->
      case validateDependencies depIds allTasks of
        Left message -> Left message
        Right validIds -> Right (depId : validIds)

-- | Conta tarefas num estado específico percorrendo a lista com foldr.
countByStatus :: TaskStatus -> [Task] -> Int
countByStatus status = foldr countMatching 0
  where
    countMatching :: Task -> Int -> Int
    countMatching task count
      | taskStatus task == status = count + 1
      | otherwise = count

-- | Soma a pontuação das prioridades das tarefas usando foldr.
totalPriorityScore :: [Task] -> Int
totalPriorityScore = foldr addPriorityScore 0
  where
    addPriorityScore :: Task -> Int -> Int
    addPriorityScore task total =
      priorityScore (taskPriority task) + total

    priorityScore :: Priority -> Int
    priorityScore Low = 1
    priorityScore Medium = 2
    priorityScore High = 3
    priorityScore Critical = 4

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

-- Formatação pura -------------------------------------------------------------

-- | Representação textual do estado
showStatus :: TaskStatus -> String
showStatus ToDo       = "ToDo"
showStatus InProgress = "InProgress"
showStatus Review     = "Review"
showStatus Done       = "Done"

-- | Representação textual da prioridade
showPriority :: Priority -> String
showPriority Low      = "Low"
showPriority Medium   = "Medium"
showPriority High     = "High"
showPriority Critical = "Critical"
