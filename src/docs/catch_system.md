# Sistema de Captura Reformulado

Este documento descreve as mudanças e melhorias implementadas no sistema de captura (`catch.lua`) para tornar a experiência mais estratégica, imersiva e fiel às mecânicas clássicas.

## 1. Nova Fórmula de Chance de Captura

A chance de captura não é mais apenas um valor fixo baseado na Pokebola. Agora, diversos fatores influenciam o sucesso:

`Chance Final = (TaxaBase * MultiplicadorBola) * (Fator HP) * (Bônus Status) * (Bônus Mood) * (Bônus Vocação)`

### 1.1 Fator HP (Vida)
Quanto menos vida o monstro tiver, maior será a chance de captura.
- **Fórmula:** `(3 * MaxHP - 2 * CurrentHP) / (3 * MaxHP)`
- **Impacto:**
    - **100% HP:** Chance reduzida para **33%** do original.
    - **HP Baixo (Vermelho):** Chance próxima de **100%** do original (triplicando a chance em relação ao HP cheio).

### 1.2 Bônus de Status (Conditions)
Monstros afligidos por condições negativas são mais fáceis de capturar.
- **Multiplicador:** **x1.5**
- **Condições Válidas:** Queimado (Burn), Envenenado (Poison), Paralisado (Paralyze), Eletrificado (Energy) e Afogando (Drown).

### 1.3 Bônus de Mood (Humor/Estado Wild)
Integração com o sistema de `WildMoods`.
- **Dormindo (Sleeping):** **x4.0** de chance.
- **Comendo (Eating):** **x2.5** de chance.
- **Distraído (Caution):** **x2.0** de chance.

---

## 2. Sistema de Som Avançado

A captura agora conta com feedback auditivo em três etapas distintas, enviadas via Extended Opcode 85:

1.  **Lançamento (`catch_throw.mp3`)**: Toca no momento exato em que a bola sai da mão do jogador.
2.  **Impacto/Balanço (`catch_shake.mp3`)**: Toca quando a bola atinge o monstro e começa a balançar.
3.  **Resultado**: 
    - **Sucesso (`catch_success.mp3`)**: Toca após o balanço final se o monstro for capturado.
    - **Falha (`catch_fail.mp3`)**: Toca se o monstro escapar da bola.

---

## 3. Melhorias Visuais e Sincronização

- **Ocultação Inteligente:** O monstro é ocultado (`invisible outfit`) e sua barra de vida é escondida durante o balanço da bola para simular que ele está dentro dela.
- **Sincronização de Delays:** Os tempos de animação e sons foram ajustados para serem mais ágeis, reduzindo o tempo de espera total da captura sem perder a tensão do balanço.
- **Feedback de Texto:** Mensagens no console informam o jogador quando bônus de Mood (como dormir ou comer) estão ativos.

---

## Como Configurar Novos Sons
Para alterar os sons, basta substituir os arquivos `.mp3` na pasta `mods/Advanced Sound/Sounds/` do client ou alterar os nomes das strings na função `doPlayerSendSound` dentro do arquivo `catch.lua`.
