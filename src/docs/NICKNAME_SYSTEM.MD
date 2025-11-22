# Nickname System — documentação de implementação

Última atualização: 21/11/2025

Este documento descreve o sistema de "Nickname" (apelidos) implementado no servidor, detalhando as alterações realizadas e o fluxo de dados para garantir a persistência correta dos nomes.

## Visão geral

O `Nickname System` permite que jogadores atribuam nomes personalizados aos seus summons. O sistema garante:

- Atribuição de apelidos via comando `!givenickname`.
- Persistência do apelido no item (pokéball) através do atributo especial `pokeNickname`.
- Restauração do apelido ao evocar o summon (release), aplicando o nome no momento da criação.
- Preservação do apelido ao recolher o summon (recall), evitando sobrescrita acidental pelo nome padrão.

Para garantir a robustez, o sistema utiliza um mecanismo de "lock" semelhante aos sistemas de Gender e Nature, impedindo que o nome seja alterado indevidamente após a criação.

---

## Fluxo de dados (end-to-end)

1. **Definição (`!givenickname`)**
    - O jogador usa o comando `!givenickname <nome>`.
    - O script `give_nickname.lua` sanitiza o nome e o aplica:
        - Ao **summon ativo** (se houver e o nome não estiver travado).
        - À **pokéball** correspondente (atributo `pokeNickname`).

2. **Pokéball -> Summon (Release)**
    - Ao liberar (`doReleaseSummon`), o script lê `storedNickname = ball:getSpecialAttribute("pokeNickname")`.
    - O valor é passado para `Game.createMonster(..., storedNickname)`.
    - O construtor do `Monster` (C++) recebe `initName` e chama `setNameAndLock(initName)`, aplicando o nome e travando-o (`nameLocked = true`).

3. **Summon -> Pokéball (Recall)**
    - Ao recolher (`doRemoveSummon`), o script verifica o nome atual do summon.
    - **Lógica de Proteção**: O script compara o nome do summon com o nome padrão da espécie (`monsterType:getName()`).
    - O atributo `pokeNickname` na pokéball só é atualizado se o nome do summon for **diferente** do padrão. Isso evita que um summon cujo nome não pôde ser alterado (ex: travado) sobrescreva um apelido válido na pokéball com o nome padrão.

4. **Persistência em Captura**
    - Ao capturar um monstro (`doAddPokeball`), se o corpo tiver um `corpseNickname` (ou se for um monstro selvagem sem nick), o atributo é salvo na nova pokéball.

---

## Como o sistema foi implementado (passo a passo)

### 1. Alterações em C++

- **`src/monster.h` / `src/monster.cpp`**
    - `Monster::createMonster` e o construtor foram atualizados para aceitar um parâmetro opcional `const std::string& initName`.
    - Se `initName` for fornecido, o construtor chama `setNameAndLock(initName)`.

- **`src/creature.h` / `src/creature.cpp`**
    - Adicionado método `setNameAndLock(name)`: define o nome e seta a flag `nameLocked = true`.
    - Adicionado método `isNameLocked()`: retorna o estado da flag.
    - `Creature::setName` respeita o lock, impedindo alterações se `nameLocked` for verdadeiro (exceto se for o mesmo nome).

- **`src/luascript.cpp`**
    - `luaGameCreateMonster` foi atualizado para ler o 9º argumento (string) e passá-lo como `initName` para o C++.

### 2. Alterações em Lua

- **`src/data/lib/core/newfunctions.lua`**
    - **`doReleaseSummon`**:
        - Lê `pokeNickname` da pokéball.
        - Passa o nickname como último argumento para `Game.createMonster`.
        - Persiste o UID da pokéball de origem no summon (`monster:setStorageValue(95001, ball.uid)`) para garantir o vínculo correto no recall.
    - **`doRemoveSummon`**:
        - Recupera a pokéball correta usando o UID armazenado (storage 95001) ou fallback para `getUsingBall`.
        - Verifica se o nome do summon difere do padrão (`summon:getType():getName()`).
        - Atualiza `pokeNickname` na pokéball apenas se houver um apelido válido e diferente do padrão.

- **`src/data/talkactions/scripts/give_nickname.lua`**
    - Implementa a lógica de comando.
    - Tenta renomear o summon ativo. Se falhar (nome travado), avisa o jogador e salva apenas na pokéball.
    - Propaga o apelido para pokéballs correspondentes no inventário.

---

## Persistência e Atributos

- **`pokeNickname`** (Item Attribute): Armazena a string do apelido na pokéball.
- **`nameLocked`** (Creature Flag): Indica que o nome foi definido na criação e não deve ser alterado por rotinas comuns.

---

## Testes Sugeridos

1.  **Fluxo Básico**:
    - Invocar monstro -> `!givenickname Teste` -> Recolher -> Invocar novamente.
    - Verificar se o nome "Teste" persiste.

2.  **Persistência no Recall**:
    - Ter um monstro com apelido "Teste".
    - Forçar uma situação onde o summon não tem o nome (ex: via script de debug ou falha simulada).
    - Recolher o monstro.
    - Verificar se a pokéball **mantém** "Teste" e não foi sobrescrita por "Bellsprout".

3.  **Múltiplas Pokéballs**:
    - Ter 3 Bellsprouts idênticos.
    - Dar apelido a um deles.
    - Garantir que apenas a pokéball correta recebe/mantém o apelido ao invocar e recolher.

---

## Observações

O sistema segue estritamente o padrão estabelecido pelos sistemas de **Gender** e **Nature**, garantindo consistência na base de código e facilitando a manutenção. A correção crítica no `doRemoveSummon` (verificação de nome padrão e scoping de variável) foi essencial para resolver problemas de desaparecimento de nicks.
