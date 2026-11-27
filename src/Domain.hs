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
    -- * Predicados combináveis
  , isStatus
  , isPriority
  , isAssignee
  , matchesAll
    -- * Filtros
  , filterBy
  , filterByStatus
  , filterByPriority
  , filterByAssignee
    -- * Pipelines de transformação
  , projectTasks
  , taskTitles
  , taskTitlesByStatus
  , tasksOfMember
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
  , pendingDependencies
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

-- Predicados ------------------------------------------------------------------

-- | A tarefa está no estado indicado?
--   Composição: extrai o campo e compara-o.
isStatus :: TaskStatus -> Task -> Bool
isStatus status = (== status) . taskStatus

-- | A tarefa tem a prioridade indicada?
isPriority :: Priority -> Task -> Bool
isPriority priority = (== priority) . taskPriority

-- | A tarefa está atribuída ao membro indicado?
isAssignee :: MemberId -> Task -> Bool
isAssignee mid = (== Just mid) . taskAssignee

-- | Combina vários predicados num só: a tarefa tem de satisfazer todos.
--   HOF: recebe uma lista de funções e devolve uma função. Sem predicados,
--   qualquer tarefa é aceite.
matchesAll :: [Task -> Bool] -> Task -> Bool
matchesAll predicates task = all ($ task) predicates

-- Filtros ---------------------------------------------------------------------

-- | Filtro genérico: o critério é recebido como função (HOF).
filterBy :: (Task -> Bool) -> [Task] -> [Task]
filterBy = filter

-- | Filtra tarefas por estado
filterByStatus :: TaskStatus -> [Task] -> [Task]
filterByStatus = filterBy . isStatus

-- | Filtra tarefas por prioridade
filterByPriority :: Priority -> [Task] -> [Task]
filterByPriority = filterBy . isPriority

-- | Filtra tarefas por responsável
filterByAssignee :: MemberId -> [Task] -> [Task]
filterByAssignee = filterBy . isAssignee

-- Pipelines de transformação --------------------------------------------------

-- | Todas as tarefas de um projeto, pela ordem dos sprints.
--   'concatMap' aplica 'sprintTasks' a cada sprint e junta as listas.
projectTasks :: Project -> [Task]
projectTasks = concatMap sprintTasks . projectSprints

-- | Títulos das tarefas. 'map' porque a lista mantém o tamanho e a ordem.
taskTitles :: [Task] -> [String]
taskTitles = map taskTitle

-- | Títulos das tarefas num dado estado: pipeline @map f . filter p@.
taskTitlesByStatus :: TaskStatus -> [Task] -> [String]
taskTitlesByStatus status = map taskTitle . filter (isStatus status)

-- | Tarefas de um membro em todos os sprints do projeto.
tasksOfMember :: MemberId -> Project -> [Task]
tasksOfMember mid = filterByAssignee mid . projectTasks

-- Prioridade efetiva ----------------------------------------------------------

-- | Sobe um nível quando faltam três dias ou menos, sem passar de 4 (Critical).
effectivePriority :: Task -> Int -> Priority
effectivePriority task daysRemaining
  | daysRemaining > 3 = taskPriority task
  | otherwise = min 4 (taskPriority task + 1)

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
validateDependencies depIds allTasks = check (missingDependencies depIds allTasks)
  where
    check [] = Right depIds
    check (badId : _) = Left ("ID de dependência inexistente: " ++ show badId)

-- | IDs de dependência que não correspondem a nenhuma tarefa existente.
missingDependencies :: [TaskId] -> [Task] -> [TaskId]
missingDependencies [] _ = []
missingDependencies (depId : depIds) allTasks
  | noTask (findTaskById depId allTasks) = depId : missingDependencies depIds allTasks
  | otherwise = missingDependencies depIds allTasks
  where
    noTask Nothing = True
    noTask (Just _) = False

-- | Conta tarefas num estado específico percorrendo a lista com foldr.
countByStatus :: TaskStatus -> [Task] -> Int
countByStatus status = foldr countMatching 0
  where
    countMatching :: Task -> Int -> Int
    countMatching task count
      | taskStatus task == status = count + 1
      | otherwise = count

-- | Soma as prioridades das tarefas (escala de 1 a 4) usando foldr.
totalPriorityScore :: [Task] -> Int
totalPriorityScore = foldr addPriorityScore 0
  where
    addPriorityScore :: Task -> Int -> Int
    addPriorityScore task total = taskPriority task + total

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

-- | Dependências da tarefa que ainda não estão satisfeitas, pela ordem declarada.
--   Uma dependência conta como satisfeita se existir na lista e estiver 'Done'.
--   Recursão estrutural sobre a lista de IDs (percorre uma vez, sem inverter).
pendingDependencies :: Task -> [Task] -> [TaskId]
pendingDependencies task allTasks = pending (taskDependsOn task)
  where
    pending [] = []
    pending (depId : depIds)
      | satisfied depId = pending depIds
      | otherwise = depId : pending depIds

    satisfied depId = isDone (findTaskById depId allTasks)
    isDone Nothing = False
    isDone (Just dep) = taskStatus dep == Done

-- | Uma tarefa está bloqueada quando tem pelo menos uma dependência por satisfazer.
--   Uma tarefa que não existe não está bloqueada.
isBlocked :: TaskId -> [Task] -> Bool
isBlocked tid allTasks = blocked (findTaskById tid allTasks)
  where
    blocked Nothing = False
    blocked (Just task) = not (null (pendingDependencies task allTasks))

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

-- | Representação textual da prioridade (1 = Low ... 4 = Critical).
showPriority :: Priority -> String
showPriority 1 = "Low"
showPriority 2 = "Medium"
showPriority 3 = "High"
showPriority 4 = "Critical"
showPriority _ = "desconhecida"
