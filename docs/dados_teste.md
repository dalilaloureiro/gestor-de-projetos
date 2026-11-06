# Dados de Teste do Projeto

Este ficheiro documenta o conjunto de dados de demonstração usado para validar o núcleo funcional do sistema e para apoiar a apresentação da Fase 1.

## Objetivo

Os dados de teste foram desenhados para cobrir:

- projeto com membros e sprints distintos
- tarefas em diferentes estados
- prioridades variadas
- dependências entre tarefas
- casos normais e casos limite

## Estrutura do cenário

### Projeto principal
- Nome: `gestor-de-projetos`
- Membros: Alice, Bob, Carol, David
- 2 sprints: Sprint 1 e Sprint 2

### Sprint 1
Tarefas:

1. `Configurar repositório`  
   - Estado: `Done`
   - Prioridade: `High`
   - Responsável: Alice
   - Sem dependências

2. `Criar modelo de domínio`  
   - Estado: `Done`
   - Prioridade: `High`
   - Responsável: Alice
   - Sem dependências

3. `Implementar Domain.hs`  
   - Estado: `InProgress`
   - Prioridade: `High`
   - Responsável: Alice
   - Sem dependências

4. `Escrever testes`  
   - Estado: `ToDo`
   - Prioridade: `Medium`
   - Responsável: Bob
   - Depende de tarefa 3

5. `Configurar persistência`  
   - Estado: `ToDo`
   - Prioridade: `Medium`
   - Responsável: David
   - Sem dependências

### Sprint 2
Tarefas:

6. `Implementar Parsing.hs`  
   - Estado: `ToDo`
   - Prioridade: `High`
   - Responsável: Alice
   - Sem dependências

7. `Implementar Reports.hs`  
   - Estado: `ToDo`
   - Prioridade: `Medium`
   - Responsável: Carol
   - Depende da tarefa 6

8. `Interface de terminal`  
   - Estado: `ToDo`
   - Prioridade: `Medium`
   - Responsável: David
   - Depende da tarefa 6

9. `Corrigir bug no parsing`  
   - Estado: `ToDo`
   - Prioridade: `Critical`
   - Responsável: Bob
   - Sem dependências

## Casos cobertos

### Casos normais
- tarefa concluída
- tarefa em progresso
- tarefa por fazer
- prioridade alta, média e crítica
- membro com múltiplas tarefas
- dependências entre tarefas

### Casos limite
- sprint vazio (podendo ser criado em testes de progresso)
- todas as tarefas concluídas no sprint
- tarefa bloqueada por dependência não concluída
- tarefa inexistente em consultas por ID

## Como estes dados ajudam os testes

Os dados permitem validar diretamente:

- `findProject` / `findSprint` / `findTask`
- `filterByStatus` / `filterByPriority` / `filterByAssignee`
- `progressSprint`
- `progressProject`
- `isBlocked`
- `validTransitions` / `transitionTask`

A combinação de tarefas concluídas, em progresso e por fazer funciona como base para demonstrar o comportamento real do domínio em Haskell.
