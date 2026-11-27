{-|
Module      : Spec
Description : Suite de testes para o núcleo funcional (Domain e Reports)

Testes das funções puras principais:
- Consultas (findProject, findSprint, findTask, findMember)
- Filtros (por estado, prioridade e responsável)
- Recursão justificada: progressSprint, progressProject, isBlocked
- Formatação (showStatus, showPriority)
- Predicados, filtros HOF e pipelines (Fase 2)
- Relatórios puros de sprint e de membro (Fase 2)
- Situações de erro: Left e Nothing
- Dados de demonstração (módulo Seed) usados como cenário real

Casos normais, limites (listas vazias) e consultas sem resultado.

Framework: HUnit (simples, sem dependências pesadas)
-}
module Main (main) where

import Data.List (isInfixOf)
import Test.HUnit
import Model
import qualified Domain
import qualified Reports
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
testTaskTodo = Task 1 "Tarefa 1" "Desc" ToDo 2 Nothing []

testTaskDone :: Task
testTaskDone = Task 2 "Tarefa 2" "Desc" Done 3 Nothing []

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
  assertEqual "filterByPriority 2" [testTaskTodo] (Domain.filterByPriority 2 tasks)
  assertEqual "filterByPriority 3" [testTaskDone] (Domain.filterByPriority 3 tasks)

testFilterByAssignee :: Test
testFilterByAssignee = TestCase $ do
  let taskAssigned = testTaskTodo { taskAssignee = Just 1 }
  let tasks = [taskAssigned, testTaskDone]
  assertEqual "filterByAssignee 1" [taskAssigned] (Domain.filterByAssignee 1 tasks)
  assertEqual "filterByAssignee 999" [] (Domain.filterByAssignee 999 tasks)

testEffectivePriority :: Test
testEffectivePriority = TestCase $ do
  assertEqual "mais de três dias mantém prioridade"
    2 (Domain.effectivePriority testTaskTodo 4)
  assertEqual "três dias sobe Medium para High"
    3 (Domain.effectivePriority testTaskTodo 3)
  assertEqual "prioridade 1 sobe para 2"
    2 (Domain.effectivePriority (testTaskTodo { taskPriority = 1 }) 2)
  assertEqual "prioridade 3 sobe para 4"
    4 (Domain.effectivePriority (testTaskTodo { taskPriority = 3 }) 1)
  assertEqual "4 não sobe acima de 4"
    4 (Domain.effectivePriority (testTaskTodo { taskPriority = 4 }) 0)
  assertEqual "tarefa atrasada também satisfaz dias restantes <= 3"
    3 (Domain.effectivePriority testTaskTodo (-1))

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
        [ testTaskTodo { taskPriority = 1 }
        , testTaskTodo { taskPriority = 2 }
        , testTaskTodo { taskPriority = 3 }
        , testTaskTodo { taskPriority = 4 }
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
  assertEqual "showPriority 4" "Critical" (Domain.showPriority 4)
  assertEqual "showPriority 1" "Low" (Domain.showPriority 1)

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
  assertEqual "seed: filtro 3 (High)" 3 (length (Domain.filterByPriority 3 tarefasSprint1))
  assertEqual "seed: filtro Alice" 3 (length (Domain.filterByAssignee 1 tarefasSprint1))
  assertEqual "seed: filtro inexistente" [] (Domain.filterByAssignee 99 tarefasSprint1)

-- Fase 2: predicados, filtros HOF e pipelines ---------------------------------

testFilterBy :: Test
testFilterBy = TestCase $ do
  let tasks = [testTaskTodo, testTaskDone]
  assertEqual "filterBy com critério próprio" [testTaskDone]
    (Domain.filterBy ((> 2) . taskPriority) tasks)
  assertEqual "filterBy em lista vazia" []
    (Domain.filterBy (Domain.isStatus Done) [])
  assertEqual "filterBy quando todas satisfazem" [testTaskDone, testTaskDone]
    (Domain.filterBy (Domain.isStatus Done) [testTaskDone, testTaskDone])

testMatchesAll :: Test
testMatchesAll = TestCase $ do
  let mine = testTaskDone { taskId = 3, taskAssignee = Just 1 }
  let tasks = [testTaskTodo, testTaskDone, mine]
  assertEqual "combina estado, prioridade e responsável" [mine]
    (Domain.filterBy
      (Domain.matchesAll
        [Domain.isStatus Done, Domain.isPriority 3, Domain.isAssignee 1])
      tasks)
  assertEqual "sem predicados aceita todas" tasks
    (Domain.filterBy (Domain.matchesAll []) tasks)
  assertEqual "predicados incompatíveis não aceitam nenhuma" []
    (Domain.filterBy
      (Domain.matchesAll [Domain.isStatus Done, Domain.isStatus ToDo])
      tasks)

testPipelines :: Test
testPipelines = TestCase $ do
  let tasks = [testTaskTodo, testTaskDone]
  assertEqual "taskTitles mantém a ordem" ["Tarefa 1", "Tarefa 2"]
    (Domain.taskTitles tasks)
  assertEqual "taskTitles de lista vazia" [] (Domain.taskTitles [])
  assertEqual "taskTitlesByStatus" ["Tarefa 2"]
    (Domain.taskTitlesByStatus Done tasks)
  assertEqual "taskTitlesByStatus sem resultados" []
    (Domain.taskTitlesByStatus Review tasks)

testProjectTasks :: Test
testProjectTasks = TestCase $ do
  let mine1 = testTaskTodo { taskAssignee = Just 1 }
  let mine2 = testTaskDone { taskAssignee = Just 1 }
  let proj = testProject
        { projectSprints =
            [ testSprint { sprintTasks = [mine1] }
            , testSprint { sprintId = 2, sprintTasks = [mine2] }
            ]
        }
  assertEqual "projectTasks junta os sprints por ordem" [mine1, mine2]
    (Domain.projectTasks proj)
  assertEqual "projeto sem sprints não tem tarefas" []
    (Domain.projectTasks testProject)
  assertEqual "projeto com sprint vazio não tem tarefas" []
    (Domain.projectTasks testProject { projectSprints = [testSprint] })
  assertEqual "tasksOfMember percorre todos os sprints" [mine1, mine2]
    (Domain.tasksOfMember 1 proj)
  assertEqual "membro sem tarefas" [] (Domain.tasksOfMember 2 proj)

-- Fase 2: relatórios puros ----------------------------------------------------

testFormatPercentage :: Test
testFormatPercentage = TestCase $ do
  assertEqual "zero" "0.0%" (Reports.formatPercentage 0)
  assertEqual "cem" "100.0%" (Reports.formatPercentage 100)
  assertEqual "arredonda a uma casa" "66.7%" (Reports.formatPercentage (200 / 3))

testFormatTaskLine :: Test
testFormatTaskLine = TestCase $ do
  assertEqual "sem responsável"
    "#1 Tarefa 1 | ToDo | prioridade: Medium | responsável: sem responsável"
    (Reports.formatTaskLine testTaskTodo)
  assertEqual "com responsável"
    "#2 Tarefa 2 | Done | prioridade: High | responsável: membro #1"
    (Reports.formatTaskLine testTaskDone { taskAssignee = Just 1 })

testSprintReportEmpty :: Test
testSprintReportEmpty = TestCase $ do
  assertEqual "relatório de sprint vazio"
    (unlines
      [ "== Sprint 1 (2024-01-01 a 2024-01-14) =="
      , "Progresso: 0.0%"
      , ""
      , "Tarefas por estado:"
      , "ToDo (0)"
      , "  (nenhuma)"
      , "InProgress (0)"
      , "  (nenhuma)"
      , "Review (0)"
      , "  (nenhuma)"
      , "Done (0)"
      , "  (nenhuma)"
      , ""
      , "Tarefas bloqueadas:"
      , "  (nenhuma)"
      ])
    (Reports.sprintReport testSprint)

testSprintReportAllDone :: Test
testSprintReportAllDone = TestCase $ do
  let sprint = testSprint { sprintTasks = [testTaskDone] }
  let report = Reports.sprintReport sprint
  assertBool "progresso a 100%" ("Progresso: 100.0%" `isInfixOf` report)
  assertBool "conta a tarefa concluída" ("Done (1)" `isInfixOf` report)
  assertEqual "nenhuma bloqueada" "  (nenhuma)\n"
    (Reports.sprintBlockedTasks sprint (sprintTasks sprint))

testSprintBlockedTasks :: Test
testSprintBlockedTasks = TestCase $ do
  let blocked = testTaskTodo { taskDependsOn = [2, 99] }
  let pending = testTaskTodo { taskId = 2, taskTitle = "Tarefa 2" }
  let sprint = testSprint { sprintTasks = [blocked, pending] }
  assertEqual "indica as dependências pendentes e inexistentes"
    "  #1 Tarefa 1 (à espera de: #2, #99)\n"
    (Reports.sprintBlockedTasks sprint (sprintTasks sprint))

testMemberReport :: Test
testMemberReport = TestCase $ do
  let active = testTaskTodo { taskStatus = InProgress, taskAssignee = Just 1 }
  let finished = testTaskDone { taskAssignee = Just 1 }
  let proj = testProject
        { projectSprints = [testSprint { sprintTasks = [active, finished] }] }
  assertEqual "relatório com tarefas em curso e concluídas"
    (unlines
      [ "== Alice =="
      , "Carga de trabalho:"
      , "  ToDo: 0"
      , "  InProgress: 1"
      , "  Review: 0"
      , "  Done: 1"
      , "  Total: 2"
      , ""
      , "Tarefas em curso:"
      , "  " ++ Reports.formatTaskLine active
      ])
    (Reports.memberReport 1 proj)

testMemberReportNoTasks :: Test
testMemberReportNoTasks = TestCase $ do
  assertEqual "membro sem tarefas"
    (unlines
      [ "== Bob =="
      , "Carga de trabalho:"
      , "  ToDo: 0"
      , "  InProgress: 0"
      , "  Review: 0"
      , "  Done: 0"
      , "  Total: 0"
      , ""
      , "Tarefas em curso:"
      , "  (nenhuma)"
      ])
    (Reports.memberReport 2 testProject)

-- Fase 2: situações de erro ---------------------------------------------------

testMemberReportUnknown :: Test
testMemberReportUnknown = TestCase $ do
  assertEqual "membro inexistente"
    "Membro #999 não encontrado no projeto.\n"
    (Reports.memberReport 999 testProject)

testTransitionErrors :: Test
testTransitionErrors = TestCase $ do
  assertEqual "tarefa concluída não reabre"
    (Left "Transição de estado inválida: Done -> InProgress")
    (Domain.transitionTask testTaskDone InProgress)
  assertEqual "ToDo não salta para Review"
    (Left "Transição de estado inválida: ToDo -> Review")
    (Domain.transitionTask testTaskTodo Review)
  assertEqual "Review não recua"
    (Left "Transição de estado inválida: Review -> InProgress")
    (Domain.transitionTask testTaskTodo { taskStatus = Review } InProgress)

testDependencyErrors :: Test
testDependencyErrors = TestCase $ do
  assertEqual "sem tarefas, qualquer dependência é inexistente"
    (Left "ID de dependência inexistente: 1")
    (Domain.validateDependencies [1] [])
  assertEqual "com vários erros, reporta o primeiro"
    (Left "ID de dependência inexistente: 98")
    (Domain.validateDependencies [98, 99] [testTaskTodo])

testNothingOnEmpty :: Test
testNothingOnEmpty = TestCase $ do
  assertEqual "findProject em lista vazia" Nothing (Domain.findProject 1 [])
  assertEqual "findSprint em projeto sem sprints" Nothing
    (Domain.findSprint 1 testProject)
  assertEqual "findTask em sprint vazio" Nothing (Domain.findTask 1 testSprint)
  assertEqual "findMember em projeto sem membros" Nothing
    (Domain.findMember 1 testProject { projectMembers = [] })

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
  , testFilterBy
  , testMatchesAll
  , testPipelines
  , testProjectTasks
  , testFormatPercentage
  , testFormatTaskLine
  , testSprintReportEmpty
  , testSprintReportAllDone
  , testSprintBlockedTasks
  , testMemberReport
  , testMemberReportNoTasks
  , testMemberReportUnknown
  , testTransitionErrors
  , testDependencyErrors
  , testNothingOnEmpty
  ]

main :: IO ()
main = do
  testCounts <- runTestTT tests
  if errors testCounts > 0 || failures testCounts > 0
    then exitFailure
    else pure ()
