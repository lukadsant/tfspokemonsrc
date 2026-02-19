Sistema de Natures (Personalidades)

Este documento descreve o sistema de "Nature" (personalidade) implementado no servidor, quais arquivos foram alterados e os passos necessários para adicionar/alterar natures.

## Visão geral

Cada criatura (monstro/summon/pokémon) pode possuir uma Nature (personalidade). Cada Nature pode:

- Aumentar um atributo em +10% (boost).
- Reduzir um atributo em -10% (reduce).
- Ser neutra (quando aumenta e reduz o mesmo atributo — nenhum efeito).

As Natures são representadas por constantes `NATURE_*` (enum C++) e registradas no ambiente Lua. Quando um pokéball armazena uma criatura, seu valor numérico de Nature é persistido no atributo especial `pokeNature`. Em corpses usamos `corpseNature` para depuração/persistência.

As estatísticas afetadas atualmente são: `attack`, `magicAttack`, `defense`, `magicDefense` e `speed`.

## Tabela de natures

Nature | Increases | Decreases
---|---:|---:
Adamant | Attack | Magic Attack
Bashful | Magic Attack | Magic Attack (neutral)
Bold | Defense | Attack
Brave | Attack | Speed
Calm | Magic Defense | Attack
Careful | Magic Defense | Magic Attack
Docile | Defense | Defense (neutral)
Gentle | Magic Defense | Defense
Hardy | Attack | Attack (neutral)
Hasty | Speed | Defense
Impish | Defense | Magic Attack
Jolly | Speed | Magic Attack
Lax | Defense | Magic Defense
Lonely | Attack | Defense
Mild | Magic Attack | Defense
Modest | Magic Attack | Attack
Naive | Speed | Magic Defense
Naughty | Attack | Magic Defense
Quiet | Magic Attack | Speed
Quirky | Magic Defense | Magic Defense (neutral)
Rash | Magic Attack | Magic Defense
Relaxed | Defense | Speed
Sassy | Magic Defense | Speed
Serious | Speed | Speed (neutral)
Timid | Speed | Attack

## Como o sistema foi implementado (passo a passo)

Resumo das alterações principais e onde procurar o código:

1. Constantes / enum
	- Arquivo: `src/const.h`
	- Foi adicionada a enum `Natures_t` contendo as constantes `NATURE_*` (25 entradas). Estas constantes são usadas tanto em C++ quanto em Lua.

2. Registro em Lua
	- Arquivo: `src/luascript.cpp`
	- Todas as constantes `NATURE_*` são registradas com `registerEnum(...)` para ficarem acessíveis nos scripts Lua.

3. Extensão do parsing de monstros (opcional/definido por `MonsterType`)
	- Arquivo: `src/monsters.cpp` / `src/monsters.h`
	- `MonsterType::MonsterInfo` foi estendido para suportar uma natureza por defeito definida no XML do monstro e para listas/opções de `naturerandom` (quando aplicável).

4. Passagem/armazenamento de nature ao criar monstros
	- Arquivos: `src/monster.cpp`, `src/monster.h`, `src/game.cpp` (pontos de criação relevantes)
	- `Monster::createMonster` e o construtor de `Monster` foram atualizados para aceitar um parâmetro `initNature`. A precedência de seleção da nature é: `MonsterType::info.nature` (defaut no XML) > `initNature` passado pela API > escolha ponderada/aleatória definida em `MonsterType` > `NATURE_NONE` para summons sem nature.
	- Quando o parâmetro `initNature` for usado pelo código chamador, `setNatureAndLock` é aplicado para evitar que o C++ sobrescreva o valor logo em seguida.

5. API de Creature (C++)
	- Arquivos: `src/creature.h`, `src/creature.cpp`
	- Adicionados membros `Natures_t nature`, `bool natureLocked`, e métodos `setNature` / `setNatureAndLock` (espelhando o modelo usado para skull/sex). `setNatureAndLock` faz lock para indicar que a value foi definida por inicialização e não deve ser sobrescrita por rotinas automáticas.

6. Bindings Lua para Nature
	- Arquivo: `src/luascript.cpp` (registrations) e `src/luascript.h` (declarações)
	- `Creature:getNature()` e `Creature:setNature(nature)` foram expostos ao Lua; `setNature` usa `setNatureAndLock` para preservar o valor quando scripts definem nature manualmente.

7. Persistência e scripts Lua
	- Arquivos: vários scripts Lua em `src/data/...` (por exemplo, captura/liberação e corpse scripts)
	- `pokeNature` foi adicionado como atributo especial no item pokéball quando uma criatura é capturada. Ao liberar o summon a partir da pokéball, o atributo `pokeNature` (se presente) é passado para `Game.createMonster` para que a summon mantenha a mesma natureza.
	- `corpseNature` também foi gravado nos scripts de corpse para depuração e persistência intermediária.

8. Mapeamentos e aplicação de modificadores (Lua)
	- Arquivo: `src/data/lib/core/newfunctions.lua`
	- Duas tabelas globais foram adicionadas: `natureBoost` e `natureReduce`, que mapeiam `NATURE_*` para a string do atributo afetado (por exemplo, "attack", "magicAttack", "defense", "magicDefense", "speed").
	- A função utilitária `applyNatureModifier(total, statName, creature)` aplica a multiplicação correta:
		 - se `boost == statName` e `reduce ~= statName`: floor(total * 1.10)
		 - se `reduce == statName` e `boost ~= statName`: floor(total * 0.90)
		 - se `boost == reduce == statName` (neutral): sem alteração
	- Esta função é utilizada nas funções por-stat do monster (ex.: `Monster.getTotalMeleeAttack`, `Monster.getTotalMagicAttack`, `Monster.getTotalDefense`, `Monster.getTotalMagicDefense`, `Monster.getTotalSpeed`).

9. Interface de apresentação (on-look)
	- Arquivo: `src/data/events/scripts/player.lua`
	- `Player:onLook` (e variações `onLookInTrade` / `onLookInBattleList`) foram atualizados para mostrar a Nature legível e, para summons, anotar visualmente os efeitos de boost/reduce: por exemplo "Attack: 55 (+10%)" e "Defense: 45 (-10%)". A implementação usa `natureBoost`/`natureReduce` para manter a UI sincronizada com a lógica.

10. Limpeza e testes locais
	 - Pequenos patches de correção de declarações (por exemplo, declarações faltantes em `src/luascript.h`) e correções de sintaxe em scripts Lua foram aplicadas para evitar erros de build/parse.

## Como adicionar ou alterar uma Nature

1. Adicione/edite uma entrada em `src/const.h` na enum `Natures_t` (mantendo o valor numérico consistente se necessário para persistência).
2. Registre a constante em `src/luascript.cpp` com `registerEnum(NATURE_YOURNAME)` para exposição em scripts.
3. Em `src/data/lib/core/newfunctions.lua` adicione/atualize `natureBoost[NATURE_YOURNAME] = "statName"` e `natureReduce[NATURE_YOURNAME] = "otherStatName"`. Use as strings: `"attack"`, `"magicAttack"`, `"defense"`, `"magicDefense"`, `"speed"`.
4. (Opcional) Atualize a documentação (`src/docs/NATURES_SYSTEM.MD`) com a nova natureza e suas implicações.
5. Compile, carregue o mundo e teste uma captura/liberação e `onLook` para verificar os efeitos numericamente e a anotação no cliente.

## Persistência e atributos relevantes

- `pokeNature` (item special attribute): armazenado na pokéball quando o summon é removido/recolhido; restaurado ao liberar a summon.
- `corpseNature` (corpse special attribute): usado para log/debug de corpses (quando aplicável).
- `setNatureAndLock` (C++): método usado quando um valor de nature foi definido no momento da criação para evitar sobrescrita.

## Testes sugeridos

1. Capturar um monstro normal, inspecionar a pokéball: verifique `pokeNature` gravado (pode usar logs/prints).  
2. Liberar a summon com `doReleaseSummon`: verificar que a summon tem a mesma nature e que as estatísticas exibidas via `onLook` mostram "+10%" / "-10%" conforme a tabela de natures.  
3. Testar natures neutras (ex.: Hardy, Bashful) e confirmar que as estatísticas não mudam.  
4. Testar criaturas geradas por `Game.createMonster(..., initNature)` para confirmar que `setNatureAndLock` mantém a value fornecida.

## Changelog (resumo das ações aplicadas)

- Criado/estendido enum `Natures_t` e registradas constantes em Lua.  
- Extenso suporte em C++ para transportar um parâmetro `initNature` na criação de monsters e lock de natureza.  
- Adicionados métodos Lua `Creature:getNature()` e `Creature:setNature()` expostos e implementados para usar lock quando apropriado.  
- Persistência em pokéballs (`pokeNature`) e corpses (`corpseNature`) adicionada.  
- Mapeamentos `natureBoost` / `natureReduce` implementados em `newfunctions.lua` e a função `applyNatureModifier` aplicada nas funções de cálculo de status.  
- `Player:onLook` e scripts relacionados atualizados para exibir a Nature e anotações (+10% / -10%).

---

Se quiser, eu posso:

- Incluir exemplos de XML de monstros com `<nature>` / `<naturerandom>` para referência.  
- Executar um build rápido e um conjunto de scripts de teste que gerem descrições `onLook` para um conjunto de natures (ex.: Adamant, Modest, Jolly) e postar o resultado aqui.

Data da documentação: 15/11/2025



COMPORTAMENTOS NATURES
✅ 25 Natures → 25 Comportamentos de Criaturas
Legenda rápida

Hostile 1 / Passive 0 → Agressivo

Hostile 1 / Passive 1 → Defensivo (só revida / recua com low HP)

Hostile 0 / Passive 1 → Amedrontado / pacífico

Hostile 0 / Passive 0 → Amistoso (segue o player mas não ataca)

runonhealth: porcentagem em que foge

staticattack: quão agitada é a IA (baixo = agitado; alto = parado)

targetdistance: distância ideal do alvo

⭐ 1. Hardy (Neutro)

Criatura padrão, equilíbrio total.
hostile=1 passive=1 runonhealth=20% staticattack=3000 targetdistance=1

⭐ 2. Lonely (Ataque↑ Defesa↓)

Bate forte mas tem medo de se machucar.
hostile=1 passive=1 runonhealth=40% staticattack=2000 targetdistance=1

⭐ 3. Brave (Ataque↑ Velocidade↓)

Agressiva mas lenta e decidida.
hostile=1 passive=0 runonhealth=0 staticattack=50000 targetdistance=1

⭐ 4. Adamant (Ataque↑ Atq. Esp↓)

Agressor corpo-a-corpo puro.
hostile=1 passive=0 runonhealth=0 staticattack=1500 targetdistance=1

⭐ 5. Naughty (Ataque↑ Def. Esp↓)

Agressivo caótico, não pensa em recuar.
hostile=1 passive=0 runonhealth=0 staticattack=800 targetdistance=2

⭐ 6. Bold (Defesa↑ Ataque↓)

Tank que evita atacar até ser provocado.
hostile=1 passive=1 runonhealth=30% staticattack=7000 targetdistance=1

⭐ 7. Docile (Neutro)

Parecido com Hardy, mas menos agressivo.
hostile=1 passive=1 runonhealth=25% staticattack=4000

⭐ 8. Relaxed (Defesa↑ Velocidade↓)

Lento e resistente, recua tarde.
hostile=1 passive=1 runonhealth=15% staticattack=25000

⭐ 9. Impish (Defesa↑ Atq. Esp↓)

Defensor brincalhão — provoca mas não mata.
hostile=1 passive=1 runonhealth=35% staticattack=3000

⭐ 10. Lax (Defesa↑ Def. Esp↓)

Briga mas foge cedo por ser descuidado.
hostile=1 passive=1 runonhealth=50% staticattack=3500

⭐ 11. Modest (Atq. Esp↑ Ataque↓)

Mage que ataca de longe e evita contato.
hostile=1 passive=1 targetdistance=5 runonhealth=30% staticattack=2500

⭐ 12. Mild (Atq. Esp↑ Defesa↓)

Glass cannon emocional: bate forte e foge rápido.
hostile=1 passive=1 runonhealth=60% targetdistance=4

⭐ 13. Quiet (Atq. Esp↑ Velocidade↓)

Canhão mágico parado.
hostile=1 passive=0 runonhealth=0 staticattack=45000 targetdistance=5

⭐ 14. Rash (Atq. Esp↑ Def. Esp↓)

Agressivo mágico imprudente.
hostile=1 passive=0 runonhealth=5% staticattack=1200

⭐ 15. Calm (Def. Esp↑ Ataque↓)

Criatura pacífica que só revida.
hostile=1 passive=1 runonhealth=40% staticattack=6000

⭐ 16. Gentle (Def. Esp↑ Defesa↓)

Fácil de assustar, recua muito cedo.
hostile=0 passive=1 runonhealth=80% staticattack=9000

⭐ 17. Sassy (Def. Esp↑ Velocidade↓)

Lento, resistente, e provoca o jogador.
hostile=1 passive=1 runonhealth=20% staticattack=8000

⭐ 18. Careful (Def. Esp↑ Atq. Esp↓)

Evita perigo e tenta sempre recuar.
hostile=1 passive=1 runonhealth=50% staticattack=12000

⭐ 19. Jolly (Velocidade↑ Ataque↓)

Criatura hiperativa que corre ao redor do jogador.
hostile=0 passive=0 staticattack=500 targetdistance=2

⭐ 20. Hasty (Velocidade↑ Defesa↓)

Ataca e recua freneticamente (hit and run).
hostile=1 passive=1 runonhealth=50% staticattack=200

⭐ 21. Timid (Velocidade↑ Ataque↓)

Foge de tudo, quase impossível de prender.
hostile=0 passive=1 runonhealth=100% staticattack=1000

⭐ 22. Naive (Velocidade↑ Def. Esp↓)

Corre muito mas toma decisões ruins.
hostile=1 passive=1 runonhealth=35% staticattack=900

⭐ 23. Serious (Neutro)

Comportamento consistente e previsível.
hostile=1 passive=1 runonhealth=20% staticattack=3000

⭐ 24. Bashful (Neutro tímido)

Evita conflito até ser realmente atacado.
hostile=1 passive=1 runonhealth=40% staticattack=4000

⭐ 25. Quirky (Neutro imprevisível)

Se comporta aleatoriamente entre agressivo/defensivo/amedrontado.
hostile=1 passive=0/1 alternando
runonhealth variável (0–60%)
staticattack variável (500–8000)

Ideal para criaturas “caóticas”.