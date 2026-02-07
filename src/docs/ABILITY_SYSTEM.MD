# Ability System — documentação de implementação

Última atualização: 07/12/2025

Este documento descreve o sistema de "Abilities" (habilidades passivas) implementado no servidor, detalhando as alterações realizadas, a lógica de persistência e os gatilhos de ativação.

## Visão geral

O `Ability System` permite que Pokémon possuam habilidades passivas distintas (ex: Torrent, Rain Dish) que influenciam o combate ou regeneração. O sistema garante:

-   **Atribuição Única**: Cada Pokémon recebe uma habilidade (ID 1-3) ao ser capturado ou invocado pela primeira vez.
-   **Persistência**: A habilidade é salva na Pokéball (`pokeAbility`) e no corpo do monstro (`corpseAbility`), persistindo através de capturas, evoluções e reinícios do servidor.
-   **Atribuição Retroativa**: Pokémon antigos (capturados antes da atualização) recebem uma habilidade aleatória na primeira invocação.
-   **Suporte a Selvagens**: Pokémon selvagens recebem habilidades aleatórias "on-the-fly" ao tentar usá-las.
-   **Visualização**: O nome da habilidade é exibido na descrição da Pokéball (Look).

---

## Fluxo de dados (end-to-end)

1.  **Atribuição Inicial**
    -   **Selvagens**: Em `abilities.lua` (`getPokemonAbility`), se o monstro não tiver habilidade e não tiver mestre, uma aleatória é atribuída e salva no mapa global `MONSTER_ABILITY_MAP`.
    -   **Captura**: Ao capturar (`catch.lua`), o script lê `corpseAbility` do corpo e passa para `doAddPokeball`.
    -   **Retroativo**: Em `doReleaseSummon`, se a bola não tiver `pokeAbility`, uma aleatória é gerada e salva na bola.

2.  **Pokéball -> Summon (Release)**
    -   Ao liberar (`doReleaseSummon`), o script lê `abilityId = ball:getSpecialAttribute("pokeAbility")`.
    -   O ID é registrado no mapa global `MONSTER_ABILITY_MAP` vinculado ao CID do monstro.

3.  **Summon -> Pokéball (Recall/Death)**
    -   **Recall**: Ao recolher (`doRemoveSummon`), a entrada é removida do mapa global. A habilidade já está salva na bola, então não precisa ser atualizada (é imutável).
    -   **Morte**: Ao morrer (`corpselevel.lua`), a habilidade é lida do mapa global e salva no corpo como `corpseAbility`, permitindo que o Pokémon seja recapturado com a mesma habilidade.

4.  **Evolução**
    -   Ao evoluir (`doEvolveSummon`), o atributo `pokeAbility` é copiado da bola antiga para a nova, garantindo que a habilidade persista na nova forma.

---

## Como o sistema foi implementado (passo a passo)

### 1. Lógica Central (`data/lib/core/abilities.lua`)
-   **`ABILITY_DEFINITIONS`**: Tabela contendo a lógica de cada habilidade (`onThink`, `onAttack`, `onHealthChange`).
-   **`POKEMON_ABILITIES`**: Mapeamento de Pokémon para suas possíveis habilidades.
-   **`MONSTER_ABILITY_MAP`**: Tabela global para armazenar a habilidade ativa de cada monstro (CID -> AbilityID).

### 2. Alterações em Lua

-   **`src/data/lib/core/newfunctions.lua`**
    -   **`doAddPokeball`**: Atualizado para aceitar `abilityId` e salvar `pokeAbility`.
    -   **`doReleaseSummon`**: Lê `pokeAbility` e registra no mapa global. Implementa atribuição retroativa.
    -   **`doEvolveSummon`**: Transfere `pokeAbility` para a nova bola.

-   **`src/data/actions/scripts/poke/catch.lua`**
    -   Lê `corpseAbility` do corpo e passa para `doAddPokeball`.

-   **`src/data/creaturescripts/scripts/corpselevel.lua`**
    -   Ao morrer, salva a habilidade do monstro no corpo (`corpseAbility`) e loga no console.

-   **`src/data/events/scripts/player.lua`**
    -   **`onLook` / `onLookInTrade`**: Exibe "Ability: [Nome]" na descrição da Pokéball.

-   **`src/data/spells/scripts/abilities/trigger.lua`**
    -   Spell genérica (`ability_trigger`) usada em `spells.xml` para ativar efeitos periódicos (`onThink`).

-   **`src/data/creaturescripts/scripts/monsterhealthchange.lua`**
    -   Gatilhos reativos para `onAttack` e `onHealthChange`.

---

## Persistência e Atributos

-   **`pokeAbility`** (Item Attribute): ID numérico da habilidade salvo na Pokéball.
-   **`corpseAbility`** (Item Attribute): ID numérico salvo no corpo do monstro morto.
-   **`MONSTER_ABILITY_MAP`** (Global Table): Armazenamento em memória durante a vida do monstro.

---

## Testes Sugeridos

1.  **Captura e Persistência**:
    -   Spawnar Blastoise selvagem -> Verificar habilidade (texto visual) -> Capturar.
    -   Dar Look na bola -> Verificar se a habilidade bate.
    -   Summonar -> Verificar se a habilidade continua funcionando.

2.  **Retroatividade**:
    -   Pegar uma bola antiga (sem habilidade).
    -   Summonar -> Recolher -> Look.
    -   Deve ter ganho uma habilidade aleatória.

3.  **Evolução**:
    -   Ter um Squirtle com habilidade X.
    -   Evoluir para Wartortle.
    -   Verificar se Wartortle mantém a habilidade X.

4.  **Selvagens**:
    -   Spawnar monstro selvagem.
    -   Verificar se ele usa habilidades (ex: cura na chuva, dano extra com vida baixa).

---

## Observações

O sistema foi desenhado para ser extensível. Novas habilidades podem ser adicionadas apenas editando `abilities.lua`, sem necessidade de mexer em C++ ou scripts de núcleo. A decisão de usar uma tabela global (`MONSTER_ABILITY_MAP`) foi tomada devido à limitação de `Monster` objects não possuírem armazenamento persistente acessível via Lua da mesma forma que Players.
