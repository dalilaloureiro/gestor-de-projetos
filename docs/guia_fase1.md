# Guia de Apresentação da Fase 1

## Objetivo

Este guião serve para apresentar a Fase 1 em poucos minutos, destacando os pontos principais do projeto sem entrar em detalhes excessivos de implementação.

## Ordem sugerida da apresentação

1. Breve visão do problema  
   Explicar que o projeto trata da gestão de tarefas, sprints e tempos de equipa.

2. Modelo de domínio  
   Mostrar os tipos principais: `TaskStatus`, `Priority`, `Task`, `Sprint`, `Project` e `AppState`.

3. Núcleo funcional puro  
   Explicar que `Domain.hs` contém consultas, filtros e cálculos recursivos sem IO.

4. Recursão justificada  
   Mostrar exemplos: progressos de sprint/projeto e detecção de bloqueios por dependências.

5. Dados de teste  
   Apresentar o ficheiro `data/seed.hs` e explicar quais cenários ele cobre.

6. Testes  
   Mostrar que o projeto já tem testes para consulta e progressos, usando casos normais e limites.

7. Fecho  
   Referir que a fase seguinte evolui para persistência e interface.

## Pontos-chave a reforçar

- modelação explícita do domínio
- uso de `Maybe` e `Either`
- operações puras e testáveis
- recursão estrutural em listas
- foco em regras de negócio, não em I/O

## Duração recomendada

- 2 minutos: contexto e visão geral
- 1 minuto: modelo e domínio
- 1 minuto: recursão e regras
- 1 minuto: testes e dados

Total estimado: 5 minutos.
