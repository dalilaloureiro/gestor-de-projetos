# Documentação da Fase 2 — Elemento A

Este documento descreve as funções de lógica de domínio acrescentadas na
Fase 2. Estão implementadas no módulo `Domain`, que não realiza operações de
entrada/saída: recebe valores do modelo e devolve resultados calculados.

## Prioridade efetiva

```haskell
effectivePriority :: Task -> Int -> Priority
```

Recebe uma tarefa e o número de dias restantes até ao fim do sprint. Se
faltarem mais de três dias, devolve a prioridade base da tarefa. Se faltarem
três dias ou menos, sobe a prioridade exatamente um nível:

| Prioridade base | Prioridade efetiva |
|---|---|
| `Low` | `Medium` |
| `Medium` | `High` |
| `High` | `Critical` |
| `Critical` | `Critical` |

A função não calcula a data nem altera a tarefa; recebe os dias restantes como
argumento e devolve uma prioridade.

## Transições de estado

```haskell
validTransitions :: [(TaskStatus, TaskStatus)]
canTransition :: TaskStatus -> TaskStatus -> Bool
transitionTask :: Task -> TaskStatus -> Either String Task
```

`validTransitions` contém os pares de estados permitidos. A regra é avançar
apenas para o passo seguinte:

```text
ToDo -> InProgress -> Review -> Done
```

`canTransition` verifica se um par de estados consta dessa lista. Repetir o
estado atual, saltar um estado ou voltar atrás não é permitido.

`transitionTask` aplica a regra. Se a transição for válida, devolve `Right`
com uma cópia da tarefa cujo estado foi atualizado. Se for inválida, devolve
`Left` com uma mensagem explicativa. Os outros campos da tarefa são preservados.

## Validação de dependências

```haskell
validateDependencies :: [TaskId] -> [Task] -> Either String [TaskId]
```

Recebe os IDs de dependências e a lista de tarefas disponíveis. Percorre os
IDs e verifica se cada um corresponde a uma tarefa existente. Devolve `Right`
com os IDs validados, mantendo a ordem, ou `Left` com uma mensagem relativa
ao primeiro ID inexistente.

Esta função valida apenas a existência dos IDs. Não verifica se as tarefas
dependentes estão concluídas; essa regra continua separada na deteção de
bloqueios existente no módulo `Domain`.

## Agregações com `foldr`

### Contagem por estado

```haskell
countByStatus :: TaskStatus -> [Task] -> Int
```

Recebe um estado e uma lista de tarefas e devolve quantas tarefas estão nesse
estado. Usa `foldr` para percorrer a lista e acumular a contagem. Uma lista
vazia ou sem tarefas nesse estado produz `0`.

### Pontuação total das prioridades

```haskell
totalPriorityScore :: [Task] -> Int
```

Soma uma pontuação por cada tarefa, usando a escala definida para esta
implementação:

| Prioridade | Pontos |
|---|---:|
| `Low` | 1 |
| `Medium` | 2 |
| `High` | 3 |
| `Critical` | 4 |

A função usa `foldr` para acumular a soma. Uma lista vazia produz `0`.

## Testes

Os casos de teste em `test/Spec.hs` cobrem as transições permitidas e
inválidas, as dependências existentes e inexistentes, as prioridades e as
agregações, incluindo listas vazias. Executar com:

```text
cabal test
```
