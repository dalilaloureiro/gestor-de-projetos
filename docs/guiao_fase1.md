# Guião de Demonstração — Fase 1

Duração alvo: 5 minutos. Tudo o que se mostra abaixo já está implementado e coberto por testes.

## Antes de começar

```bash
cabal build all
cabal test
```

Mostrar que o build passa sem warnings e que a suite termina em `PASS` (24 testes).

## 1. Modelo de domínio — `src/Model.hs` (1 min)

- `TaskStatus` e `Priority`: sum types com `Eq`, `Show`, `Read`, `Enum`, `Bounded`.
- `Member`, `Task`, `Sprint`, `Project`: records que agregam o domínio.
- Relações: `Project → [Sprint]`, `Sprint → [Task]`, `Task → Maybe MemberId`, `Task → [TaskId]`.
- Justificação das decisões: `docs/modelo.md`.

## 2. Estrutura do projeto — `gestor-de-projetos.cabal` (30 s)

- `src/`: `Model`, `Domain`, `Parsing`, `Persistence`, `Reports`.
- `app/Main.hs`: ponto de entrada mínimo.
- `test/Spec.hs`: suite HUnit; `data/Seed.hs`: dados de demonstração.
- `docs/`: modelo, dados de teste, planos e este guião.

## 3. Funções essenciais puras — `src/Domain.hs` (1 min 30 s)

Mostrar no `ghci` (ou explicar pelo código):

```
cabal repl
> import Model
> import Domain
> import Seed
> findProject 1 estadoInicial
> findTask 4 (sprints !! 0)
> filterByStatus Done tarefasSprint1
> filterByPriority High tarefasSprint1
> filterByAssignee 1 tarefasSprint1
> showStatus InProgress
```

Pontos a referir: assinaturas explícitas, `Maybe` nas consultas, `filter` com predicados simples.

## 4. Recursão justificada — `src/Domain.hs` (1 min 30 s)

Três funções recursivas, cada uma com comentário a justificar a recursão:

| Função | Recursão sobre |
|---|---|
| `progressSprint` (+ `countDoneAndTotal`) | lista de tarefas |
| `progressProject` (+ `sumSprintProgress`) | lista de sprints |
| `isBlocked` (+ `pendingDependencies`) | lista de dependências |

Demonstração sobre o seed:

```
> progressSprint (sprints !! 0)   -- 40.0
> progressProject projeto         -- 20.0
> isBlocked 4 tarefasSprint1      -- True
> isBlocked 3 tarefasSprint1      -- False
```

## 5. Dados de teste — `data/Seed.hs` (30 s)

- 1 projeto, 2 sprints, 9 tarefas, 4 membros.
- O módulo `Seed` é compilado com a suite de testes, por isso os dados nunca ficam desatualizados.
- Cenários cobertos: `docs/dados_teste.md`.

## 6. Testes — `test/Spec.hs` (30 s)

- 24 casos HUnit: consultas existentes e inexistentes, listagens, filtros, progresso (sprint vazio, todas `Done`, misto), bloqueios (sem dependências, dependência `Done`, pendente, inexistente) e formatação.
- Metade dos testes usa os dados do `Seed`, a outra metade fixtures mínimos para casos limite.

## Perguntas previsíveis do professor

- **Porque não há `Either` no `Domain`?** `Maybe` cobre a ausência nas consultas; validação com `Either` (criação de entidades, transições de estado, parsing) é âmbito da Fase 2.
- **Porque recursão e não `fold`?** Requisito da fase: demonstrar recursão estrutural explícita; `map`/`filter`/`fold` entram na Fase 2.
- **Porque `data/Seed.hs` e não um `.txt`?** Na Fase 1 os dados são valores Haskell (sem parsing); a serialização em ficheiro é Fase 3.
- **Os stubs de `Parsing`, `Persistence` e `Reports` não deviam estar vazios?** Estão — são `undefined` com assinaturas, como previsto na tarefa A4, para fixar o contrato dos módulos.
