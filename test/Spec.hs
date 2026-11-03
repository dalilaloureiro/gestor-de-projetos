{-|
Module      : Spec
Description : Suite de testes para o núcleo funcional (Domain)
Copyright   : (c) 2024 Francisco, Dalila, Duarte
License     : MIT
Maintainer  : exemplo@universidade.pt

Testes das funções puras principais:
- Consultas (findProject, findSprint, findTask)
- Filtros (por estado, prioridade, responsável, etiqueta)
- Recursão justificada: progressSprint, progressProject, isBlocked
- Transições de estado
- Casos normais, limites (listas vazias) e erros

Framework: HUnit (simples, sem dependências pesadas)
-}
module Main where

import Test.HUnit
import Model
import qualified Domain

-- Dados de teste mínimos ------------------------------------------------------

testMember1 :: Member
testMember1 = Member 1 "Alice" "Developer"

testMember2 :: Member
testMember2 = Member 2 "Bob" "QA"

testProject :: Project
testProject = Project 1 "Projeto Teste" "Descrição" [testMember1, testMember2] []

testSprint :: Sprint
testSprint = Sprint 1 "Sprint 1" "2024-01-01" "2024-01-14" []

testTaskTodo :: Task
testTaskTodo = Task 1 "Tarefa 1" "Desc" ToDo Medium Nothing [] []

testTaskDone :: Task
testTaskDone = Task 2 "Tarefa 2" "Desc" Done High Nothing [] []

-- Testes ---------------------------------------------------------------------

testFindProject :: Test
testFindProject = TestCase $ do
  let projects = [testProject]
  assertEqual "findProject existente" (Just testProject) (Domain.findProject 1 projects)
  assertEqual "findProject inexistente" Nothing (Domain.findProject 999 projects)

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

testCanTransition :: Test
testCanTransition = TestCase $ do
  assertBool "ToDo -> InProgress" (Domain.canTransition ToDo InProgress)
  assertBool "InProgress -> Review" (Domain.canTransition InProgress Review)
  assertBool "Review -> Done" (Domain.canTransition Review Done)
  assertBool "InProgress -> ToDo (back)" (Domain.canTransition InProgress ToDo)
  assertBool "Review -> InProgress (back)" (Domain.canTransition Review InProgress)
  assertBool "Done -> (nada)" (not (Domain.canTransition Done ToDo))
  assertBool "ToDo -> Review (inválido)" (not (Domain.canTransition ToDo Review))

testTransitionTask :: Test
testTransitionTask = TestCase $ do
  let result = Domain.transitionTask testTaskTodo InProgress
  assertBool "transitionTask válida" (case result of Right _ -> True; Left _ -> False)
  let result2 = Domain.transitionTask testTaskTodo Done
  assertBool "transitionTask inválida" (case result2 of Left _ -> True; Right _ -> False)

-- Suite principal -------------------------------------------------------------

tests :: Test
tests = TestList
  [ testFindProject
  , testFindSprint
  , testFindTask
  , testFilterByStatus
  , testFilterByPriority
  , testFilterByAssignee
  , testProgressSprintEmpty
  , testProgressSprintAllDone
  , testProgressSprintMixed
  , testProgressProject
  , testIsBlockedNoDeps
  , testIsBlockedWithDoneDep
  , testIsBlockedWithPendingDep
  , testCanTransition
  , testTransitionTask
  ]

main :: IO ()
main = do
  _ <- runTestTT tests
  return ()