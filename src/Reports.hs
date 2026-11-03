{-|
Module      : Reports
Description : Geração de relatórios textuais a partir do modelo
Copyright   : (c) 2024 Francisco, Dalila, Duarte
License     : MIT
Maintainer  : exemplo@universidade.pt

Responsável por:
- Relatórios de sprint: tarefas por estado, progresso, bloqueadas
- Relatórios de projeto: progresso global, distribuição por prioridade
- Relatórios de membro: carga de trabalho, tarefas em curso
- Formatação pura (sem IO) - apenas transforma modelo em String

Os relatórios usam funções de 'Domain' (progressSprint, isBlocked, etc.)
e composição funcional para agregar e formatar informação.
-}
module Reports
  ( -- * Relatórios de Sprint
    sprintReport
  , sprintTasksByStatus
  , sprintBlockedTasks
    -- * Relatórios de Projeto
  , projectReport
  , projectProgress
  , projectPriorityDistribution
    -- * Relatórios de Membro
  , memberReport
  , memberWorkload
  , memberActiveTasks
    -- * Utilitários de formatação
  , formatPercentage
  , formatTaskLine
  ) where

import Model
import qualified Domain

-- Relatórios de Sprint --------------------------------------------------------

-- | Relatório completo de um sprint
sprintReport :: Sprint -> String
sprintReport = undefined  -- TODO: compor sprintTasksByStatus, progresso, bloqueadas

-- | Lista tarefas agrupadas por estado
sprintTasksByStatus :: Sprint -> String
sprintTasksByStatus = undefined

-- | Lista tarefas bloqueadas no sprint
sprintBlockedTasks :: Sprint -> [Model.Task] -> String
sprintBlockedTasks = undefined  -- usa Domain.isBlocked

-- Relatórios de Projeto -------------------------------------------------------

-- | Relatório completo de um projeto
projectReport :: Model.Project -> String
projectReport = undefined

-- | Progresso global do projeto (usa Domain.progressProject)
projectProgress :: Model.Project -> String
projectProgress = undefined

-- | Distribuição de tarefas por prioridade
projectPriorityDistribution :: Model.Project -> String
projectPriorityDistribution = undefined

-- Relatórios de Membro --------------------------------------------------------

-- | Relatório de carga de trabalho de um membro
memberReport :: Model.MemberId -> Model.Project -> String
memberReport = undefined

-- | Carga de trabalho (contagem de tarefas por estado)
memberWorkload :: Model.MemberId -> Model.Project -> String
memberWorkload = undefined

-- | Tarefas ativas (InProgress, Review) de um membro
memberActiveTasks :: Model.MemberId -> Model.Project -> String
memberActiveTasks = undefined

-- Utilitários de formatação ---------------------------------------------------

-- | Formata percentagem com uma casa decimal
formatPercentage :: Double -> String
formatPercentage = undefined

-- | Formata uma linha de tarefa para listagens
formatTaskLine :: Model.Task -> String
formatTaskLine = undefined