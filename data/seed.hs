-- Dados de demonstração (seed) para o projeto

module Seed where

import Model

-- Membros da equipa
membros :: [Member]
membros =
  [ Member 1 "Alice"
  , Member 2 "Bob"
  , Member 3 "Carol"
  , Member 4 "David"
  ]

-- Tarefas do Sprint 1
tarefasSprint1 :: [Task]
tarefasSprint1 =
  [ Task 1 "Configurar repositório" "Inicializar repo Git e CI" Done High (Just 1) []
  , Task 2 "Criar modelo de domínio" "Definir ADTs e records em Model.hs" Done High (Just 1) []
  , Task 3 "Implementar Domain.hs" "Funções puras: consultas, filtros, progresso" InProgress High (Just 1) []
  , Task 4 "Escrever testes" "Testes unitários para Domain.hs" ToDo Medium (Just 2) [3]
  , Task 5 "Configurar persistência" "Leitura/escrita de ficheiros em Persistence.hs" ToDo Medium (Just 4) []
  ]

-- Tarefas do Sprint 2
tarefasSprint2 :: [Task]
tarefasSprint2 =
  [ Task 6 "Implementar Parsing.hs" "Parsing de ficheiros e entrada do utilizador" ToDo High (Just 1) []
  , Task 7 "Implementar Reports.hs" "Relatórios de sprint, projeto e membro" ToDo Medium (Just 3) [6]
  , Task 8 "Interface de terminal" "Menu textual em Main.hs" ToDo Medium (Just 4) [6]
  , Task 9 "Corrigir bug no parsing" "Parsing falha com datas inválidas" ToDo Critical (Just 2) []
  ]

-- Sprints
sprints :: [Sprint]
sprints =
  [ Sprint 1 "Sprint 1 - Fundação" "2024-11-01" "2024-11-14" tarefasSprint1
  , Sprint 2 "Sprint 2 - Funcionalidades" "2024-11-15" "2024-11-28" tarefasSprint2
  ]

-- Projeto principal
projeto :: Project
projeto = Project 1 "gestor-de-projetos" "Sistema de gestão de projetos em Haskell" membros sprints

-- Lista inicial de projetos
estadoInicial :: [Project]
estadoInicial = [projeto]