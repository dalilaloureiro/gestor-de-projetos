{-|
Module      : Main
Description : Ponto de entrada da aplicação - interface de terminal

Módulo principal que:
- Inicializa o estado (carrega de ficheiro ou usa seed)
- Apresenta menu textual
- Processa comandos do utilizador
- Delega lógica pura para 'Domain' e 'Reports'
- Usa 'Persistence' para guardar estado
- Mantém IO isolado do núcleo funcional
-}
module Main where

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