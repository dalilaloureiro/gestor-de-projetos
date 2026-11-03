{-|
Module      : Main
Description : Ponto de entrada da aplicação - interface de terminal
Copyright   : (c) 2024 Francisco, Dalila, Duarte
License     : MIT
Maintainer  : exemplo@universidade.pt

Módulo principal que:
- Inicializa o estado (carrega de ficheiro ou usa seed)
- Apresenta menu textual
- Processa comandos do utilizador
- Delega lógica pura para 'Domain' e 'Reports'
- Usa 'Persistence' para guardar estado
- Mantém IO isolado do núcleo funcional
-}
module Main where

import Model
import qualified Domain
import qualified Persistence
import qualified Reports

-- | Função principal
main :: IO ()
main = do
  putStrLn "=================================="
  putStrLn "  Gestor de Projetos - Fase 1"
  putStrLn "=================================="
  putStrLn ""
  putStrLn "Estrutura do projeto criada com sucesso!"
  putStrLn ""
  putStrLn "Módulos disponíveis:"
  putStrLn "  - Model       : Tipos de domínio (ADTs, records)"
  putStrLn "  - Domain      : Núcleo funcional puro (regras, recursão)"
  putStrLn "  - Parsing     : Parsing/validação de dados externos"
  putStrLn "  - Persistence : Leitura/escrita de ficheiros"
  putStrLn "  - Reports     : Geração de relatórios"
  putStrLn ""
  putStrLn "Para compilar:   cabal build"
  putStrLn "Para executar:   cabal run gestor-de-projetos"
  putStrLn "Para testar:     cabal test"
  putStrLn ""
  putStrLn "Próximos passos (Elemento B):"
  putStrLn "  - Implementar funções em Domain.hs"
  putStrLn "  - Adicionar testes em test/Spec.hs"
  putStrLn ""
  putStrLn "Próximos passos (Elemento C):"
  putStrLn "  - Criar dados de teste em data/seed.txt"
  putStrLn "  - Configurar suite de testes"