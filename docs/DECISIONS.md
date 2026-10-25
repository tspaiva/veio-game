# Registro de decisões

Decisões tomadas a partir da análise do [GDD](GDD.md). O GDD é mantido sincronizado com estas decisões. Toda decisão nova entra aqui com um ID e é refletida no GDD na mesma mudança. Se algo divergir, este documento prevalece.

Formato: cada decisão tem um ID estável (`D<n>`) para ser citada em código, issues e PRs.

---

## D1 — Reatividade dos programas: ações duradouras + blocos `QUANDO`

- Ações como `ir até`, `minerar` e `voltar à base` **duram vários ticks** e bloqueiam a sequência até terminar.
- A reatividade vem de **blocos de evento `QUANDO <condição>`**, avaliados no início de todo tick. Se um dispara, a ação atual é **cancelada**, o corpo do handler executa e, ao terminar, o **loop principal reinicia** do começo.
- O interpretador usa **pilha de frames** e suporta cancelamento desde o início (M2), mesmo que o editor só exponha o `QUANDO` depois.
- Interrupções e prioridades entre handlers são um conceito de progressão (GDD 9.3).

## D2 — Movimento

- **Drones voam.** Pathfinding com `AStarGrid2D` sobre tiles vazios, atualizado quando o terreno muda.
- **O jogador tem gravidade.** A mobilidade vertical progride assim:
  1. **Escadas**: fabricadas com ferro e posicionadas como tiles. Entram no protótipo.
  2. **Elevador**: construído pelo jogador (poço e cabine). É um ponto de infraestrutura que as criaturas podem atacar.
  3. **Jetpack**: equipamento tardio.
- Consequência intencional: descer fundo exige infraestrutura construída pelo jogador, o que reforça a vanguarda (GDD 6.3).

## D3 — Mapa sempre gerado proceduralmente

- Todo mapa vem de uma **seed**. Não existem mapas desenhados à mão.
- O gerador fica isolado (`world/mine/mine_generator.gd`) para evoluir para um modo roguelike no futuro.

## D4 — Idioma

- Código, identificadores e comentários em **inglês**.
- Documentação de design em **português**.
- Textos do jogo: a definir quando houver localização. Por enquanto, em português.

## D5 — Bloco sem a peça correspondente: falha em execução

- A rotina pode conter blocos de peças que o drone não tem. O editor mostra um aviso, mas não impede.
- Em execução, o bloco **falha** e registra no log do drone (ex.: `"sem broca instalada"`).

## D6 — Rotinas compartilhadas

- Uma rotina é compartilhada por **referência** entre os drones que a usam.
- Editar a rotina **reinicia o programa** de todos os drones que a usam.
- Cópias independentes surgem só via "rotinas extras" (D9).

## D7 — Neblina (fog of war)

- Os tiles começam **ocultos**. São revelados pelo **jogador** e pelo **Batedor**, dentro do raio dos seus sensores.
- O **scanner de minério** dos outros drones **só enxerga tiles já revelados**.
- Só o Batedor tem o bloco `explorar`.
- Isso cria dependência entre as classes: sem Batedor, os Mineradores ficam limitados ao que o jogador explorou.

## D8 — Onboarding: primeiro drone com rotina defeituosa

- O primeiro Minerador já vem com uma rotina pronta que funciona, mas tem um defeito visível (ex.: não volta à base com bateria baixa).
- O jogador aprende a editar consertando. Não há tutorial explícito.

## D9 — Três classes de drone, uma rotina por classe

- Classes: **Batedor**, **Minerador** e **Defensor**. Cada classe é um **chassi** que define as categorias de peça que aceita.
- **A classe é fixa**: um drone fabricado como Minerador sempre é Minerador.
- **Uma rotina por classe**: todos os drones da classe executam a mesma rotina (espelhada). No início, o jogador cuida de 3 rotinas.
- **Parâmetros por drone**: a rotina declara parâmetros (ex.: `minério alvo`, `meu posto`) e cada drone tem os próprios valores. A mesma rotina gera comportamentos diferentes.
- **Rotinas extras por classe** são uma tecnologia futura liberada pela corporação.
- **Suporte** (consertar, construir) fica como **4ª classe futura**, fora do protótipo.

| Classe | Categorias de slot (proposta) | Blocos exclusivos |
|---|---|---|
| Batedor | sensores, antena, memória, energia | `explorar` |
| Minerador | ferramenta, carga, scanner, energia | `cavar`, `minerar`, `descarregar` |
| Defensor | armas, sensor de ameaça, antena, energia, blindagem | `mirar`, `atirar` |

O loadout dentro da classe é livre (ex.: broca silenciosa ou de diamante). A mesma rotina roda em loadouts diferentes, graças à D5.

## D10 — O Batedor entra no protótipo

Com a neblina (D7), ele faz parte do loop central. Atualiza o escopo da seção 13 do GDD (ver [PLAN.md](PLAN.md)).

## D11 — Simulação

- **Tick fixo de lógica a 10 Hz**, separado da renderização (o visual interpola).
- **Controles de velocidade**: pausa, 1×, 2×, 4×, e avanço passo a passo no debug.
- **Orçamento de instruções**: no máximo 32 passos instantâneos (controle e condições) por drone por tick. Se estourar, o drone fica `IDLE` e registra no log.

## D12 — Tecnologia

- **Godot 4.7.2-stable**, GDScript, renderer **Compatibility** (2D, maior compatibilidade em PC).
- **Testes**: runner próprio e mínimo em `tests/` (sem dependências), executado em modo headless.
- A lógica dos programas (`core/`) **não depende de nós da cena**, para poder ser testada headless.

## D13 — Build web para testes

- O jogo continua sendo **para PC**. O celular serve **só para testes**.
- O CI gera um **build web** (export HTML5, single-threaded, sem exigir headers COOP/COEP) e publica no **GitHub Pages**. Ele roda no navegador do PC e do celular, sem instalar nada.
- Controles de toque (arrastar e pinçar na câmera, movimento básico) entram só como apoio aos testes. A interface continua pensada para mouse e teclado.
- Entra no M1. O repositório é **público**, para o Pages funcionar no plano gratuito. O CI sempre gera o build e publica no Pages a partir da branch padrão quando o Pages está ativado (Settings → Pages → Source: **GitHub Actions**). Sem o Pages ativo, a publicação é pulada.
- O link de um mapa específico usa `?seed=<n>` na URL.
