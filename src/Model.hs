{-|
Module      : Model
Description : Modelo de domínio do gestor de projetos
Copyright   : (c) 2024 Francisco, Dalila, Duarte
License     : MIT
Maintainer  : exemplo@universidade.pt

Tipos algébricos e records que modelam o domínio de gestão de projetos:
projetos, sprints, tarefas, membros, etiquetas e estado global da aplicação.

A modelação segue os princípios da Programação Funcional:
- Tipos de soma (sum types) para estados finitos (TaskStatus, Priority)
- Records para entidades com campos nomeados
- Maybe para campos opcionais (ex.: responsável)
- Listas para relações 1:N (tarefas de um sprint, sprints de um projeto)
- Derivação de typeclasses padrão para igualdade, exibição, leitura, enumeração
-}
module Model
  ( -- * Identificadores
    ProjectId
  , SprintId
  , TaskId
  , MemberId
    -- * Tipos de soma (estados e prioridades)
  , TaskStatus (..)
  , Priority (..)
    -- * Entidades
  , Member (..)
  , Label (..)
  , Task (..)
  , Sprint (..)
  , Project (..)
    -- * Estado global
  , AppState (..)
  ) where

-- | Identificador único de projeto
type ProjectId = Int

-- | Identificador único de sprint
type SprintId = Int

-- | Identificador único de tarefa
type TaskId = Int

-- | Identificador único de membro
type MemberId = Int

-- | Estado de uma tarefa.
--   Transições válidas: ToDo -> InProgress -> Review -> Done
data TaskStatus
  = ToDo
  | InProgress
  | Review
  | Done
  deriving (Eq, Show, Read, Enum, Bounded, Ord)

-- | Prioridade de uma tarefa.
--   Ord derivado permite comparação direta: Low < Medium < High < Critical
data Priority
  = Low
  | Medium
  | High
  | Critical
  deriving (Eq, Show, Read, Enum, Bounded, Ord)

-- | Membro da equipa
data Member = Member
  { memberId   :: MemberId
  , memberName :: String
  , memberRole :: String
  } deriving (Eq, Show, Read)

-- | Etiqueta associada a tarefas
data Label = Label
  { labelName :: String
  } deriving (Eq, Show, Read)

-- | Tarefa individual
data Task = Task
  { taskId          :: TaskId
  , taskTitle       :: String
  , taskDescription :: String
  , taskStatus      :: TaskStatus
  , taskPriority    :: Priority
  , taskAssignee    :: Maybe MemberId
  , taskLabels      :: [Label]
  , taskDependsOn   :: [TaskId]
  } deriving (Eq, Show, Read)

-- | Sprint contendo um conjunto de tarefas
data Sprint = Sprint
  { sprintId     :: SprintId
  , sprintName   :: String
  , sprintStart  :: String   -- Data em formato ISO 8601 (YYYY-MM-DD)
  , sprintEnd    :: String
  , sprintTasks  :: [Task]
  } deriving (Eq, Show, Read)

-- | Projeto contendo sprints e membros
data Project = Project
  { projectId     :: ProjectId
  , projectName   :: String
  , projectDesc   :: String
  , projectMembers :: [Member]
  , projectSprints :: [Sprint]
  } deriving (Eq, Show, Read)

-- | Estado global da aplicação: lista de projetos
data AppState = AppState
  { projects :: [Project]
  } deriving (Eq, Show, Read)

-- Nota: os getters são gerados automaticamente pela sintaxe de record:
--   taskStatus, taskPriority, taskAssignee, taskLabels, taskDependsOn :: Task -> ...
--   sprintTasks :: Sprint -> [Task]
--   projectSprints, projectMembers :: Project -> ...
--   projects :: AppState -> [Project]
-- Estão disponíveis para uso direto via a exportação dos construtores de record (..)