{-|
Module      : Spec
Description : Suite de testes para o núcleo funcional (Domain)

Testes das funções puras principais:
- Consultas (findProject, findSprint, findTask, findMember)
- Filtros (por estado, prioridade e responsável)
- Recursão justificada: progressSprint, progressProject, isBlocked
- Formatação (showStatus, showPriority)
- Dados de demonstração (módulo Seed) usados como cenário real

Casos normais, limites (listas vazias) e consultas sem resultado.

Framework: HUnit (simples, sem dependências pesadas)
-}
module Main (main) where

import Test.HUnit
import Model
import qualified Domain
import Seed
import System.Exit (exitFailure)

-- Dados de teste mínimos ------------------------------------------------------

testMember1 :: Member
testMember1 = Member 1 "Alice"

testMember2 :: Member
testMember2 = Member 2 "Bob"

testProject :: Project
testProject = Project 1 "Projeto Teste" "Descrição" [testMember1, testMember2] []

testSprint :: Sprint
testSprint = Sprint 1 "Sprint 1" "2024-01-01" "2024-01-14" []

testTaskTodo :: Task
testTaskTodo = Task 1 "Tarefa 1" "Desc" ToDo Medium Nothing []

testTaskDone :: Task
testTaskDone = Task 2 "Tarefa 2" "Desc" Done High Nothing []

-- Acesso aos dados de demonstração (o seed tem sempre 2 sprints)
seedSprint1 :: Sprint
seedSprint1 = case sprints of
  (s:_) -> s
  []    -> error "Seed sem sprints"

seedSprint2 :: Sprint
seedSprint2 = case sprints of
  (_:s:_) -> s
  _       -> error "Seed sem o segundo sprint"

-- Testes ---------------------------------------------------------------------

testFindProject :: Test
testFindProject = TestCase $ do
  let projectList = [testProject]
  assertEqual "findProject existente" (Just testProject) (Domain.findProject 1 projectList)
  assertEqual "findProject inexistente" Nothing (Domain.findProject 999 projectList)

testFindSprint :: Test
testFindSprint = TestCase $ do
  let proj = testProject { projectSprints = [testSprint] }
  assertEqual "findSprint existente" (Just testSprint) (Domain.findSprint 1 proj)
  assertEqual "findSprint inexistente" Nothing (Domain.findSprint 999 proj)

testFindTask :: Test
testFindTask = TestCase $ do
  let sprint = testSprint { sprintTasks = [testTaskTodo, testTaskDone] }
  assertEqual "findTask existente" (Just testTaskTodo) (Domain.findTask 1 sprint)
  assertEqual "findTask inexistente" Nothing (Domain.findTask 999 sprint)

testFindMember :: Test
testFindMember = TestCase $ do
  assertEqual "findMember existente" (Just testMember2) (Domain.findMember 2 testProject)
  assertEqual "findMember inexistente" Nothing (Domain.findMember 999 testProject)

testListagens :: Test
testListagens = TestCase $ do
  let proj = testProject { projectSprints = [testSprint] }
  assertEqual "listProjects" [testProject] (Domain.listProjects [testProject])
  assertEqual "listSprintsOfProject" [testSprint] (Domain.listSprintsOfProject proj)
  assertEqual "listMembersOfProject" [testMember1, testMember2] (Domain.listMembersOfProject proj)
  assertEqual "listTasksOfSprint vazio" [] (Domain.listTasksOfSprint testSprint)

testFilterByStatus :: Test
testFilterByStatus = TestCase $ do
  let tasks = [testTaskTodo, testTaskDone]
  assertEqual "filterByStatus ToDo" [testTaskTodo] (Domain.filterByStatus ToDo tasks)
  assertEqual "filterByStatus Done" [testTaskDone] (Domain.filterByStatus Done tasks)
  assertEqual "filterByStatus vazio" [] (Domain.filterByStatus Review tasks)

testFilterByPriority :: Test
testFilterByPriority = TestCase $ do
  let tasks = [testTaskTodo, testTaskDone]
  assertEqual "filterByPriority Medium" [testTaskTodo] (Domain.filterByPriority Medium tasks)
  assertEqual "filterByPriority High" [testTaskDone] (Domain.filterByPriority High tasks)

testFilterByAssignee :: Test
testFilterByAssignee = TestCase $ do
  let taskAssigned = testTaskTodo { taskAssignee = Just 1 }
  let tasks = [taskAssigned, testTaskDone]
  assertEqual "filterByAssignee 1" [taskAssigned] (Domain.filterByAssignee 1 tasks)
  assertEqual "filterByAssignee 999" [] (Domain.filterByAssignee 999 tasks)

testEffectivePriority :: Test
testEffectivePriority = TestCase $ do
  assertEqual "mais de três dias mantém prioridade"
    Medium (Domain.effectivePriority testTaskTodo 4)
  assertEqual "três dias sobe Medium para High"
    High (Domain.effectivePriority testTaskTodo 3)
  assertEqual "prioridade Low sobe para Medium"
    Medium (Domain.effectivePriority (testTaskTodo { taskPriority = Low }) 2)
  assertEqual "prioridade High sobe para Critical"
    Critical (Domain.effectivePriority (testTaskTodo { taskPriority = High }) 1)
  assertEqual "Critical não sobe acima de Critical"
    Critical (Domain.effectivePriority (testTaskTodo { taskPriority = Critical }) 0)
  assertEqual "tarefa atrasada também satisfaz dias restantes <= 3"
    High (Domain.effectivePriority testTaskTodo (-1))

testTransitionTask :: Test
testTransitionTask = TestCase $ do
  assertBool "ToDo -> InProgress permitido"
    (Domain.canTransition ToDo InProgress)
  assertBool "InProgress -> Review permitido"
    (Domain.canTransition InProgress Review)
  assertBool "Review -> Done permitido"
    (Domain.canTransition Review Done)
  assertBool "não permite saltar estados"
    (not (Domain.canTransition ToDo Done))
  assertEqual "transição válida atualiza apenas o estado"
    (Right (testTaskTodo { taskStatus = InProgress }))
    (Domain.transitionTask testTaskTodo InProgress)
  assertEqual "repetir o estado atual é inválido"
    (Left "Transição de estado inválida: ToDo -> ToDo")
    (Domain.transitionTask testTaskTodo ToDo)
  assertEqual "não permite voltar atrás"
    (Left "Transição de estado inválida: InProgress -> ToDo")
    (Domain.transitionTask (testTaskTodo { taskStatus = InProgress }) ToDo)
  assertEqual "transição inválida explica o erro"
    (Left "Transição de estado inválida: ToDo -> Done")
    (Domain.transitionTask testTaskTodo Done)

testCountByStatus :: Test
testCountByStatus = TestCase $ do
  let tasks = [testTaskTodo, testTaskDone]
  assertEqual "conta tarefas ToDo" 1 (Domain.countByStatus ToDo tasks)
  assertEqual "conta tarefas Done" 1 (Domain.countByStatus Done tasks)
  assertEqual "estado sem tarefas dá zero" 0 (Domain.countByStatus Review tasks)
  assertEqual "lista vazia dá zero" 0 (Domain.countByStatus Done [])

testTotalPriorityScore :: Test
testTotalPriorityScore = TestCase $ do
  let tasks =
        [ testTaskTodo { taskPriority = Low }
        , testTaskTodo { taskPriority = Medium }
        , testTaskTodo { taskPriority = High }
        , testTaskTodo { taskPriority = Critical }
        ]
  assertEqual "soma os pontos das quatro prioridades" 10
    (Domain.totalPriorityScore tasks)
  assertEqual "lista vazia tem pontuação zero" 0
    (Domain.totalPriorityScore [])

testValidateDependencies :: Test
testValidateDependencies = TestCase $ do
  let tasks = [testTaskTodo, testTaskDone]
  assertEqual "dependências existentes são devolvidas"
    (Right [2, 1]) (Domain.validateDependencies [2, 1] tasks)
  assertEqual "lista vazia de dependências é válida"
    (Right []) (Domain.validateDependencies [] tasks)
  assertEqual "ID inexistente devolve erro"
    (Left "ID de dependência inexistente: 99")
    (Domain.validateDependencies [99] tasks)
  assertEqual "devolve erro se uma dependência posterior não existe"
    (Left "ID de dependência inexistente: 99")
    (Domain.validateDependencies [2, 99] tasks)

testProgressSprintEmpty :: Test
testProgressSprintEmpty = TestCase $ do
  let sprint = testSprint { sprintTasks = [] }
  assertEqual "progressSprint vazio" 0.0 (Domain.progressSprint sprint)

testProgressSprintAllDone :: Test
testProgressSprintAllDone = TestCase $ do
  let sprint = testSprint { sprintTasks = [testTaskDone, testTaskDone { taskId = 3 }] }
  assertEqual "progressSprint todas Done" 100.0 (Domain.progressSprint sprint)

testProgressSprintMixed :: Test
testProgressSprintMixed = TestCase $ do
  let sprint = testSprint { sprintTasks = [testTaskTodo, testTaskDone] }
  assertEqual "progressSprint 50%" 50.0 (Domain.progressSprint sprint)

testProgressProject :: Test
testProgressProject = TestCase $ do
  let sprint1 = testSprint { sprintId = 1, sprintTasks = [testTaskDone] }
  let sprint2 = testSprint { sprintId = 2, sprintTasks = [testTaskTodo] }
  let proj = testProject { projectSprints = [sprint1, sprint2] }
  -- progressProject = média dos sprints: (100 + 0) / 2 = 50
  assertEqual "progressProject" 50.0 (Domain.progressProject proj)

testProgressProjectEmpty :: Test
testProgressProjectEmpty = TestCase $ do
  assertEqual "progressProject sem sprints" 0.0 (Domain.progressProject testProject)

testIsBlockedNoDeps :: Test
testIsBlockedNoDeps = TestCase $ do
  let tasks = [testTaskTodo]
  assertBool "isBlocked sem dependências" (not (Domain.isBlocked 1 tasks))

testIsBlockedWithDoneDep :: Test
testIsBlockedWithDoneDep = TestCase $ do
  let taskDep = testTaskTodo { taskId = 1, taskDependsOn = [2] }
  let taskDone = testTaskDone { taskId = 2 }
  let tasks = [taskDep, taskDone]
  assertBool "isBlocked com dependência Done" (not (Domain.isBlocked 1 tasks))

testIsBlockedWithPendingDep :: Test
testIsBlockedWithPendingDep = TestCase $ do
  let taskDep = testTaskTodo { taskId = 1, taskDependsOn = [2] }
  let taskTodo = testTaskTodo { taskId = 2 }
  let tasks = [taskDep, taskTodo]
  assertBool "isBlocked com dependência ToDo" (Domain.isBlocked 1 tasks)

testIsBlockedWithMissingDep :: Test
testIsBlockedWithMissingDep = TestCase $ do
  let taskDep = testTaskTodo { taskDependsOn = [999] }
  assertBool "isBlocked com dependência inexistente" (Domain.isBlocked 1 [taskDep])

testIsBlockedMissingTask :: Test
testIsBlockedMissingTask = TestCase $ do
  assertBool "isBlocked de tarefa inexistente" (not (Domain.isBlocked 999 [testTaskTodo]))

testShowStatusAndPriority :: Test
testShowStatusAndPriority = TestCase $ do
  assertEqual "showStatus ToDo" "ToDo" (Domain.showStatus ToDo)
  assertEqual "showStatus Done" "Done" (Domain.showStatus Done)
  assertEqual "showPriority Critical" "Critical" (Domain.showPriority Critical)
  assertEqual "showPriority Low" "Low" (Domain.showPriority Low)

-- Testes sobre os dados de demonstração (Seed) --------------------------------

testSeedFind :: Test
testSeedFind = TestCase $ do
  assertEqual "seed: findProject 1" (Just projeto) (Domain.findProject 1 estadoInicial)
  assertEqual "seed: findSprint 2" (Just seedSprint2) (Domain.findSprint 2 projeto)
  assertEqual "seed: findTask 4 no Sprint 1" (Just (tarefasSprint1 !! 3)) (Domain.findTask 4 seedSprint1)
  assertEqual "seed: findMember 4" (Just (membros !! 3)) (Domain.findMember 4 projeto)

testSeedProgressSprint :: Test
testSeedProgressSprint = TestCase $ do
  -- Sprint 1: 2 tarefas Done em 5 -> 40%
  assertEqual "seed: progressSprint 1" 40.0 (Domain.progressSprint seedSprint1)
  -- Sprint 2: 0 tarefas Done em 4 -> 0%
  assertEqual "seed: progressSprint 2" 0.0 (Domain.progressSprint seedSprint2)

testSeedProgressProject :: Test
testSeedProgressProject = TestCase $ do
  -- média de 40% e 0% -> 20%
  assertEqual "seed: progressProject" 20.0 (Domain.progressProject projeto)

testSeedBlocked :: Test
testSeedBlocked = TestCase $ do
  -- tarefa 4 depende da 3, que está InProgress -> bloqueada
  assertBool "seed: tarefa 4 bloqueada" (Domain.isBlocked 4 tarefasSprint1)
  -- tarefa 3 não tem dependências -> não bloqueada
  assertBool "seed: tarefa 3 desbloqueada" (not (Domain.isBlocked 3 tarefasSprint1))

testSeedFilters :: Test
testSeedFilters = TestCase $ do
  assertEqual "seed: filtro Done" 2 (length (Domain.filterByStatus Done tarefasSprint1))
  assertEqual "seed: filtro High" 3 (length (Domain.filterByPriority High tarefasSprint1))
  assertEqual "seed: filtro Alice" 3 (length (Domain.filterByAssignee 1 tarefasSprint1))
  assertEqual "seed: filtro inexistente" [] (Domain.filterByAssignee 99 tarefasSprint1)

-- Suite principal -------------------------------------------------------------

tests :: Test
tests = TestList
  [ testFindProject
  , testFindSprint
  , testFindTask
  , testFindMember
  , testListagens
  , testFilterByStatus
  , testFilterByPriority
  , testFilterByAssignee
  , testEffectivePriority
  , testTransitionTask
  , testCountByStatus
  , testTotalPriorityScore
  , testValidateDependencies
  , testProgressSprintEmpty
  , testProgressSprintAllDone
  , testProgressSprintMixed
  , testProgressProject
  , testProgressProjectEmpty
  , testIsBlockedNoDeps
  , testIsBlockedWithDoneDep
  , testIsBlockedWithPendingDep
  , testIsBlockedWithMissingDep
  , testIsBlockedMissingTask
  , testShowStatusAndPriority
  , testSeedFind
  , testSeedProgressSprint
  , testSeedProgressProject
  , testSeedBlocked
  , testSeedFilters
  ]

main :: IO ()
main = do
  testCounts <- runTestTT tests
  if errors testCounts > 0 || failures testCounts > 0
    then exitFailure
    else pure ()
