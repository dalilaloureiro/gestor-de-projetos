{-|
Module      : Persistence
Description : Persistência do estado da aplicação em ficheiros

Responsável por:
- Leitura do estado a partir de ficheiro no arranque
- Escrita do estado em ficheiro após alterações
- Gestão de ficheiros de dados de demonstração (seed)
- Uso de 'Either' para tratamento explícito de erros de IO

A camada de persistência usa 'Parsing' para converter entre
texto e modelo, mantendo o IO isolado do núcleo funcional.
-}
module Persistence
  ( -- * Ficheiro de estado principal
    defaultStateFile
  , loadState
  , saveState
    -- * Dados de demonstração (seed)
  , seedFile
  , loadSeed
  , saveSeed
    -- * Utilitários
  , ensureDataDir
  ) where

import Model

-- | Caminho padrão do ficheiro de estado
defaultStateFile :: FilePath
defaultStateFile = "data/state.txt"

-- | Caminho do ficheiro de dados de demonstração
seedFile :: FilePath
seedFile = "data/seed.txt"

-- | Carrega o estado da aplicação a partir do ficheiro padrão
--   Retorna 'AppState' vazio se o ficheiro não existir ou houver erro
loadState :: IO (Either String AppState)
loadState = undefined  -- TODO: implementar leitura de ficheiro + Parsing.parseAppState

-- | Guarda o estado da aplicação no ficheiro padrão
saveState :: AppState -> IO (Either String ())
saveState = undefined  -- TODO: implementar Parsing.showAppState + escrita de ficheiro

-- | Carrega dados de demonstração (seed)
loadSeed :: IO (Either String AppState)
loadSeed = undefined  -- TODO: implementar

-- | Guarda dados de demonstração (seed)
saveSeed :: AppState -> IO (Either String ())
saveSeed = undefined  -- TODO: implementar

-- | Garante que o diretório de dados existe
ensureDataDir :: IO ()
ensureDataDir = undefined  -- TODO: createDirectoryIfMissing