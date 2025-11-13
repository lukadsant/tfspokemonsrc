# Gender System — documentação de implementação

Última atualização: 11/11/2025

Este documento descreve, passo a passo, como foi implementado o sistema de "gender" (sexo) no servidor. O objetivo é fornecer um guia completo e reutilizável para implementar sistemas semelhantes no futuro (por exemplo, um sistema de "nature"/personalidade), preservando consistência, evitando condições de corrida e mantendo boa instrumentação para depuração.

Índice
- Visão geral
- Objetivos de design
- Fluxo de dados (end-to-end)
- Mudanças principais (arquivos e função)
- Contrato público / API (inputs, outputs, efeitos colaterais)
- Locking / concorrência e instrumentação
- Como estender (ex.: Nature System)
- Testes e procedimento de validação
- Checklist de implantação

---

## Visão geral

O `Gender System` fornece:

- Definição de sexo a partir do tipo de monstro (XML) com suporte a opções ponderadas (ratio/weights).
- Persistência do sexo quando um monstro é capturado em um item (pokéball) através de atributos especiais do item (`pokeSkull`).
- Restauração confiável do sexo ao evocar um summon (release), evitando que o construtor do `Monster` faça randomização que sobrescreva o valor pretendido.
- Exibição do sexo no `look` (descrição) do summon e do item.

Para resolver races e sobrescritas, adicionamos:

- um parâmetro opcional para `Monster::createMonster(...)` que aceita um valor de skull;
- lógica no construtor do `Monster` que prioriza `MonsterType` (XML) > `initSkull` (script) > randomização (quando aplicável);
- mecanismo de lock (`skullLocked`) e API atômica `setSkullAndLock` (permitindo scripts travarem o valor);
- instrumentação para imprimir um backtrace quando uma tentativa de sobrescrita é impedida.

---

## Objetivos de design

- Preservar compatibilidade com código existente (defaults e sobrecargas mantidas).
- Aplicar valor de sexo o mais cedo possível (durante construção) para eliminar janela de corrida com randomização.
- Conservar proteção para chamadas que tentem sobrescrever valores críticos aplicados por scripts.
- Garantir fácil extensão para sistemas semelhantes (nature, brilho, tags), com mínimo de alterações espalhadas.

---

## Fluxo de dados (end-to-end)

1. Corpse -> pokéball
	 - O script de morte/corpse grava o skull do monstro no `corpse` (ex.: `corpse:setSpecialAttribute("corpseSkull", skull)`).
	 - Quando o jogador captura, o script de captura (`doAddPokeball`) lê `corpseSkull` e grava `pokeSkull` no item da pokéball: `ball:setSpecialAttribute("pokeSkull", corpseSkull)`.

2. Pokéball -> Summon (release)
	 - Ao liberar (`doReleaseSummon`), o script lê `storedSkull = ball:getSpecialAttribute("pokeSkull")`.
	 - Se `storedSkull` existe, a chamada para criar o monstro passa esse valor: `Game.createMonster(name, pos, extended, force, level, boost, storedSkull)`.
	 - O construtor do `Monster` recebe `initSkull` e aplica antes de qualquer randomização.
	 - Como proteção adicional, agendamos `addEvent(doSetMonsterSkullByMaster, 50, player:getId(), storedSkull)` para re-aplicar via lista de summons do master (safety-net).

3. Recall / RemoveSummon
	 - Ao remover o summon (`doRemoveSummon`), o script persiste de volta o skull atual do summon para o item: `ball:setSpecialAttribute("pokeSkull", summon:getSkull())`.

4. Look / Descrição
	 - Ao olhar o summon ou a pokéball, os scripts de `onLook` leem `pokeSkull` e exibem texto humano (ex.: `Sex: Male`).

---

## Mudanças principais (arquivos e trechos relevantes)

Lista de arquivos alterados (resumo):

- C++
	- `src/monster.h`
		- Assinatura atualizada com argumentos opcionais:
			- `static Monster* createMonster(const std::string& name, uint16_t lvl = 0, uint16_t bst = 0, Skulls_t skull = SKULL_NONE);`
			- `explicit Monster(MonsterType* mtype, uint16_t lvl = 0, uint16_t bst = 0, Skulls_t initSkull = SKULL_NONE);`

	- `src/monster.cpp`
		- `Monster::createMonster(...)` agora encaminha o `skull` opcional para o construtor.
		- `Monster::Monster(..., initSkull)` aplica a precedência de definição de skull:
			1. `mType->info.skull` (XML)
			2. `initSkull` (passado por script)
			3. randomização (se não é summon)
			4. `SKULL_NONE` (summons sem skull)

	- `src/creature.cpp`
		- `Creature::setSkull(Skulls_t newSkull)`:
			- Mantém `skullLocked` check: se bloqueado e uma chamada tenta alterar → imprime "prevented overwrite" e backtrace (diagnóstico).
			- Removido log ruidoso de cada alteração normal para reduzir spam.
		- `Creature::setSkullAndLock(Skulls_t newSkull)` (API atômica) foi usada pela binding Lua (aplica + bloqueia).

	- `src/luascript.cpp`
		- `luaGameCreateMonster` agora lê o 7º parâmetro opcional (skull) e passa para `Monster::createMonster`.

- Lua (scripts)
	- `src/data/lib/core/newfunctions.lua`
		- `doReleaseSummon`: pega `storedSkull` e passa como 7º argumento a `Game.createMonster(...)` (quando presente). Mantém `addEvent(doSetMonsterSkullByMaster, 50, ...)` como fallback.
		- `doSetMonsterSkullByMaster` / `doSetMonsterSkull`: helpers para re-aplicar skull.

	- `src/data/actions/scripts/poke/catch.lua` (ou arquivo de captura equivalente)
		- `doAddPokeball` grava `pokeSkull` no item e atualiza `description` para mostrar o sexo em texto legível.

	- `src/data/events/scripts/player.lua`
		- Em `Player:onLook`, adicionado extrair `pokeSkull` do `master:getUsingBall()` e inserir `Sex: <valor>` na descrição do summon; também mostra sexo na descrição do item pokéball.

---

## Contrato público / API

- Monster::createMonster
	- Assinatura: `Monster* createMonster(const std::string& name, uint16_t lvl = 0, uint16_t bst = 0, Skulls_t skull = SKULL_NONE)`
	- Entrada: nome do monstro, level, boost, skull opcional.
	- Efeito: cria objeto `Monster` que já terá seu `skull` definido segundo a precedência descrita.
	- Compatibilidade: chamadas sem o 7º parâmetro permanecem funcionando.

- luaGameCreateMonster (binding)
	- Agora aceita um 7º argumento numérico (Skulls_t) passado de Lua para C++.

- Item special attributes
	- `pokeSkull` — inteiro que representa o skull/sex a ser persistido.
	- Outras chaves: `pokeName`, `pokeLevel`, `pokeBoost`, `pokeHealth`, `pokeLove`, etc. (já existentes no sistema).

---

## Locking / concorrência e instrumentação

- `skullLocked` (bool em `Creature`)
	- Quando `true`, impede que chamadas subsequentes a `setSkull` sobrescrevam o valor atual.
	- Scripts que desejam aplicar e travar um valor devem usar `setSkullAndLock` (já implementado) ou chamar a binding que mapeia para essa função.

- Instrumentação de diagnóstico
	- Quando uma tentativa de sobrescrita é bloqueada (`skullLocked` == true e `newSkull != skull`), imprimimos uma mensagem e um backtrace nativo (funções `backtrace` / `backtrace_symbols`) para identificar o caller.
	- Removemos logs para cada mudança normal para evitar gerar ruído no servidor (essas linhas apareciam em massa: "[Creature::setSkull] creature id=0 ...").
	- Em caso de regressão, reativar prints adicionais por curto período para depuração é uma opção.

---

## Como estender: implementar um `Nature System` (passos práticos)

O `Nature System` terá um fluxo quase idêntico ao `Gender System`:

1. Defina o atributo/representação em `MonsterType::info` (XML) — se aplicável.
2. No momento da captura, armazene o valor no item, ex.: `pokeNature` (item special attribute).
3. Atualize `Game.createMonster` binding para aceitar mais um parâmetro opcional (p.ex.: `Nature_t nature = NATURE_NONE`) — **mesma estratégia do skull**.
4. Atualize `Monster` constructor com um novo parâmetro `initNature` (default `NATURE_NONE`) e aplique a precedência:
	 - `mType->info.nature` (XML) > `initNature` (script) > randomização (se aplicável) > padrão
5. Se o atributo não pode ser sobrescrito depois, reutilize o padrão `lock` (p.ex.: `natureLocked`) e uma API `setNatureAndLock` (aplicar + bloquear).
6. Atualize os scripts `doReleaseSummon` / `doRemoveSummon` para persistir e restaurar `pokeNature` junto com `pokeSkull`.
7. Atualize `Player:onLook` para mostrar Nature/Personalidade no look do summon/item.

Recomendações:
- Use o mesmo mecanismo de passagem de argumento (7º/8º parâmetro) para mantê-lo consistente.
- Sempre aplique o valor no construtor para evitar randomização que sobrescreva.
- Adicione instrumentação de prevenção (backtrace) se o atributo deve ser imutável depois de aplicado.

---

## Testes e procedimento de validação

1. Compilar:
```bash
cd /home/lukadsant/Downloads/pokedashpota1.0_release/pokedashpota1.0_src/pokedashpota1.0_serversrc/src
make -j$(nproc)
```

2. Teste manual (fluxo happy-path):
- Capture um monstro cujo skull seja conhecido.
- Verifique o item (`pokeSkull` e `description`).
- Release o summon e verifique o `look` do summon: deve conter `Sex: <valor>`.
- Remova o summon e verifique se `pokeSkull` foi persistido de volta ao item.

3. Teste de stress (race):
- Em um ambiente controlado, simule criação simultânea (scripts/NPCs) ou automações que chamam `createMonster`/`setSkull` repetidamente.
- Se houver sobrescrita indevida, o log de "prevented overwrite" deverá imprimir backtraces para localizar o caller.

4. Validação pós-implantação:
- Monitorar logs por 24–72 horas para confirmar ausência de ruído e que summons mantêm o sexo corretamente.

---

## Checklist de implantação

- [ ] Compilar servidor com as mudanças C++.
- [ ] Implantar scripts Lua atualizados.
- [ ] Reproduzir casos de captura/release/recall para confirmar persistência.
- [ ] Monitorar logs por mensagens de "prevented overwrite" (apenas se ocorrerem).

---

## Observações finais

O design favorece aplicar valores de atributos (sexo, natureza, etc.) o mais cedo possível (no construtor), usar atributos especiais de itens para persistência e proteger valores importantes usando locks atômicos. Esse padrão é sólido e repetível para outros atributos.

Se desejar, eu posso:

- Gerar um `PR` com um scaffold pronto para o `Nature System` seguindo exatamente este padrão (codificando bindings, construtor e scripts de exemplo). 
- Rodar a compilação local e anexar o `make` output aqui.
- Adicionar testes automatizados simples (script Lua que simula captura/release em loop para validar races).

Escolha o próximo passo que prefere e eu continuo. 

