# Atribuição de Tarefas — Fase 1 (Modelação e Núcleo Funcional)


## 1. Visão Geral da Fase 1

Objetivo central: estabelecer os fundamentos do projeto.

```
tipos -> listas/estruturas -> pattern matching -> recursão -> núcleo do domínio
```

Entregáveis obrigatórios da Fase 1:

- [ ] Modelo de domínio (data types, records, relações)
- [ ] Estrutura do projeto (módulos iniciais e repositório)
- [ ] Funções essenciais puras (regras de domínio)
- [ ] Recursão justificada
- [ ] Dados de teste pequenos
- [x] README inicial
- [x] Histórico Git

---

## 2. Princípios de Divisão de Trabalho

Para evitar bloqueios e sobreposição:

1. **Elemento A é o "dono do modelo"**: define os tipos primeiro; B e C não avançam com funções que dependam de tipos ainda não acordados.
2. **Contrato de tipos na primeira metade da fase**: A publica `Model.hs` cedo; B e C trabalham contra esse contrato.
3. **Cada elemento tem um módulo principal claro** (ver secção 3).
4. **Integração contínua manual**: commits frequentes, branches curtas, merge para `main` só com build a passar.
5. **Revisão cruzada obrigatória**: cada PR é revisto por pelo menos outro elemento.
6. **Reunião curta semanal** (15–30 min) para sincronizar e desbloquear.

---

## 3. Atribuição por Elemento

### Elemento A (Francisco) — Modelação e Estrutura do Projeto

**Responsabilidade central:** definir o modelo de domínio e garantir a estrutura inicial do repositório e dos módulos.

| # | Tarefa | Entregável | Depende de |
|---|---|---|---|
| A1 | Definir ADTs e records principais (`TaskStatus`, `Priority`, `Member`, `Label`, `Task`, `Sprint`, `Project`, `AppState`) | `src/Model.hs` | — |
| A2 | Definir assinaturas explícitas dos tipos e derivar `Eq`, `Show`, `Read`, `Enum`, `Bounded` onde fizer sentido | `src/Model.hs` | A1 |
| A3 | Criar estrutura inicial do repositório (`taskflow.cabal`, `cabal.project`, pastas `src/`, `app/`, `test/`, `data/`, `docs/`) | Repositório compilável vazio | — |
| A4 | Criar módulos esqueleto (`Domain.hs`, `Parsing.hs`, `Persistence.hs`, `Reports.hs`) com assinaturas comentadas (stubs) | Ficheiros `.hs` com `undefined`/comentários | A3 |
| A5 | Configurar `app/Main.hs` mínimo que compila e imprime uma mensagem | Build a passar | A3 |
| A6 | Documentar o modelo de domínio (diagrama simples em texto/mermaid + justificação das decisões) | `docs/modelo.md` | A1 |
| A7 | Manter `README.md` inicial (descrição, compilação, execução, estrutura) | `README.md` | A3 |

**Critérios de conclusão:**
- `cabal build` passa sem erros.
- `Model.hs` cobre todas as entidades e relações da proposta.
- Assinaturas explícitas em todas as funções principais do modelo (getters/derivações).
- `README.md` permite a um terceiro compilar e executar.

**Riscos:**
- Modelo demasiado ambicioso → começar pelo subconjunto mínimo e evoluir.
- Tipos instáveis a meio da fase → congelar o contrato de tipos até ao final da semana 1 da fase; alterações posteriores exigem aviso a B e C.

---

### Elemento B (Dalila) — Funções Puras Essenciais e Recursão

**Responsabilidade central:** implementar o núcleo funcional puro sobre o modelo definido por A, com recursão justificada.

| # | Tarefa | Entregável | Depende de |
|---|---|---|---|
| B1 | Funções de criação/consulta: `findProject`, `findSprint`, `findTask` por ID (retornam `Maybe`) | `src/Domain.hs` | A1 |
| B2 | Listagens puras: listar projetos, sprints de um projeto, tarefas de um sprint | `src/Domain.hs` | A1 |
| B3 | Filtros simples: por estado, por prioridade, por responsável | `src/Domain.hs` | A1 |
| B4 | **Recursão justificada #1**: cálculo de progresso de um sprint (percorrer tarefas e contar `Done`) | `progressSprint` em `Domain.hs` | B1 |
| B5 | **Recursão justificada #2**: cálculo de progresso de um projeto (percorrer sprints) | `progressProject` em `Domain.hs` | B4 |
| B6 | **Recursão justificada #3**: verificação de dependências de uma tarefa (percorrer `taskDependsOn` e verificar se estão `Done`) | `isBlocked` em `Domain.hs` | B1 |
| B7 | Funções auxiliares de formatação pura (ex.: `showStatus`, `showPriority`) | `Domain.hs` ou `Reports.hs` (stub) | A2 |
| B8 | Assinaturas explícitas em todas as funções implementadas | `Domain.hs` | — |

**Critérios de conclusão:**
- Todas as funções têm assinatura explícita.
- Cada função recursiva tem um comentário a justificar porque é recursiva (e não um `fold`).
- Pattern matching usado em vez de `if` sempre que apropriado.
- Funções testáveis de forma pura (sem IO).

**Riscos:**
- Bloqueio se A atrasar o modelo → B pode avançar com stubs tipados e preencher depois.
- Recursão forçada → preferir recursão estrutural natural (listas de tarefas/sprints); não inventar recursão onde um `fold` é mais claro (o `fold` entra na Fase 2, mas pode ser usado já se simplificar).

---

### Elemento C (Duarte) — Dados de Teste, Testes Iniciais e Documentação de Suporte

**Responsabilidade central:** preparar dados de demonstração, começar a suite de testes das funções puras e apoiar a documentação.

| # | Tarefa | Entregável | Depende de |
|---|---|---|---|
| C1 | Definir um pequeno conjunto de dados de teste (1 projeto, 2 sprints, ~8 tarefas com estados/prioridades variados, dependências e etiquetas) | `data/seed.hs` (valores Haskell) | A1 |
| C2 | Documentar os dados de teste (o que cada cenário cobre) | `docs/dados_teste.md` | C1 |
| C3 | Configurar a suite de testes (`test/Spec.hs`) com framework simples (ex.: `HUnit` ou testes manuais com `assert`) | `test/Spec.hs` compilável | A3 |
| C4 | Testes das funções de consulta (`findProject`, `findSprint`, `findTask`) — caso existente e caso inexistente (`Nothing`) | `test/Spec.hs` | B1 |
| C5 | Testes das funções recursivas: `progressSprint`, `progressProject`, `isBlocked` — casos normais e limites (sprint vazio, todas `Done`, dependência não concluída) | `test/Spec.hs` | B4–B6 |
| C6 | Documentação de suporte à apresentação da Fase 1 (guião curto: o que mostrar, por que ordem) | `docs/guiao_fase1.md` | A6, B8 |
| C7 | Apoiar A na revisão do `README.md` (secção de testes e dados) | `README.md` | A7 |

**Critérios de conclusão:**
- `cabal test` (ou equivalente) corre e passa.
- Dados de teste cobrem casos normais e pelo menos 2 casos limite.
- Guião de demonstração permite apresentar a Fase 1 em ≤5 minutos.

**Riscos:**
- Dependência forte de B → C pode começar por escrever os testes como "especificação" (falham primeiro), alinhando com B.
- Framework de testes pesado → usar o mais simples possível; o objetivo é demonstrar a prática, não a ferramenta.



## 5. Regras de Colaboração e Git

- **Branches:** `feat/a-modelo`, `feat/b-domain`, `feat/c-testes` (ou por tarefa: `feat/a1-model`).
- **Commits pequenos e frequentes**, mensagens claras (`feat: adiciona ADT TaskStatus`, `test: cobre progressSprint vazio`).
- **Pull Requests** para `main` com pelo menos 1 revisão de outro elemento.




## 6. Critérios de Aceitação da Fase 1 (checklist coletivo)

Antes da apresentação, o grupo deve conseguir marcar todos:

- [ ] `cabal build` passa sem erros nem warnings relevantes.
- [ ] `cabal test` passa.
- [ ] `src/Model.hs` contém todos os ADTs e records previstos, com derivações adequadas.
- [ ] Todas as funções em `Domain.hs` têm assinatura explícita.
- [ ] Existem pelo menos 3 funções recursivas justificadas por comentário.
- [ ] Pattern matching é usado nas funções de domínio.
- [ ] `data/seed.hs` (ou equivalente) permite demonstrar o sistema.
- [ ] `README.md` explica objetivo, compilação, execução e estrutura.
- [ ] `docs/modelo.md` justifica as decisões de modelação.



## 8. Definição de "Done" por Tarefa

Uma tarefa só está concluída quando:

1. O código compila e os testes passam.
2. Tem assinatura explícita (funções) e comentários onde necessário.
3. Foi revista por pelo menos outro elemento (PR aprovado).
4. Está integrada em `main`.
5. Se aplicável, tem teste associado.
6. Se aplicável, está refletida na documentação (`README`, `docs/`).

