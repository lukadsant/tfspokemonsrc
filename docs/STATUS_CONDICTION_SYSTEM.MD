# Alterações no Sistema de Condições de Status

Este documento detalha as melhorias feitas no Sistema de Condições de Status dos Summons para garantir que as condições persistam após o recall e sejam claramente visíveis para o jogador.

## 1. Persistência de Condições
**Objetivo**: Impedir que os jogadores removam efeitos de status negativos (como Sleep ou Poison) simplesmente recolhendo e invocando novamente seu Pokémon.

**Implementação**:
- **Salvamento**: Quando um summon é removido (`doRemoveSummon`), o sistema verifica se há condições ativas. Se encontradas, a duração restante (ticks) é salva nos atributos especiais da pokébola (ex: `pokeSleepTicks`, `pokePoisonTicks`).
- **Restauração**: Quando um summon é liberado (`doReleaseSummon`), o sistema verifica a pokébola por esses atributos. Se encontrados, a condição é reaplicada ao monstro com a duração salva.

**Condições Suportadas**:
- Sleep (`CONDITION_SLEEP`)
- Paralyze (`CONDITION_PARALYZE`)
- Poison (`CONDITION_POISON`)
- Burn (`CONDITION_FIRE`)
- Energy (`CONDITION_ENERGY`)
- Drunk (`CONDITION_DRUNK`)
- Freezing (`CONDITION_FREEZING`)
- Dazzled (`CONDITION_DAZZLED`)
- Cursed (`CONDITION_CURSED`)
- Bleeding (`CONDITION_BLEEDING`)

## 2. Efeitos Visuais e Animação
**Objetivo**: Garantir que o feedback visual (como "Zzz" para sono) persista quando o monstro for invocado novamente.

**Implementação**:
- Como as condições padrão podem não retomar automaticamente seus efeitos no cliente após a reaplicação via script, foram adicionados loops personalizados.
- **Funções**: `sendSleepEffect`, `sendPoisonEffect`, `sendBurnEffect`.
- Essas funções chamam a si mesmas recursivamente usando `addEvent` a cada 2 segundos para reproduzir o efeito mágico apropriado (`CONST_ME_SLEEP`, `CONST_ME_HITBYPOISON`, etc.) enquanto a condição existir na criatura.

## 3. Dano Periódico
**Objetivo**: Garantir que as condições de dano continuem a causar dano após a reinvocação.

**Implementação**:
- As condições restauradas são configuradas com dano periódico padrão (ex: 50 de dano a cada 2 segundos) para garantir que continuem sendo uma ameaça.
- **Nota**: Isso usa um valor padrão fixo, pois recuperar a fórmula exata de dano original do objeto de condição em Lua é limitado.

## 4. Descrição da Pokébola
**Objetivo**: Permitir que os jogadores vejam se um Pokémon está afetado por uma condição sem precisar invocá-lo.

**Implementação**:
- Modificado `updatePokeballDescription` em `newfunctions.lua` e `Player:onLook` em `player.lua`.
- O texto de "look" agora anexa o status ao final, ex:
  > It contains a Bellsprout. Level: 10. ... **Status: Sleeping.**

## Arquivos Modificados
- `src/data/lib/core/newfunctions.lua`: Lógica central para salvar/restaurar condições e atualizar descrições.
- `src/data/events/scripts/player.lua`: Lógica para exibir descrições em `onLook` e `onLookInTrade`.
