# Nickname persistence — debugging notes

Date: 2025-11-21
Repository path: src/data/lib/core/newfunctions.lua, src/data/talkactions/scripts/give_nickname.lua, src/monster.cpp, src/creature.cpp, src/luascript.cpp

## Problem summary (Português)

O problema: nicknames dados por `!givenickname` são aplicados corretamente ao summon e persistem na pokeball após captura, mas ao recolher / re-summonar às vezes o pokémon aparece sem o nickname — como se o `pokeNickname` não tivesse sido persistido ou a pokeball correta não tivesse sido escolhida no recall.

Logs de sessão (trecho):

```
GOD Pota has logged in.
WARNING! Pokedex successfully built.
give_nickname: propagated nickname=	pota	 to ball uid=	65536
give_nickname: saved nickname=	pota	 to ball uid=	65536	 pokeName=	Bellsprout
doReleaseSummon: using ball uid=	65537	 pokeName=	Bellsprout	 pokeNickname=	pota
[Creature::setNatureAndLock] creature id=0 nature 0 -> 5
doReleaseSummon: using ball uid=	65539	 pokeName=	Bellsprout	 pokeNickname=	Bellsprout
[Creature::setNatureAndLock] creature id=0 nature 0 -> 5
wgive_nickname: propagated nickname=	pota	 to ball uid=	65541
give_nickname: saved nickname=	pota	 to ball uid=	65541	 pokeName=	Bellsprout
doReleaseSummon: using ball uid=	65542	 pokeName=	Bellsprout	 pokeNickname=	pota
[Creature::setNatureAndLock] creature id=0 nature 0 -> 5
doReleaseSummon: using ball uid=	65544	 pokeName=	Bellsprout	 pokeNickname=	Bellsprout
[Creature::setNatureAndLock] creature id=0 nature 0 -> 5
```

Observação: repara-se que o `give_nickname` salvou `pota` em UID 65536 e 65541, mas `doReleaseSummon` está usando outras UIDs (65537, 65539, 65542, 65544) para criar summons — parte deles têm `pokeNickname = pota`, outros não.

## Reproduzir (passos sugeridos)

1. Iniciar servidor com as mudanças atuais.
2. Como GOD, spawnar um `Bellsprout` com nickname, ou usar `!givenickname pota` em uma pokeball existente.
3. Checar que o summon aparece com o nick.
4. Capturar o summon (fluxo de captura atual já grava `corpseNickname` -> `doAddPokeball` parameter -> `addBall:setSpecialAttribute("pokeNickname", safeNick)`).
5. Conferir o atributo `pokeNickname` na pokeball (onLook deve também mostrar `Nickname: pota`).
6. Re-summonar e imediatamente recolher; observar o log `doReleaseSummon: using ball uid= ... pokeNickname= ...` e verificar se a UID corresponde à mesma pokeball que recebeu o `pokeNickname` na captura. Repetir várias vezes com múltiplas balls idênticas.

## Código e pontos relevantes (onde procurar)

- Lua (summon/release/recall pipeline):
  - `src/data/lib/core/newfunctions.lua`
    - doReleaseSummon (lê `ball:getSpecialAttribute("pokeNickname")` e chama `Game.createMonster(..., storedNickname)`)
    - doRemoveSummon (persistência em recall: grava `ball:setSpecialAttribute("pokeNickname", sname)`)
    - doAddPokeball (quando captura: grava `addBall:setSpecialAttribute("pokeNickname", safeNick)` quando `corpseNickname` existe)
    - sanitizeNickname / updatePokeballDescription
  - `src/data/talkactions/scripts/give_nickname.lua`
    - persiste `pokeNickname` com `ball:setSpecialAttribute("pokeNickname", nickname)` e propaga para matching balls

- C++ (nome atômico / lock):
  - `src/creature.h/cpp` - `Creature::setNameAndLock`, `Creature::isNameLocked()`
  - `src/monster.h/cpp` - `Monster::createMonster(..., initName)` e `Monster` constructor chamando `setNameAndLock(initName)`
  - `src/luascript.cpp` - binding `luaGameCreateMonster` foi alterado para aceitar o `initName` e passar ao `Monster::createMonster`.

## Alterações já aplicadas (resumo)

- `!givenickname`:
  - sanitizer, propagation to matching pokeballs
  - removed deferred rename attempts when the summon has `isNameLocked()` to avoid noisy C++ backtraces

- `newfunctions.lua`:
  - Summon creation now passes stored nickname into `Game.createMonster(..., initName)` so the C++ constructor applies + locks the name atomically.
  - On successful creation we now store the originating ball UID on the monster with `monster:setStorageValue(95001, ball.uid)`.
  - On remove/recall we first try to find the origin ball by reading `summon:getStorageValue(95001)` and using that Item instance if present; fallback to previous heuristics if not found.
  - Deferred helpers that call `setName` were guarded by `isNameLocked()` to avoid overwrite attempts.

## Hipóteses (por que ainda ocorre)

1. Origin UID is not being stored or not persisted for some summons:
   - `monster:setStorageValue(95001, ball.uid)` may fail silently in some flows (pcall used), or the `ball` value at moment of creation isn't the correct one.
   - Race condition: `doReleaseSummon` might be using a different `ball` object (player:getUsingBall() or other heuristics) than the one that the player expects. If `ball` is changed between the time nickname is saved and summon creation, the stored origin UID can be incorrect.

2. Multiple identical pokeballs + propagation inconsistencies:
   - `give_nickname` propagates the nickname to matching pokeballs, but propagation depends on matching attributes (pokeName, level, boost, owner). If those attributes differ or are missing on some items, a subset of balls will have the nickname while the one chosen at release will not.

3. Capture path vs give_nickname path:
   - Capturing writes `pokeNickname` during `doAddPokeball` (from `corpseNickname` param). `!givenickname` writes with `ball:setSpecialAttribute("pokeNickname", nickname)` on the chosen ball. If these two write flows target different item instances (e.g., the ball returned to backpack is a different UID), the visible data will vary.

4. Storage vs temporary data:
   - There are multiple ephemeral markers: `isBeingUsed`, `lastSummonAt`, player storage 95000, monster storage 95001. Any of these might be set/cleared at unexpected times.

## Suggested next diagnostics (high priority)

1. Add deterministic debug traces (temporary) around these points and include the `ball.uid` and table identity where possible:
   - Right before `monster:setStorageValue(95001, ball.uid)` in `doReleaseSummon`.
   - Right before the `ball:setSpecialAttribute("pokeNickname", sname)` in `doRemoveSummon` (recall) to log which ball instance is being written.
   - When `doAddPokeball` adds a ball (capture), log the UID of the created `addBall` and any `corpseNickname` it received.
   - In `give_nickname`, log the chosen `ball.uid` and list all balls that were updated during propagation.

2. Confirm that `monster:setStorageValue` persists across the monster lifetime (some TFS builds treat monster/player storages differently). If monsters do not support storage as expected, consider storing `originUid` in a lightweight map in Lua keyed by `monster:getId()` (and clean up on monster death/remove).

3. Re-run the reproduce steps with the extra logging and capture the full sequence of events (spawn -> give_nickname -> capture -> doAddPokeball -> use/release -> doReleaseSummon -> doRemoveSummon). Compare the UIDs at each step.

4. If origin UID is absent or wrong in some cases, inspect the logic that picks `ball` in `doReleaseSummon` — player:getUsingBall() vs heuristics. Consider making the selection deterministic by preferring `player:getSlotItem(CONST_SLOT_AMMO)` if present and matching expected attributes, or require players to place the ball in the ammo slot before summoning for testing.

## Suggested code fixes (ranked)

1. (Defensive) If monster storages are unreliable, maintain a Lua table mapping `monster:getId()` -> origin UID when you call `player:addSummon(monster)` and use that mapping in `doRemoveSummon` as the first preference. Remember to clear mapping when summon is removed.

2. (Robust) Ensure `monster:setStorageValue(95001, ball.uid)` is executed unconditionally (avoid silent pcall swallowing actual errors) — log failure if it returns false.

3. (Deterministic) On `doReleaseSummon`, pass the `ball.uid` into `Game.createMonster` as an additional optional parameter (not currently supported), or record as suggested (monster storage). This ties the created monster to the origin item deterministically.

4. (Propagation) Improve `give_nickname` propagation heuristics to include item location (ammo/backpack slot), and optionally push nickname to all identical balls by item template UID rather than only matching attributes.

5. (Cleanup) Remove debug prints when fixed; tighten use of `pcall` so errors don't silently hide problems.

## Minimal test plan

- Unit manual test: create 3 identical pokeballs for a player, name only one with `!givenickname`, spawn and recall repeatedly; expect the recalled ball to be the same UID the summon came from and keep the nickname.
- Acceptance: no occurrences of mismatch for UID or missing `pokeNickname` in 20 repeated cycles across random picks.

## Commands (build / run)

```bash
cd /path/to/src
make -j$(nproc)
# restart server (adjust to your run method)
pkill -f tfs || true
./tfs
```

## Checklist for the next developer/agent

- [ ] Add temporary logs around origin UID store and recall write.
- [ ] Reproduce and paste full chronological logs (spawn -> give_nickname -> capture -> addBall UID -> release -> removeSummon using ball UID -> recall write). Include timestamps to correlate.
- [ ] If monster storage appears unreliable, implement in-Lua mapping fallback keyed by `monster:getId()`.
- [ ] After fix, remove temporary logs and debug prints.

---

If precisar, posso aplicar as mudanças de debug (log prints) e rodar uma sessão de testes automáticos aqui no workspace. Diga se quer que eu:

- A: adicione logs e rode a build/testes e cole os resultados aqui, ou
- B: você mesmo aplica os passos de teste e me envia os logs para eu analisar.


