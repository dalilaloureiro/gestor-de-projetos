{-|
Module      : Reports
Description : Geração de relatórios textuais a partir do modelo

Responsável por:
- Relatórios de sprint: tarefas por estado, progresso, bloqueadas
- Relatórios de projeto: progresso global, distribuição por prioridade (Fase 3)
- Relatórios de membro: carga de trabalho, tarefas em curso
- Formatação pura (sem IO) - apenas transforma modelo em String

Os relatórios usam funções de 'Domain' (progressSprint, isBlocked, etc.)
e composição funcional: 'filter' seleciona tarefas, 'map' transforma-as em
linhas e 'unlines'/'concatMap' juntam o resultado.
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

import Data.List (intercalate)
import Domain
import Model
import Text.Printf (printf)

-- Relatórios de Sprint --------------------------------------------------------

-- | Relatório completo de um sprint: cabeçalho, progresso, tarefas por estado
--   e tarefas bloqueadas. As dependências são procuradas nas tarefas do próprio
--   sprint, por isso uma dependência de outro sprint conta como pendente.
sprintReport :: Sprint -> String
sprintReport sprint =
  concat
    [ unlines
        [ "== " ++ sprintName sprint ++ " ("
            ++ sprintStart sprint ++ " a " ++ sprintEnd sprint ++ ") =="
        , "Progresso: " ++ formatPercentage (progressSprint sprint)
        , ""
        , "Tarefas por estado:"
        ]
    , sprintTasksByStatus sprint
    , unlines ["", "Tarefas bloqueadas:"]
    , sprintBlockedTasks sprint (sprintTasks sprint)
    ]

-- | Lista tarefas agrupadas por estado.
--   'concatMap' gera uma secção por cada estado do tipo 'TaskStatus' e junta-as.
sprintTasksByStatus :: Sprint -> String
sprintTasksByStatus sprint = concatMap section [minBound .. maxBound]
  where
    section :: TaskStatus -> String
    section status =
      let tasks = filterByStatus status (sprintTasks sprint)
          title = showStatus status ++ " (" ++ show (length tasks) ++ ")"
      in unlines (title : indentList (map formatTaskLine tasks))

-- | Lista as tarefas bloqueadas do sprint e as dependências que as bloqueiam.
--   O segundo argumento são as tarefas onde as dependências são procuradas.
--   Pipeline: 'filter' escolhe as bloqueadas e 'map' formata cada uma.
sprintBlockedTasks :: Sprint -> [Task] -> String
sprintBlockedTasks sprint allTasks =
  unlines . indentList . map blockedLine . filterBy blocked $ sprintTasks sprint
  where
    blocked :: Task -> Bool
    blocked = (`isBlocked` allTasks) . taskId

    blockedLine :: Task -> String
    blockedLine task =
      showTaskRef (taskId task) ++ " " ++ taskTitle task
        ++ " (à espera de: "
        ++ intercalate ", " (map showTaskRef (pendingDependencies task allTasks))
        ++ ")"

-- Relatórios de Projeto -------------------------------------------------------

-- | Relatório completo de um projeto
projectReport :: Project -> String
projectReport = undefined  -- TODO: Fase 3

-- | Progresso global do projeto (usa Domain.progressProject)
projectProgress :: Project -> String
projectProgress = undefined  -- TODO: Fase 3

-- | Distribuição de tarefas por prioridade
projectPriorityDistribution :: Project -> String
projectPriorityDistribution = undefined  -- TODO: Fase 3

-- Relatórios de Membro --------------------------------------------------------

-- | Relatório de um membro: carga de trabalho e tarefas em curso.
--   Um ID que não existe no projeto produz uma mensagem em vez do relatório
--   ('findMember' devolve 'Maybe' e 'maybe' trata os dois casos).
memberReport :: MemberId -> Project -> String
memberReport mid project = maybe notFound report (findMember mid project)
  where
    notFound :: String
    notFound = unlines ["Membro #" ++ show mid ++ " não encontrado no projeto."]

    report :: Member -> String
    report member =
      concat
        [ unlines ["== " ++ memberName member ++ " ==", "Carga de trabalho:"]
        , memberWorkload mid project
        , unlines ["", "Tarefas em curso:"]
        , memberActiveTasks mid project
        ]

-- | Carga de trabalho (contagem de tarefas por estado e total).
--   Reutiliza 'countByStatus' (um 'foldr') para cada estado, através de 'map'.
memberWorkload :: MemberId -> Project -> String
memberWorkload mid project =
  unlines (indentList (map statusLine [minBound .. maxBound] ++ [totalLine]))
  where
    tasks :: [Task]
    tasks = tasksOfMember mid project

    statusLine :: TaskStatus -> String
    statusLine status =
      showStatus status ++ ": " ++ show (countByStatus status tasks)

    totalLine :: String
    totalLine = "Total: " ++ show (length tasks)

-- | Tarefas ativas (InProgress, Review) de um membro.
memberActiveTasks :: MemberId -> Project -> String
memberActiveTasks mid =
  unlines . indentList . map formatTaskLine . filterBy isActive . tasksOfMember mid
  where
    isActive :: Task -> Bool
    isActive = (`elem` [InProgress, Review]) . taskStatus

-- Utilitários de formatação ---------------------------------------------------

-- | Formata percentagem com uma casa decimal
formatPercentage :: Double -> String
formatPercentage = printf "%.1f%%"

-- | Formata uma linha de tarefa para listagens
formatTaskLine :: Task -> String
formatTaskLine task =
  intercalate " | "
    [ showTaskRef (taskId task) ++ " " ++ taskTitle task
    , showStatus (taskStatus task)
    , "prioridade: " ++ showPriority (taskPriority task)
    , "responsável: " ++ maybe "sem responsável" showMemberRef (taskAssignee task)
    ]
  where
    showMemberRef :: MemberId -> String
    showMemberRef mid = "membro #" ++ show mid

-- | Referência curta a uma tarefa, por exemplo @#4@.
showTaskRef :: TaskId -> String
showTaskRef tid = '#' : show tid

-- | Indenta as linhas de uma lista; uma lista vazia é assinalada explicitamente.
indentList :: [String] -> [String]
indentList [] = ["  (nenhuma)"]
indentList items = map ("  " ++) items
