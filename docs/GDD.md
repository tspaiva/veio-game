# Documento de Design — Jogo de Mineração com Drones Programáveis

> Nome provisório: **Veio**
> Plataforma: **PC** (Windows, Linux, Mac). **Build web** para testes, inclusive no celular (D13)
> Engine: **Godot 4.7.2-stable**
> Status: **pré-protótipo**. M0 (fundação) concluído
> Versão do documento: **2**. Decisões registradas em [DECISIONS.md](DECISIONS.md); plano em [PLAN.md](PLAN.md)

Este documento é mantido atualizado. As referências `(Dn)` apontam para a decisão correspondente em [DECISIONS.md](DECISIONS.md).

---

## 1. Visão geral

Jogo 2D de mineração e automação em visão de corte lateral. O jogador é um técnico enviado por uma corporação para extrair um cristal raro de um planeta onde **ninguém esteve antes**. Ele começa minerando à mão, mas a mina é profunda demais para uma pessoa só: o jogo gira em torno de **montar e programar drones** (com blocos visuais) para minerar, transportar e defender a operação.

Há **três classes de drone**: **Batedor**, **Minerador** e **Defensor**. Cada classe tem **uma rotina** compartilhada por todos os drones dela. No início, o jogador cuida de apenas três programas (D9).

Os drones são construídos com **minérios comuns** extraídos no próprio planeta. O **cristal valioso** é enviado à corporação, que em troca libera novas tecnologias.

O subsolo é o lar de criaturas que reagem à extração. Elas atacam a base e os drones. O jogador programa **drones de defesa** e também atua em campo com seu próprio equipamento. O desafio central é **manter todo o sistema funcionando**: minerando, defendendo e se expandindo.

### Pilares

1. **Programar é jogar**: o prazer vem de ver um sistema criado pelo jogador rodando sozinho.
2. **Errar é divertido**: drones fazem coisas erradas de forma visível e engraçada; depurar faz parte da diversão.
3. **O jogo não ensina, o jogador descobre**: sem tutorial explícito; o ambiente e os desafios guiam.
4. **Toda ação tem custo**: minerar mais gera mais reação das criaturas.
5. **Desafio, não pressão**: o foco é equilíbrio e estratégia, não reflexo nem timer apertado.
6. **O minerador nunca fica inútil**: o jogador continua relevante em campo do início ao fim.

---

## 2. Premissa e lore (a refinar)

> ⚠️ Esta seção é uma base. A lore será refinada depois.

- O jogador é o **primeiro ser humano** a pisar no planeta. Não há mineradores anteriores nem ruínas humanas.
- O cristal valioso não é um minério comum: é parte de um **organismo cristalino vivo**, uma rede que se espalha pelo subsolo como raízes, chamado **o Veio**.
- As **criaturas nascem do Veio**, crescendo a partir dos cristais. Funcionam como o sistema imune dele.
- **Por que atacam:** extrair o cristal é arrancar pedaços de um corpo vivo. As criaturas defendem seu lar.
- **Por que nunca são extintas:** enquanto o Veio existir, ele gera novas criaturas. Matar uma só gasta energia do Veio.
- **Por que ficam mais fortes nas camadas profundas:** mais perto do **coração do Veio**, mais energia para gerar criaturas complexas.
- **Por que o cristal é valioso:** é energia viva. A corporação sabe disso e esconde do jogador.
- **Final (ideia):** no fundo da mina está o coração do Veio. O jogador decide o que fazer com ele. Caminhos de final ainda em aberto.

---

## 3. Loop principal

1. **Explorar à mão**: o jogador desce, revela a neblina e descobre minérios, perigos e criaturas novas.
2. **Entender o problema**: "o cobre está atrás de rocha dura e perto de uma toca".
3. **Montar o drone**: escolher a classe, fabricar peças com minérios comuns e definir o loadout para a tarefa.
4. **Programar**: montar a rotina da classe com blocos e ajustar os parâmetros de cada drone.
5. **Assistir e depurar**: observar, encontrar falhas, ajustar.
6. **Escalar**: replicar drones; Batedores ampliam a área revelada; a produção automática alimenta a fabricação.
7. **Enviar cristal**: o cristal coletado vai para a corporação, que libera novas tecnologias.
8. **Defender**: lidar com a reação das criaturas, com Defensores e com o próprio equipamento.

---

## 4. A mina

- Visão em **corte lateral 2D**, com terreno escavável baseado em tiles.
- **Sempre gerada proceduralmente** a partir de uma **seed**. Não há mapas desenhados à mão. O gerador é isolado para permitir um modo **roguelike** no futuro (D3).
- Dividida em **camadas** de profundidade. Cada camada tem minérios, tipos de rocha, perigos e criaturas próprios.
- Terreno escavado fica aberto (túneis persistentes), formando rotas que drones usam.
- **Neblina (fog of war):** os tiles começam ocultos e são revelados pelo jogador e pelo Batedor, dentro do raio dos seus sensores (D7).
- Tipos de tile (exemplos): terra, rocha, rocha dura, **minérios comuns** (ferro, cobre, silício…), **cristal do Veio**, toca de criaturas, água, lava/gás (camadas avançadas), **escada** (construída pelo jogador).
- **Rocha de fronteira** separa as camadas (ver seção 6.3).
- Câmera com zoom (rodinha do mouse) e arraste, permitindo alternar entre visão geral e detalhe.

---

## 5. Minérios e economia

### 5.1 Minérios comuns: para construir

Usados na **fabricação** de drones, peças, estruturas e equipamento do jogador. Novos minérios aparecem em camadas mais profundas, liberando peças melhores.

| Minério (proposta) | Camada | Uso principal |
|---|---|---|
| Ferro | 1 | chassis, estruturas, barreiras, escadas |
| Cobre | 1 | fiação, baterias, antenas |
| Silício | 2 | sensores, chips de memória |
| Titânio | 3 | blindagem, brocas melhores |
| Outros a definir | 4+ | peças avançadas |

### 5.2 Cristal do Veio: para a corporação

- Não é usado na fabricação. É **enviado à corporação** por um ponto de envio na base.
- Em troca, a corporação concede **créditos / reputação** que liberam:
  - novas **plantas de peças** (que destravam novos blocos de programação)
  - melhorias da base (energia, capacidade de fabricação)
  - equipamento novo para o jogador
  - **rotinas extras por classe** (D9) e, no futuro, a classe **Suporte**
- Metas de envio funcionam como **marcos**, não punições: atingir a meta libera tecnologia; não há penalidade por atraso (desafio, não pressão).
- O cristal é o que mais provoca as criaturas: extrair cristal aumenta muito a perturbação da região.

### 5.3 Fragmentos de cristal: para upgrades

- Deixados por **criaturas mortas**. Como são pedaços pequenos, a corporação não tem interesse neles.
- São usados para **upgrades em drones** (e no equipamento do jogador). Um drone que recebe fragmentos ganha bônus, por exemplo:
  - mais velocidade
  - bateria maior
  - mais dano
  - mais resistência
  - broca mais rápida
- Cria um ciclo: defender bem gera fragmentos, que fortalecem os drones.

### 5.4 Fluxo resumido

```
Minérios comuns  → fabricação (drones, peças, estruturas, equipamento)
Cristal do Veio  → corporação → créditos → novas plantas e tecnologias
Fragmentos       → upgrades em drones e no equipamento do jogador
Sucata           → reciclada em parte dos minérios usados no drone
```

---

## 6. O minerador (jogador)

O jogador é o **técnico de campo** da operação. Ele não substitui os drones, mas faz coisas que eles não fazem, e tem papel em todas as fases do jogo.

O jogador **tem gravidade**; os drones voam (D2). Descer fundo exige infraestrutura que só o jogador constrói.

### 6.1 Equipamento

- **Ferramenta de escavação**: minera à mão; melhorável (mais rápida, fura rocha dura).
- **Arma pessoal**: para defesa em emergências; melhorável e com variações (tiro único, área, atordoar).
- **Ferramenta de reparo**: conserta drones e estruturas em campo, inclusive **drones abatidos antes de virarem sucata** (ver seção 8.2).
- **Construção em campo**: posicionar **escadas**, **barreiras** e **sinalizadores** (pontos que os drones podem usar como alvo, ex.: "ir até sinalizador A").
- **Mobilidade vertical**, em progressão (D2):
  1. **Escadas**: fabricadas com ferro e posicionadas como tiles. Lentas, mas disponíveis desde o início.
  2. **Elevador**: poço com cabine construído pelo jogador. Vira a "espinha" da mina e um ponto que as criaturas podem atacar.
  3. **Jetpack**: equipamento tardio, para mobilidade livre.
- **Cargas de explosivo**: abrir a rocha de fronteira entre camadas.
- **Revelar a neblina**: o jogador revela os tiles ao redor de si (D7).

O equipamento é fabricado com minérios comuns, liberado pela corporação e melhorado com fragmentos.

### 6.2 Integração com os drones

O jogador participa da programação como um elemento do mundo:

- Blocos como **"ir até o minerador"**, **"seguir o minerador"**, **"minerador em perigo?"**
- O jogador pode **enviar sinais manualmente** (atalho de teclado), que os drones ouvem como qualquer outro sinal. Ex.: chamar defensores, ordenar recuo.
- Sinalizadores colocados pelo jogador servem de referência para rotas e postos.

### 6.3 Vanguarda

- Só o jogador abre **novas camadas**: a rocha de fronteira exige explosivos posicionados por ele.
- Explorar uma camada nova é sempre feito pessoalmente primeiro, e é o momento de maior risco.
- Como o jogador tem gravidade, a vanguarda também exige levar a infraestrutura de subida (escadas, elevador) até a camada nova.

### 6.4 Morte do jogador

- O jogador reaparece na base. Perde a carga que levava. Drones continuam executando seus programas.

---

## 7. Drones

Todos os drones **voam**: navegam pelos túneis abertos sem gravidade (D2).

### 7.1 Classes e hardware

Há **três classes**. Cada classe é um **chassi** com slots limitados, que define as **categorias de peça** aceitas. **A classe é fixa**: um drone fabricado como Minerador sempre é Minerador (D9).

| Classe | Função | Categorias de slot (proposta) | Blocos exclusivos |
|---|---|---|---|
| **Batedor** | explora, revela a neblina, amplia o que os outros enxergam | sensores, antena, memória, energia | `explorar` |
| **Minerador** | produz minérios comuns e cristal | ferramenta, carga, scanner, energia | `cavar`, `minerar`, `descarregar` |
| **Defensor** | patrulha, guarda, responde a sinais, protege o jogador | armas, sensor de ameaça, antena, energia, blindagem | `mirar`, `atirar` |

- **Suporte** (construir barreiras, consertar, acalmar áreas) fica como **4ª classe futura**, liberada pela corporação.
- Dentro da classe, o **loadout é livre** (ex.: broca silenciosa ou de diamante, carga pequena ou grande).

Categorias de peças:

- **Ferramenta:** broca básica, broca silenciosa, broca de diamante, laser, explosivo
- **Sensores:** scanner de minério, sensor de ameaça, câmera (ver outros drones)
- **Carga:** compartimento pequeno, compartimento grande
- **Energia:** bateria (limita autonomia, força retorno à base)
- **Armas:** torreta, laser, atordoador, defesa em área
- **Blindagem:** resistência a dano
- **Comunicação:** antena (sinais entre drones)
- **Memória:** chip de memória (guardar posições e valores)
- **Suporte (futuro):** braço construtor (barreiras, consertos), emissor sônico (repelir criaturas, mascarar barulho)

A **bateria** é central: cria o ritmo de ir e voltar e transforma rota e eficiência em problema real.

### 7.2 Software: programação por blocos

- Programação **visual por blocos** (estilo Scratch), simples de usar mas com profundidade.
- **Regra fundamental:** cada peça instalada libera seus próprios blocos. Um drone só executa blocos das peças que possui.
- **Bloco sem a peça:** a rotina pode conter blocos de peças que o drone não tem. O editor avisa, mas não impede. Em execução, o bloco **falha e registra no log** (ex.: "sem broca instalada") (D5).
- Novos blocos são desbloqueados conforme o jogador desbloqueia novas peças.

| Peça | Blocos liberados |
|---|---|
| Chassi (qualquer classe) | mover, voltar à base, esperar, repetir, se/senão, **quando**, ir até o minerador |
| Chassi Batedor | explorar |
| Broca | cavar, minerar alvo |
| Compartimento de carga | coletar, descarregar, `carga cheia?` |
| Bateria | `bateria baixa?`, recarregar |
| Scanner de minério | `vejo minério [tipo]?`, ir até minério mais próximo [tipo] (só enxerga tiles revelados, D7) |
| Sensor de ameaça | `criatura por perto?`, `distância da criatura`, `minerador em perigo?` |
| Arma | mirar, atirar, `inimigo no alcance?` |
| Antena | enviar sinal, ouvir sinal, `recebi sinal?`, ir até origem do sinal |
| Chip de memória | guardar posição, ir até posição salva, ir até sinalizador, variáveis |
| Braço construtor (futuro) | construir barreira, consertar drone, consertar estrutura |
| Emissor sônico (futuro) | repelir criaturas, mascarar barulho |

Categorias de blocos:

- **Ações**: fazem algo no mundo. Podem **durar vários ticks** (ex.: `ir até`, `minerar`).
- **Sensores / condições**: perguntas que retornam verdadeiro/falso ou valores.
- **Controle**: se/senão, repetir, repetir até, esperar.
- **Eventos**: `QUANDO <condição>`, que interrompe a ação atual (ver 7.3).
- **Comunicação e memória**: desbloqueados mais tarde.
- **Funções** (avançado): trechos de programa reutilizáveis.

### 7.3 Execução e reatividade

- Ações duradouras bloqueiam a sequência até terminar (D1).
- A reatividade vem dos blocos **`QUANDO <condição>`**, avaliados a cada tick. Se um dispara, a ação atual é **cancelada**, o corpo do `QUANDO` executa e, ao terminar, o **programa principal reinicia** do começo.
- Interrupções e prioridades são um conceito de progressão (seção 9.3): o jogador descobre que sem `QUANDO` o drone só reage entre uma ação e outra.

### 7.4 Rotinas e parâmetros

- **Uma rotina por classe**: todos os drones da classe executam a mesma rotina (espelhada). No início, o jogador cuida de 3 rotinas (D9).
- Editar a rotina **atualiza todos os drones da classe** e **reinicia o programa** deles (D6).
- **Parâmetros por drone**: a rotina declara parâmetros (ex.: `minério alvo`, `meu posto`) e cada drone tem os próprios valores, configurados no painel do drone. A mesma rotina gera comportamentos diferentes.
- **Rotinas extras por classe** são uma tecnologia futura liberada pela corporação.

### 7.5 Exemplo de programas

```
MINERADOR (parâmetro: minério alvo):
  QUANDO criatura por perto:
    enviar sinal "socorro"
    voltar à base

  REPETIR SEMPRE:
    SE bateria baixa OU carga cheia:
      voltar à base
      descarregar
      recarregar
    SENÃO SE vejo minério [minério alvo]:
      ir até minério mais próximo [minério alvo]
      minerar
    SENÃO:
      esperar

DEFENSOR (parâmetro: meu posto):
  QUANDO inimigo no alcance:
    atirar

  REPETIR SEMPRE:
    SE minerador em perigo:
      ir até o minerador
    SENÃO SE recebi sinal "socorro":
      ir até origem do sinal
    SENÃO:
      ir até sinalizador [meu posto]

BATEDOR:
  REPETIR SEMPRE:
    SE bateria baixa:
      voltar à base
      recarregar
    SENÃO:
      explorar
```

### 7.6 Primeiro drone (onboarding)

O primeiro Minerador vem com uma **rotina pronta que funciona, mas tem um defeito visível** (ex.: não volta à base com bateria baixa). O jogador aprende a editar consertando, sem tutorial (D8).

### 7.7 Cooperação entre classes

- A neblina cria **dependência natural**: o scanner do Minerador só enxerga tiles revelados. Sem Batedores, os Mineradores ficam limitados ao que o jogador já explorou (D7).
- A **comunicação entre drones** é uma dinâmica central: sistemas cooperativos (Minerador pede socorro, Defensor responde) são descobertos pelo jogador, nunca ensinados.

---

## 8. Criaturas e combate

### 8.1 Agressão reativa (não por timer)

As criaturas reagem ao **impacto do jogador**, não a um relógio:

- **Barulho:** brocas e explosivos atraem criaturas. Brocas silenciosas mineram mais devagar e provocam menos.
- **Perturbação por região:** cada área (chunk de tiles) tem um medidor que sobe com a extração (muito mais com cristal do Veio) e decai com o tempo. Ao atingir limites, gera ataques.
- **Cristais sagrados:** alguns cristais do Veio são ninhos. Valem muito, mas extraí-los provoca um ataque grande.
- **Território:** túneis perto de tocas são mais perigosos.

O jogador escolhe o próprio ritmo: minerar agressivo e defender muito, ou minerar com cuidado e gastar menos em defesa.

### 8.2 Combate e drones abatidos

- Criaturas podem ser **mortas** e deixam **fragmentos de cristal** (seção 5.3).
- Pela lore, matar não extingue a espécie: o Veio sempre gera novas.
- Quando um drone é destruído, ele **não vira sucata imediatamente**. Ele fica **abatido** por um tempo:
  - exibe o **último trecho do seu log** (os últimos blocos executados e eventos: "bateria 8%", "criatura detectada", "sinal enviado: socorro", "sem resposta", "sem broca instalada"…)
  - o jogador pode **consertá-lo em campo** com a ferramenta de reparo (ou, no futuro, um drone Suporte)
  - se não for consertado a tempo, vira **sucata reciclável**, devolvendo parte dos minérios

### 8.3 Tipos por camada (proposta)

Cada camada introduz criaturas que **quebram a estratégia da camada anterior**:

| Camada | Criatura | O que quebra | O que o jogador aprende |
|---|---|---|---|
| 1 | Rastejadores lentos | — (introdução) | atirar, voltar à base, `QUANDO` |
| 2 | Enxame rápido | torre de alvo único | defesa em área, barreiras |
| 3 | Cavadores | barreiras e túneis fixos | patrulha, sensores, sinais |
| 4 | Caçadores por barulho | mineração agressiva | broca silenciosa, mascarar som |
| 5 | Blindados | dano bruto | coordenação (atordoar + atacar) |
| 6 | Emboscadores | drones sozinhos | grupos, escolta, pedidos de socorro |

---

## 9. Progressão e dificuldade

### 9.1 Parede macia por camada

O jogador fica "preso" numa camada até superar as criaturas dela. Sempre há **dois caminhos**:

- **Entender** a estratégia certa (rápido e satisfatório)
- **Ficar mais forte** minerando mais, enviando cristal, liberando peças e usando fragmentos (mais lento)

Ninguém trava para sempre; quem pensa é recompensado.

### 9.2 Ensino pelo próprio erro

Sem tutorial explícito. O jogo ensina por:

- **Primeiro drone com rotina defeituosa** (seção 7.6).
- **Log dos drones abatidos** (seção 8.2): mostra o que o drone estava fazendo quando caiu, dando pistas do que deu errado.
- **Debug visual** do bloco ativo em cada drone.
- **Comunicações da corporação** liberando tecnologias que sugerem novos usos.
- Desafios de cada camada desenhados para exigir um conceito novo.

### 9.3 Progressão de conceitos

1. Início: mover, cavar, voltar
2. Condicionais e sensores
3. Eventos e interrupções (`QUANDO`)
4. Parâmetros por drone
5. Memória e variáveis
6. Comunicação entre drones
7. Funções, prioridades, coordenação de grupos, rotinas extras

---

## 10. Base e manutenção

- **Base** na superfície (ou entrada da mina): recarga, descarga, **fabricação**, **ponto de envio** de cristal à corporação.
- **Energia da base** é limitada; mais drones consomem mais.
- **Manutenção:** drones danificados precisam de conserto; túneis podem ser invadidos e cortar rotas; escadas e elevadores podem ser danificados; jazidas se esgotam, forçando a operação a descer.

---

## 11. Interface (PC)

- Editor de blocos **lado a lado com a mina**: editar e ver o drone reagir em tempo real.
- Uma aba de rotina **por classe** (Batedor, Minerador, Defensor).
- Arrastar e soltar com mouse; copiar/colar blocos; atalhos de teclado.
- **Paleta filtrada pela classe**; blocos de peças ausentes aparecem com aviso.
- Clicar num drone mostra o **bloco que ele está executando** (debug visual) e o **painel do drone** (loadout e parâmetros).
- Drone abatido mostra seu **log** em um balão ou painel.
- **Painel de debug:** bloco ativo, histórico de ações, pausar e avançar passo a passo.
- **Controles de velocidade** da simulação: pausa, 1×, 2×, 4×.
- Atalhos para o jogador enviar sinais manuais.
- **Build web**: roda no navegador, inclusive no celular, para testes. Controles de toque são apenas um apoio aos testes; a interface é pensada para PC (D13).
- Futuro opcional: **modo texto** (mesmos comandos como código escrito).

---

## 12. Arquitetura técnica

- **Engine:** Godot 4.7.2-stable, GDScript, renderer **Compatibility** (D12).
- **Idioma:** código e comentários em inglês; documentação de design em português (D4).
- **Mina:** TileMapLayer com terreno destrutível e dados por tile (tipo, dureza, minério, revelado, perturbação).
- **Gerador procedural** com seed (FastNoiseLite e regras de veios e tocas), isolado em `world/mine/mine_generator.gd` (D3).
- **Neblina:** mapa de tiles revelados, consultado pelo render e pelos scanners (D7).
- **Programas como dados:** cada rotina é uma árvore de blocos serializável em JSON, com id estável por bloco, classe e parâmetros declarados. Nada de lógica de drone "hardcoded". Formato detalhado em [PLAN.md](PLAN.md).
- **Interpretador** puro (sem nós da cena), um por drone:
  - **pilha de frames**; ações duradouras são **tarefas** com `tick()` e `cancel()`
  - **handlers `QUANDO`** avaliados a cada tick, com preempção (D1)
  - **orçamento de 32 passos** instantâneos por tick; se estourar, o drone fica ocioso e registra no log (D11)
  - mesmo programa em vários drones; destaque do bloco ativo; pausar e avançar passo a passo; salvar e carregar trivialmente; modo texto futuro sobre a mesma estrutura
- **Contexto do drone:** interface entre os blocos e o mundo (`has_part`, `param`, `is_revealed`…). No jogo, o drone implementa; nos testes, um contexto falso.
- **Registro de blocos:** cada peça registra os tipos de bloco que libera. Adicionar uma peça = registrar novos blocos, sem mexer no interpretador.
- **Log por drone:** buffer circular com os últimos N blocos executados e eventos relevantes, exibido quando o drone é abatido.
- **Simulação desacoplada da renderização:** tick fixo de lógica a **10 Hz**; visual interpola; controles de velocidade (D11).
- **Pathfinding** dos drones (voadores) com AStarGrid2D sobre tiles vazios, atualizado quando o terreno muda.
- **Sinais:** barramento de mensagens simples (canal, origem, posição), usado por drones e pelo jogador.
- **Inventário/economia:** recursos por tipo, receitas de fabricação definidas como dados (`Resource`).
- **Editor de blocos:** implementação própria com nós `Control` (o `GraphEdit` é para grafos de nós, não para blocos empilháveis).
- **Testes:** runner headless próprio em `tests/`, rodado no CI a cada push.
- **Build web** gerado pelo CI e publicado no GitHub Pages (D13).

---

## 13. Escopo do primeiro protótipo

Objetivo: **validar o loop explorar → minerar → fabricar → programar → defender** na camada 1. Marcos detalhados em [PLAN.md](PLAN.md).

**Dentro do escopo**

- Uma camada de mina **gerada por seed** com terra, rocha, **ferro**, **cobre** e **cristal do Veio**
- **Neblina**, revelada pelo jogador e pelo Batedor
- Base simples com recarga, descarga, fabricação e ponto de envio de cristal
- Jogador controlável **com gravidade**, com **ferramenta de escavação**, **arma básica**, **ferramenta de reparo** e **escadas**
- **3 classes de drone** (Batedor, Minerador, Defensor), cada uma com seu chassi e slots
- **Uma rotina por classe** e **parâmetros por drone**
- Peças: broca, carga, bateria, scanner de minério, sensor de ameaça, arma básica, antena
- Fabricação de drones e peças com ferro e cobre
- Envio de cristal liberando ao menos 1 peça nova (validar o ciclo da corporação)
- Editor de blocos funcional com: mover, cavar, minerar, voltar à base, descarregar, recarregar, se/senão, repetir, **quando**, ir até o minerador, **explorar**, sensores das peças acima, enviar/ouvir sinal, atirar
- Interpretador por tick com destaque do bloco ativo e controles de velocidade
- **Primeiro Minerador com rotina defeituosa**
- 1 tipo de criatura (rastejador) com agressão por barulho/perturbação
- Criaturas morrem e deixam fragmentos; 1 ou 2 upgrades simples de drone com fragmentos
- Drone abatido exibindo log, consertável pelo jogador, senão vira sucata
- Salvar/carregar rotinas
- **Build web** para testes

**Fora do escopo (por enquanto)**

- Camadas 2+, rocha de fronteira e criaturas avançadas
- Lore, narrativa e final
- Elevador, jetpack, sinalizadores, barreiras
- Classe Suporte e rotinas extras por classe
- Memória, funções, modo texto
- Arte final, áudio, menus completos
- Save completo do jogo
- Modo roguelike

---

## 14. Questões em aberto

- Nome do jogo
- Detalhes da lore do Veio e caminhos de final
- Lista final de minérios e receitas
- Formato da relação com a corporação (créditos, reputação, árvore de tecnologias)
- Upgrades com fragmentos são permanentes? Têm limite por drone? Algum efeito colateral (ex.: drones com fragmentos atraem mais criaturas)?
- Quantos slots por chassi de cada classe
- Tempo que um drone fica abatido antes de virar sucata
- Estilo visual (pixel art vs. outro)
- Comportamento exato do bloco `explorar` (ir ao tile oculto mais próximo? andar aleatório?)
- Diferença exata entre `cavar` e `minerar`, e em qual direção `cavar` atua
- Raio dos sensores, alcance da antena e escopo dos sinais (global ou por alcance)
- Prioridade entre vários `QUANDO` disparando ao mesmo tempo
- Regras do modo roguelike (futuro)

### Resolvidas

| Questão | Decisão |
|---|---|
| Mapa procedural ou à mão | sempre procedural, com seed (D3) |
| Editar rotina afeta todos ou cria cópia | afeta todos da classe e reinicia o programa (D6, D9) |
| Chassis diferentes | sim: 3 classes fixas, cada uma com seu chassi (D9) |
| Reatividade das ações longas | blocos `QUANDO` com interrupção (D1) |
| Como o jogador sobe | escadas → elevador → jetpack (D2) |
| Neblina | sim; o scanner só vê tiles revelados (D7) |
| Bloco sem a peça | falha em execução com log (D5) |
| Idioma do código | inglês (D4) |
| Teste no celular | build web (D13) |

---

## 15. Notas para o Claude Code

- A análise inicial deste documento já foi feita. As decisões estão em [DECISIONS.md](DECISIONS.md) e o plano em [PLAN.md](PLAN.md).
- **Mantenha este GDD atualizado:** toda nova decisão entra em DECISIONS.md (com um ID `Dn`) e é refletida nas seções correspondentes deste documento, na mesma mudança.
- Siga os marcos do PLAN.md em passos pequenos e testáveis.
- Idioma: responder em **português**. Código e comentários em **inglês**.

---

## Histórico

| Versão | Mudanças |
|---|---|
| 1 | Documento original |
| 2 | Decisões D1–D13 incorporadas: 3 classes com uma rotina cada e parâmetros por drone; blocos `QUANDO`; drones voam e jogador tem gravidade (escadas → elevador → jetpack); mapa sempre procedural; neblina; bloco sem peça falha com log; primeiro drone com rotina defeituosa; tick de 10 Hz e controles de velocidade; Godot 4.7.2; build web para testes |
