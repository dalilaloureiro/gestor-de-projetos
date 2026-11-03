{-|
Module      : Parsing
Description : Parsing e validação de dados externos (ficheiros, entrada do utilizador)
Copyright   : (c) 2024 Francisco, Dalila, Duarte
License     : MIT
Maintainer  : exemplo@universidade.pt

Responsável por:
- Parsing de ficheiros de persistência (formato próprio simples)
- Parsing e validação de entrada do utilizador (menu textual)
- Conversão entre representações externas e tipos do modelo
- Uso de 'Either' para reportar erros de parsing/validação de forma explícita

A separação entre 'Parsing' (dados externos -> modelo) e 'Domain'
(modelo -> modelo) mantém o núcleo funcional puro.
-}
module Parsing
  ( -- * Parsing de ficheiros de estado
    parseAppState
  , parseProject
  , parseSprint
  , parseTask
  , parseMember
  , parseLabel
    -- * Parsing de entrada do utilizador
  , parseProjectId
  , parseSprintId
  , parseTaskId
  , parseMemberId
  , parsePriority
  , parseTaskStatus
  , parseDate
    -- * Serialização (modelo -> texto)
  , showAppState
  , showProject
  , showSprint
  , showTask
  , showMember
  , showLabel
  ) where

import Model

-- Parsing de ficheiros de estado ----------------------------------------------

-- | Parsing do estado completo da aplicação a partir de texto
parseAppState :: String -> Either String AppState
parseAppState = undefined  -- TODO: implementar parsing do formato de ficheiro

-- | Parsing de um projeto
parseProject :: String -> Either String Project
parseProject = undefined

-- | Parsing de um sprint
parseSprint :: String -> Either String Sprint
parseSprint = undefined

-- | Parsing de uma tarefa
parseTask :: String -> Either String Task
parseTask = undefined

-- | Parsing de um membro
parseMember :: String -> Either String Member
parseMember = undefined

-- | Parsing de uma etiqueta
parseLabel :: String -> Either String Label
parseLabel = undefined

-- Parsing de entrada do utilizador --------------------------------------------

-- | Parsing de ProjectId a partir de String (valida > 0)
parseProjectId :: String -> Either String ProjectId
parseProjectId = undefined

-- | Parsing de SprintId a partir de String (valida > 0)
parseSprintId :: String -> Either String SprintId
parseSprintId = undefined

-- | Parsing de TaskId a partir de String (valida > 0)
parseTaskId :: String -> Either String TaskId
parseTaskId = undefined

-- | Parsing de MemberId a partir de String (valida > 0)
parseMemberId :: String -> Either String MemberId
parseMemberId = undefined

-- | Parsing de Priority a partir de String (case-insensitive)
parsePriority :: String -> Either String Priority
parsePriority = undefined

-- | Parsing de TaskStatus a partir de String (case-insensitive)
parseTaskStatus :: String -> Either String TaskStatus
parseTaskStatus = undefined

-- | Parsing de data no formato YYYY-MM-DD
parseDate :: String -> Either String String
parseDate = undefined

-- Serialização (modelo -> texto) ----------------------------------------------

-- | Serializa o estado completo para texto (formato próprio legível)
showAppState :: AppState -> String
showAppState = undefined

-- | Serializa um projeto
showProject :: Project -> String
showProject = undefined

-- | Serializa um sprint
showSprint :: Sprint -> String
showSprint = undefined

-- | Serializa uma tarefa
showTask :: Task -> String
showTask = undefined

-- | Serializa um membro
showMember :: Member -> String
showMember = undefined

-- | Serializa uma etiqueta
showLabel :: Label -> String
showLabel = undefined