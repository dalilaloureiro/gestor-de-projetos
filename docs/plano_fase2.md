# Atribuição de Tarefas — Fase 2 (Lógica Funcional e Transformação de Dados)

## 1. Visão Geral da Fase 2

Objetivo aprofundar o domínio inicial através de boas práticas e mecanismos típicos de Haskell:

```
HOF -> pipelines (map/filter/fold) -> composição -> tratamento de erro -> separação IO
```

Entregáveis da Fase 2:

- [ ] Maioria da lógica de domínio implementada (transições, prioridade efetiva, deteção de bloqueios)
- [ ] Utilização adequada de funções de ordem superior (HOF)
- [ ] Uso de pipelines: `map`, `filter`, `folds` e composição quando apropriado
- [ ] Tratamento explícito de erros com `Maybe` e/ou `Either`
- [ ] Conjunto de dados de teste que permita ver casos normais, casos limites e situações de erro
- [ ] Separção crescente entre lógica funcional e IO
- [ ] README e documentação atualizados

---

## 2. Princípios de Divisão de Trabalho (continuidade da Fase 1)

Mesmas regras de colaboração da Fase 1 se aplicam:

1. **Elemento A é o "dono da lógica funcional pura"** — garante que as funções principais respectivas estejam coerentes com o modelo definido na Fase 1.
2. **Contrato de tipos mantido**: B e C continuam a trabalhar contra o contrato de `Model.hs` e `Domain.hs` definido por A.
3. **Cada elemento tem um módulo principal claro** (ver secção 3).
4. **Integração contínua manual**: commits frequentes, branches curtos, merge para `main` só com build a passar.
5. **Revisão cruzada obrigatória**: cada PR é revisto por pelo menos outro elemento.
6. **Reunião curta semanal** (15–30 min) para sincronizar e desbloquear.

---

## 3. Atribuição por Elemento

### Elemento A (Francisco) — Lógica de Domínio Avançada e Integração

**Responsabilidade central:** implementar a maioria da lógica de domínio restante, garantir transições de estado robustas, prioridade efetiva e separação crescente entre lógica funcional e IO.

| # | Tarefa | Entregável | Depende de |
|---|---|---|---|
| A1 | Implementar cálculo de **prioridade efetiva** (prioridade base + fator de proximidade de prazo) em função pura | `src/Domain.hs` | A2 |
| A2 | Implementar validação e transição de estado **com `Either` detalhado** (mensagens de erro explicativas) | `src/Domain.hs` (funções `transitionTask`, `canTransition`, novas) | A1 |
| A3 | Criar funções de **agregação com `fold`** sobre listas de tarefas/sprints/projetos (ex.: `calculateEffort`, `totalPriorityScore`) | `src/Domain.hs` | A1 |
| A4 | Mover/garantir que toda a lógica IO (leitura/escrita de ficheiros, parsing) fique isolada nos módulos `Parsing` e `Persistence`; funções de `Domain` devem permanecer puras | `src/Domain.hs` limpo (sem `import` de IO) | A3 |
| A5 | Atualizar assinaturas explícitas em todas as funções novas/ modificadas | `src/Domain.hs` | A1–A4 |
| A6 | Documentar as novas funções adicionadas (assinatura + comentário curto) | `docs/documentacao_fase2.md` | A1–A5 |

**Critérios de conclusão:**
- `cabal build` passa sem erros.
- Todas as funções de transição e validação retornam `Either String` com mensagens significativas.
- Funções de agregação usam `foldl'` ou `foldr` de forma natural.
- `Domain.hs` não contém importações de módulos de IO (a não ser maybe/Either para tratamento de erro).
- Documentação em `docs/documentacao_fase2.md` cobre todas as novas funções.

**Riscos:**
- Vazar `IO` para `Domain.hs` → fazer revisão de código cruzada e garantir que apenas `Parsing`/`Persistence` lidam com IO.
- Modelo de prioridade muito complexo → começar com fator simples (ex.: dias até ao fim multiplicado por nível numérico da prioridade).

---

### Elemento B (Dalila) — Funções de Ordem Superior, Pipelines e Testes

**Responsabilidade central:** introduzir e aplicar HOF, pipelines `map`/`filter`/`fold` e compostura, além de expandir a suite de testes com casos normais, limites e erros.

| # | Tarefa | Entregável | Depende de |
|---|---|---|---|
| B1 | Reescrever/upgrade das funções de **filtro** usando `filter` e composição de predicados em vez de `λ` explícito onde apropriado | `src/Domain.hs` (funções `filterByStatus`, `filterByPriority`, `filterByAssignee`) | A1 |
| B2 | Implementar funções de **agregação combinatória** com `map` e `fold` (ex.: `totalPriorityScore`, `averagePriority`, `countByStatus) | `src/Domain.hs` | A3 |
| B3 | Implementar **função de formatação de relatório** usando pipeline: `map` para transformar tarefas → strings, `filter` para selecionar, `fold` para concatenar | `src/Reports.hs` (novo ou upgrade) | A2, A3 |
| B4 | Expandir a suite de testes (`test/Spec.hs`) com novos testes que cubram: casos normais, limites (listas vazias) e situações de erro (IDs inexistentes, transições inválidas) usando HUnit | `test/Spec.hs` | B1–B3 |
| B5 | Adicionar testes de **propriedades** (QuickCheck, se houver tempo) ou pelo menos 5 novos casos de teste HUnit | `test/Spec.hs` | B4 |
| B6 | Garantir que todas as funções implementadas tenham assinatura explícita e comentário a justificar o uso de HOF/fold quando apropriado | `src/Domain.hs`, `src/Reports.hs` | B1–B5 |

**Critérios de conclusão:**
- Pelo menos 3 funções novas ou reestruturadas usam `map`, `filter` ou `fold` de forma natural.
- Pipelines de composição são usados: ex.: `filter status . filter priority` ou `map showStatus . filter (byAssignee mid)`.
- Suite de testes `cabal test` passa com cobertura aumentada.
- Pelo menos 5 novos testes HUnit adicionados (casos normais + limites + erros).

**Riscos:**
- Forçar `fold` onde `map/filter` seriam mais claros → revisar com o elemento A para garantir que a recursão/fold está justificada.
- Sobrecarga de pipelines encadeados → manter pipelines curtos e bem nomeados.

---

### Elemento C (Duarte) — Dados de Teste Avançados, Either/Maybe e Documentação

**Responsabilidade central:** expandir o conjunto de dados de teste para cobrir casos normais, limites e situações de erro; garantir tratamento explícito com `Either`/`Maybe`; atualizar documentação.

| # | Tarefa | Entregável | Depende de |
|---|---|---|---|
| C1 | Ampliar `data/seed.hs` com **cenários de erro**: tarefas com dependências que referenciam IDs inexistentes, transições inválidas, projetos sem sprints, filtros que retornam listas vazias | `data/seed.hs` | A1, A2 |
| C2 | Adicionar **dados de teste para `Either`/`Maybe`**: exemplos que demonstram erros de parsing, validação de transição inválida, IDs de projeto/sprint/tarefa inexistentes | `data/seed.hs` | C1 |
| C3 | Documentar os novos cenários de teste (o que cada conjunto de dados cobre) | `docs/dados_teste_fase2.md` | C1–C2 |
| C4 | Expandir a suite de testes (`test/Spec.hs`) com testes que explicitamente verificam resultados `Just`/`Nothing` e `Right`/`Left` para as novas funcionalidades | `test/Spec.hs` | B4, C1–C3 |
| C5 | Atualizar `docs/guiao_fase1.md` com notas sobre as novas funcionalidades da Fase 2 (casos de erro, HOF, pipelines) | `docs/guiao_fase1.md` | A6, B6, C6 |
| C6 | Revisar `README.md` com nova secção "Fase 2 — Lógica Funcional e Transformação de Dados" que descreva as funcionalidades adicionadas e como testá-las | `README.md` | A6, B6, C6 |

**Critérios de conclusão:**
- `data/seed.hs` contém pelo menos 3 cenários de erro explícitos (ex.: dependência inexistente, transição inválida, prioridade fora de intervalo).
- Suite de testes cobre casos `Just/Nothing` e `Right/Left` para as novas funcionalidades.
- Documentos `docs/dados_teste_fase2.md` e `docs/guiao_fase1.md` atualizados.
- `README.md` reflete as alterações da Fase 2.

**Riscos:**
- Dados de teste muito grandes → manter o conjunto minimalista mas diversificado (normal + 2+ limites + 2+ erros).
- Dependência de A/B → C pode escrever testes "especificação" (falham primeiro) e depois alinhar com a implementação.

---

## 4. Regras de Colaboração e Git (continuidade)

- **Branches:** `feat/a1-prioridade`, `feat/b1-filters-hof`, `feat/c2-dados-erro` (ou por tarefa: `feat/a1-prioridade`, etc.)
- **Commits pequenos e frequentes**, mensagens claras (`feat: adiciona cálculo de prioridade efetiva`, `test: cobre Left para transição inválida`).
- **Pull Requests** para `main` com pelo menos 1 revisão de outro elemento.

---

## 5. Critérios de Aceitação da Fase 2 (checklist coletivo)

Antes da apresentação, o grupo deve conseguir marcar todos:

- [ ] `cabal build` passa sem erros nem warnings relevantes.
- [ ] `cabal test` passa.
- [ ] Lógica de domínio: transições de estado com `Either`, prioridade efetiva, deteção de bloqueios.
- [ ] Pelo menos 3 funções novas ou reestruturadas usam `map`, `filter` ou `fold` de forma natural.
- [ ] Pipelines de composição estão presentes (ex.: `filter . filter`, `map . filter`).
- [ ] Todas as funções de transição retornam `Either String` com mensagens significativas.
- [ ] `Domain.hs` não contém importações de IO (lógica pura isolada).
- [ ] `data/seed.hs` cobre casos normais, limites (vazios) e situações de erro (IDs inexistentes, transições inválidas).
- [ ] Existem pelo menos 7 funções recursivas justificadas por comentário (mantendo herdado da Fase 1 + novas se necessário).
- [ ] Pattern matching usado nas funções de domínio.
- [ ] `docs/documentacao_fase2.md` existe e cobre todas as novas funções.
- [ ] `README.md` atualizado com nova secção de Fase 2.
- [ ] Guião de demonstração permite apresentar as novas funcionalidades da Fase 2 em ≤5 minutos.

---

## 6. Definição de "Done" por Tarefa

Uma tarefa só está concluída quando:

1. O código compila e os testes passam.
2. Tem assinatura explícita (funções) e comentários onde necessário.
3. Foi revista por pelo menos outro elemento (PR aprovado).
4. Está integrada em `main`.
5. Se aplicável, tem teste associado.
6. Se aplicável, está refletida na documentação (`README`, `docs/`).

---

## 7. Novas Funcionalidades Esperadas ao Final da Fase 2

Ao terminar a Fase 2, o projeto deverá ter:

1. **Lógica de domínio completa** sobre o modelo inicial:
   - Transições de estado validadas com `Either` e mensagens de erro.
   - Cálculo de prioridade efetiva (prioridade base + fator de prazo).
   - Deteção de bloqueios por dependências (já existia, agora com mais casos de erro).

2. **Funções de ordem superior (HOF) em uso**:
   - `filter` combinável para filtrar tarefas por estado, prioridade, responsável.
   - `map` para transformar dados (ex.: tarefas → strings de relatório).
   - `fold` para agregação (ex.: soma de prioridades, contagem de status).
   - Composição de funções (`.` ) para pipelines curtos e legíveis.

3. **Pipelines de dados**:
   - Exemplo: `filterByStatus Done . filterByPriority High` para tarefas altas concluídas.
   - `map showStatus . filter (byAssignee mid)` para relatório de membro.

4. **Tratamento explícito de erros**:
   - Criação de entidades (`mkProject`, `mkTask`, etc.) retorna `Either String`.
   - Transições de estado retornam `Either String` com mensagem explicativa.
   - Parsing (`Parsing.hs`) usa `Either` para erros de formato.
   - `Maybe` usado para pesquisas que podem falhar (`findProject`, `findTask`, etc.).

5. **Separção crescente entre lógica funcional e IO**:
   - `Domain.hs` permanece puro (nenhum `import` de `IO`, `System.IO`, etc.).
   - `Parsing.hs` e `Persistence.hs` lidam com IO e conversion entre texto e modelo, usando `Either` para erros.
   - `Main.hs` (app) apenas orquestra IO e chama funções puras de `Domain`.

6. **Dados de teste ricos**:
   - `data/seed.hs` com 1 projeto, 2 sprints, ~10 tarefas com estados/prioridades/dependências variados.
   - Cenários de erro explícitos: dependências que referenciam IDs inexistentes, transições inválidas, projetos sem sprints.
   - Casos limite: listas vazias de projetos/sprints/tarefas, todas as tarefas `Done` ou `ToDo`.

7. **Documentação atualizada**:
   - `docs/documentacao_fase2.md` com descrição de todas as funções novas/alteradas.
   - `README.md` com nova secção "Fase 2 — Lógica Funcional e Transformação de Dados".
   - `docs/dados_teste_fase2.md` com descrição dos novos cenários de teste.
   - `docs/guiao_fase1.md` atualizado com notas sobre Fase 2.