# Atribuição de Tarefas — Fase 2 (Lógica Funcional e Transformação de Dados)

## 1. Visão Geral da Fase 2

O framework define a Fase 2 como a passagem de um núcleo funcional básico para uma **solução claramente funcional**:

```
HOF -> map/filter -> fold -> composição -> Maybe/Either -> lógica da aplicação
```

As expectativas do framework (secção 5.2 do PDF) e onde são cumpridas:

| Expectativa do framework | Onde se concretiza |
|---|---|
| **Funcionalidades** — maioria da lógica de domínio implementada | A1–A4, B1–B3 |
| **HOF** — funções que recebem ou devolvem funções | B1, B2, B3 |
| **Pipelines** — `map`, `filter`, `fold` e composição | A3, B2, B3 |
| **Erros** — tratamento explícito com `Maybe` e/ou `Either` | A2, A4, C3 |
| **Testes** — casos normais, casos limite e situações de erro | B4, B5, C3 |
| **Arquitetura** — separação crescente entre lógica funcional e IO | A5 |
| **Documentação** — README e documentação atualizados | A6, C2, C4, C5 |

Entregáveis da Fase 2 (checklist do framework):

- [ ] Maioria da lógica de domínio implementada
- [ ] Utilização adequada de funções de ordem superior (HOF)
- [ ] Uso de `map`, `filter`, `fold` e composição quando apropriado
- [ ] Tratamento explícito de erros com `Maybe` e/ou `Either`
- [ ] Testes com casos normais, casos limite e situações de erro
- [ ] Separação crescente entre lógica funcional e IO
- [ ] `README.md` e documentação atualizados

### Fora do âmbito da Fase 2

O framework coloca estas matérias na **Fase 3** (secção 5.3: `entrada/ficheiros -> parsing/validação -> núcleo funcional -> saída/relatórios`). Não entram na Fase 2:

- Implementação de `Parsing.hs` (parsing de ficheiros e de entrada do utilizador)
- Implementação de `Persistence.hs` (leitura/escrita de ficheiros)
- Menu textual e qualquer IO em `app/Main.hs`
- Relatórios impressos no terminal (a formatação pura em `Reports.hs` **é** Fase 2; o IO à volta dela não)
- Conversão de datas `String` → `Day` (dependência `time`) e `newtype` para IDs

Princípio orientador do framework (secção 13): *"O objetivo não é maximizar a quantidade de código"*. Cada tarefa abaixo existe para evidenciar um conceito pedido, não para aumentar a funcionalidade.

---

## 2. Princípios de Divisão de Trabalho (continuidade da Fase 1)

1. **Elemento A é o "dono da lógica funcional pura"** — garante que as funções principais estejam coerentes com o modelo definido na Fase 1.
2. **Contrato de tipos mantido**: B e C trabalham contra o contrato de `Model.hs` e `Domain.hs` definido por A. Alterações de assinatura exigem aviso prévio.
3. **Sem trabalho duplicado**: cada função tem um único dono. Agregações com `fold` são do A (A3); B consome-as nos pipelines e relatórios.
4. **Integração contínua manual**: commits frequentes, branches curtos, merge para `main` só com build a passar.
5. **Revisão cruzada obrigatória**: cada PR é revisto por pelo menos outro elemento.
6. **Reunião curta semanal** (15–30 min) para sincronizar e desbloquear.

---

## 3. Atribuição por Elemento

### Elemento A (Francisco) — Lógica de Domínio Pura, `fold` e `Either`

**Responsabilidade central:** completar a lógica de domínio que falta, com `fold` para agregações e `Either` para erros, mantendo `Domain.hs` puro.

| # | Tarefa | Entregável | Depende de |
|---|---|---|---|
| A1 | **Prioridade efetiva** em função pura: `effectivePriority :: Task -> Int -> Priority`, onde `Int` = dias restantes até ao fim do sprint (ex.: ≤3 dias sobe um nível, com saturação em `Critical`). O cálculo dos dias a partir de `sprintEnd` é Fase 3, por isso entra como argumento — mantém a função pura e testável | `src/Domain.hs` | — |
| A2 | **Transições de estado com `Either`**: `validTransitions`, `canTransition`, `transitionTask :: Task -> TaskStatus -> Either String Task`, com mensagens de erro explicativas | `src/Domain.hs` | — |
| A3 | **Agregações com `fold`**: `countByStatus`, `totalPriorityScore`, `calculateEffort` (usar `foldr`/`foldl'` de forma natural, com comentário a justificar) | `src/Domain.hs` | — |
| A4 | **Validação de dependências com `Either`**: `validateDependencies :: [TaskId] -> [Task] -> Either String [TaskId]` para IDs inexistentes. **Não alterar** `isBlocked :: TaskId -> [Task] -> Bool` (contrato da Fase 1, já testado) | `src/Domain.hs` | — |
| A5 | Garantir que `Domain.hs` **não importa módulos de IO** (`System.IO`, `System.Directory`, …) e que todas as funções novas têm assinatura explícita | `src/Domain.hs` | A1–A4 |
| A6 | Documentar as funções novas/alteradas (assinatura + justificação) | `docs/documentacao_fase2.md` | A1–A5 |

**Critérios de conclusão:**
- `cabal build` passa sem erros nem warnings.
- `transitionTask` e `validateDependencies` devolvem `Either String` com mensagens significativas.
- As agregações usam `fold` de forma natural (não `sum`/`length` disfarçados).
- `Domain.hs` sem imports de IO.
- `docs/documentacao_fase2.md` cobre todas as funções novas.

**Riscos:**
- Prioridade efetiva a depender de datas → mantê-la pura, recebendo os dias como argumento; não introduzir `time` na Fase 2.
- Alterar `isBlocked` e quebrar os 24 testes da Fase 1 → criar `validateDependencies` ao lado, não em vez.

---

### Elemento B (Dalila) — HOF, Pipelines e Testes

**Responsabilidade central:** aplicar HOF, `map`/`filter`/composição e expandir a suite de testes com casos normais, limite e erro.

| # | Tarefa | Entregável | Depende de |
|---|---|---|---|
| B1 | **Filtros como HOF**: `filterBy :: (Task -> Bool) -> [Task] -> [Task]` e reescrita de `filterByStatus`/`filterByPriority`/`filterByAssignee` como composições de predicados (`filter (isStatus Done)`, sem `λ` explícito) | `src/Domain.hs` | A5 |
| B2 | **Pipelines com `map` e composição**: funções de transformação (`taskTitles`, `tasksOfMember`) e pelo menos um pipeline no estilo `map f . filter p` | `src/Domain.hs` | B1 |
| B3 | **Relatórios puros em `Reports.hs`**: `formatPercentage`, `formatTaskLine`, `sprintReport`, `memberReport` construídos com `map` (tarefas → linhas), `filter` (seleção) e `fold`/`concat` (junção). Sem IO | `src/Reports.hs` | A3, B2 |
| B4 | **Testes dos casos normais e limite** das funções novas (sprints/projetos vazios, todas `Done`, membro sem tarefas) | `test/Spec.hs` | A1–A3, B1–B3 |
| B5 | **Testes das situações de erro**: `Left` em transições inválidas e em dependências inexistentes; `Nothing` em consultas falhadas. Mínimo 5 casos novos HUnit | `test/Spec.hs` | B4, A2, A4 |
| B6 | Assinaturas explícitas em tudo o que for novo e comentário a justificar a HOF/`fold` usada | `src/Domain.hs`, `src/Reports.hs` | B1–B5 |

**Critérios de conclusão:**
- Pelo menos 3 funções novas ou reestruturadas usam `map`, `filter` ou `fold` de forma natural.
- Existe pelo menos um pipeline por composição (`.`).
- `cabal test` passa, com cobertura de `Just`/`Nothing` e `Right`/`Left`.
- Pelo menos 5 testes HUnit novos.

**Riscos:**
- Forçar `fold` onde `map`/`filter` são mais claros → validar com A antes do PR.
- Pipelines longos e ilegíveis → funções pequenas e bem nomeadas.

**Opcional (não obrigatório):** testes de propriedade com QuickCheck. Só se o resto estiver concluído; acrescenta uma dependência e não é exigido pelo framework.

---

### Elemento C (Duarte) — Dados de Teste, Casos de Erro e Documentação

**Responsabilidade central:** ampliar os dados de demonstração para cobrir casos de erro, e manter a documentação e o guião de apresentação atualizados.

| # | Tarefa | Entregável | Depende de |
|---|---|---|---|
| C1 | Ampliar `data/Seed.hs` com **cenários de erro e limite**: tarefa com dependência a ID inexistente, projeto sem sprints, sprint sem tarefas, tarefa sem responsável, membro sem tarefas | `data/Seed.hs` | A1, A2 |
| C2 | Documentar os cenários novos (o que cada um cobre e que resultado se espera) | `docs/dados_teste_fase2.md` | C1 |
| C3 | Testes sobre o `Seed` que verificam explicitamente `Just`/`Nothing` e `Right`/`Left` para os cenários de C1 | `test/Spec.hs` | B4, C1 |
| C4 | Guião de demonstração da Fase 2 (≤5 min: o que mostrar, por que ordem) | `docs/guiao_fase2.md` | A6, B6 |
| C5 | Nova secção "Fase 2 — Lógica Funcional e Transformação de Dados" no `README.md`, com o que foi adicionado e como testar | `README.md` | A6, B6 |

**Critérios de conclusão:**
- `data/Seed.hs` tem pelo menos 3 cenários de erro explícitos e continua a compilar com a suite de testes.
- A suite cobre `Just`/`Nothing` e `Right`/`Left`.
- `docs/dados_teste_fase2.md` e `docs/guiao_fase2.md` existem; `README.md` atualizado.

**Riscos:**
- Seed a crescer sem critério → manter minimalista: normal + 2 limites + 2 erros.
- Dependência de A/B → C pode escrever os testes primeiro (falham) e alinhar depois.

---

## 4. Regras de Colaboração e Git

- **Branches:** `feat/a2-transicoes`, `feat/b1-filtros-hof`, `feat/c1-seed-erros`.
- **Commits pequenos e frequentes**, mensagens claras (`feat: adiciona transitionTask com Either`, `test: cobre Left para dependência inexistente`).
- **Pull Requests** para `main` com pelo menos 1 revisão de outro elemento.

---

## 5. Critérios de Aceitação da Fase 2 (checklist coletivo)

- [ ] `cabal build` passa sem erros nem warnings.
- [ ] `cabal test` passa (24 casos herdados + novos).
- [ ] Transições de estado e validação de dependências devolvem `Either String` com mensagens significativas.
- [ ] Prioridade efetiva implementada como função pura.
- [ ] Pelo menos 3 funções usam `map`, `filter` ou `fold` de forma natural.
- [ ] Existe pelo menos um pipeline por composição (`.`).
- [ ] `Domain.hs` não importa módulos de IO.
- [ ] `Reports.hs` produz relatórios puros (sem IO).
- [ ] Testes cobrem casos normais, limite e erro (`Just`/`Nothing`, `Right`/`Left`).
- [ ] `data/Seed.hs` cobre casos normais, limite e erro.
- [ ] `docs/documentacao_fase2.md`, `docs/dados_teste_fase2.md` e `docs/guiao_fase2.md` existem.
- [ ] `README.md` atualizado com a secção da Fase 2.
- [ ] Nenhum entregável da Fase 3 (parsing, persistência, menu, IO) foi antecipado.

---

## 6. Definição de "Done" por Tarefa

1. O código compila e os testes passam.
2. Tem assinatura explícita e comentários onde necessário.
3. Foi revisto por pelo menos outro elemento (PR aprovado).
4. Está integrado em `main`.
5. Se aplicável, tem teste associado.
6. Se aplicável, está refletido na documentação (`README`, `docs/`).

---

## 7. Resultado Esperado ao Final da Fase 2

1. **Lógica de domínio** — transições de estado com `Either`, prioridade efetiva pura, validação de dependências com `Either`, mantendo `isBlocked` e o resto do contrato da Fase 1.
2. **HOF** — `filterBy` como função de ordem superior, predicados compostos, `map` para transformações.
3. **Pipelines** — `map . filter` em `Domain`/`Reports`, `fold` nas agregações.
4. **Erros** — `Either String` na criação/transição/validação; `Maybe` nas consultas.
5. **Arquitetura** — `Domain.hs` e `Reports.hs` puros; IO continua fora deles.
6. **Testes** — casos normais, limite e erro, incluindo os cenários de erro do `Seed`.
7. **Documentação** — `README.md` com secção de Fase 2, `docs/documentacao_fase2.md`, `docs/dados_teste_fase2.md` e `docs/guiao_fase2.md`.
