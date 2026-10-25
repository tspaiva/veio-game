# Documento de Design — Jogo de Mineração com Drones Programáveis

> Nome provisório: **Veio**
> Plataforma: **PC** (Windows, Linux, Mac)
> Engine: **Godot 4** (versão estável mais recente)
> Status: idealização / pré-protótipo

---

## 1. Visão geral

Jogo 2D de mineração e automação em visão de corte lateral. O jogador é um técnico enviado por uma corporação para extrair um cristal raro de um planeta onde **ninguém esteve antes**. Ele começa minerando à mão, mas a mina é profunda demais para uma pessoa só: o jogo gira em torno de **montar e programar drones** (com blocos visuais) para minerar, transportar e defender a operação.

Os drones são construídos com **minérios comuns** extraídos no próprio planeta. O **cristal valioso** é enviado à corporação, que em troca libera novas tecnologias.

O subsolo é o lar de criaturas que reagem à extração. Elas atacam a base e os drones. O jogador programa **drones de defesa** e também atua em campo com seu próprio equipamento. O desafio central é **manter todo o sistema funcionando**: minerando, defendendo e se expandindo.

### Pilares

1. **Programar é jogar** — o prazer vem de ver um sistema criado pelo jogador rodando sozinho.
2. **Errar é divertido** — drones fazem coisas erradas de forma visível e engraçada; depurar faz parte da diversão.
3. **O jogo não ensina, o jogador descobre** — sem tutorial explícito; o ambiente e os desafios guiam.
4. **Toda ação tem custo** — minerar mais gera mais reação das criaturas.
5. **Desafio, não pressão** — o foco é equilíbrio e estratégia, não reflexo nem timer apertado.
6. **O minerador nunca fica inútil** — o jogador continua relevante em campo do início ao fim.

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

1. **Explorar à mão** — o jogador desce e descobre minérios, perigos e criaturas novas.
2. **Entender o problema** — "o cobre está atrás de rocha dura e perto de uma toca".
3. **Montar o drone** — fabricar peças com minérios comuns e escolher o hardware para a tarefa.
4. **Programar** — montar a rotina com blocos.
5. **Assistir e depurar** — observar, encontrar falhas, ajustar.
6. **Escalar** — replicar drones; a produção automática alimenta a fabricação.
7. **Enviar cristal** — o cristal coletado vai para a corporação, que libera novas tecnologias.
8. **Defender** — lidar com a reação das criaturas, com drones e com o próprio equipamento.

---

## 4. A mina

- Visão em **corte lateral 2D**, com terreno escavável baseado em tiles.
- Dividida em **camadas** de profundidade. Cada camada tem minérios, tipos de rocha, perigos e criaturas próprios.
- Terreno escavado fica aberto (túneis persistentes), formando rotas que drones usam.
- Tipos de tile (exemplos): terra, rocha, rocha dura, **minérios comuns** (ferro, cobre, silício…), **cristal do Veio**, toca de criaturas, água, lava/gás (camadas avançadas).
- **Rocha de fronteira** separa as camadas (ver seção 6.3).
- Câmera com zoom (rodinha do mouse) e arraste, permitindo alternar entre visão geral e detalhe.

---

## 5. Minérios e economia

### 5.1 Minérios comuns — para construir

Usados na **fabricação** de drones, peças, estruturas e equipamento do jogador. Novos minérios aparecem em camadas mais profundas, liberando peças melhores.

| Minério (proposta) | Camada | Uso principal |
|---|---|---|
| Ferro | 1 | chassis, estruturas, barreiras |
| Cobre | 1 | fiação, baterias, antenas |
| Silício | 2 | sensores, chips de memória |
| Titânio | 3 | blindagem, brocas melhores |
| Outros a definir | 4+ | peças avançadas |

### 5.2 Cristal do Veio — para a corporação

- Não é usado na fabricação. É **enviado à corporação** por um ponto de envio na base.
- Em troca, a corporação concede **créditos / reputação** que liberam:
  - novas **plantas de peças** (que destravam novos blocos de programação)
  - melhorias da base (energia, capacidade de fabricação)
  - equipamento novo para o jogador
- Metas de envio funcionam como **marcos**, não punições: atingir a meta libera tecnologia; não há penalidade por atraso (desafio, não pressão).
- O cristal é o que mais provoca as criaturas: extrair cristal aumenta muito a perturbação da região.

### 5.3 Fragmentos de cristal — para upgrades

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

### 6.1 Equipamento

- **Ferramenta de escavação** — minera à mão; melhorável (mais rápida, fura rocha dura).
- **Arma pessoal** — para defesa em emergências; melhorável e com variações (tiro único, área, atordoar).
- **Ferramenta de reparo** — conserta drones e estruturas em campo, inclusive **drones abatidos antes de virarem sucata** (ver seção 8.2).
- **Construção em campo** — posicionar **barreiras** e **sinalizadores** (pontos que os drones podem usar como alvo, ex.: "ir até sinalizador A").
- **Mobilidade** — gancho ou jetpack para se mover na mina vertical.
- **Cargas de explosivo** — abrir a rocha de fronteira entre camadas.

O equipamento é fabricado com minérios comuns, liberado pela corporação e melhorado com fragmentos.

### 6.2 Integração com os drones

O jogador participa da programação como um elemento do mundo:

- Blocos como **"ir até o minerador"**, **"seguir o minerador"**, **"minerador em perigo?"**
- O jogador pode **enviar sinais manualmente** (atalho de teclado), que os drones ouvem como qualquer outro sinal. Ex.: chamar defensores, ordenar recuo.
- Sinalizadores colocados pelo jogador servem de referência para rotas e postos.

### 6.3 Vanguarda

- Só o jogador abre **novas camadas**: a rocha de fronteira exige explosivos posicionados por ele.
- Explorar uma camada nova é sempre feito pessoalmente primeiro, e é o momento de maior risco.

### 6.4 Morte do jogador

- O jogador reaparece na base. Perde a carga que levava. Drones continuam executando seus programas.

---

## 7. Drones

### 7.1 Hardware

Cada drone tem um **chassi com slots limitados**. Isso força drones especialistas em vez de um drone que faz tudo. Peças são fabricadas com minérios comuns; novas peças são liberadas pela corporação.

Categorias de peças:

- **Ferramenta:** broca básica, broca silenciosa, broca de diamante, laser, explosivo
- **Sensores:** scanner de minério, sensor de ameaça, câmera (ver outros drones)
- **Carga:** compartimento pequeno, compartimento grande
- **Energia:** bateria (limita autonomia, força retorno à base)
- **Armas:** torreta, laser, atordoador, defesa em área
- **Comunicação:** antena (sinais entre drones)
- **Memória:** chip de memória (guardar posições e valores)
- **Suporte:** braço construtor (barreiras, consertos), emissor sônico (repelir criaturas, mascarar barulho)

A **bateria** é central: cria o ritmo de ir e voltar e transforma rota e eficiência em problema real.

### 7.2 Software — programação por blocos

- Programação **visual por blocos** (estilo Scratch), simples de usar mas com profundidade.
- **Regra fundamental:** cada peça instalada libera seus próprios blocos. Um drone só executa blocos das peças que possui.
- Novos blocos são desbloqueados conforme o jogador desbloqueia novas peças.

| Peça | Blocos liberados |
|---|---|
| Chassi básico (início) | mover, voltar à base, esperar, repetir, se/senão, ir até o minerador |
| Broca | cavar, minerar alvo |
| Compartimento de carga | coletar, descarregar, `carga cheia?` |
| Bateria | `bateria baixa?`, recarregar |
| Scanner de minério | `vejo minério [tipo]?`, ir até minério mais próximo [tipo] |
| Sensor de ameaça | `criatura por perto?`, `distância da criatura`, `minerador em perigo?` |
| Arma | mirar, atirar, `inimigo no alcance?` |
| Antena | enviar sinal, ouvir sinal, `recebi sinal?`, ir até origem do sinal |
| Chip de memória | guardar posição, ir até posição salva, ir até sinalizador, variáveis |
| Braço construtor | construir barreira, consertar drone, consertar estrutura |
| Emissor sônico | repelir criaturas, mascarar barulho |

Categorias de blocos:

- **Ações** — fazem algo no mundo
- **Sensores / condições** — perguntas que retornam verdadeiro/falso ou valores
- **Controle** — se/senão, repetir, repetir até, esperar
- **Comunicação e memória** — desbloqueados mais tarde
- **Funções** (avançado) — trechos de programa reutilizáveis

### 7.3 Rotinas

- Um programa é salvo como **rotina** e pode ser aplicado a vários drones.
- Editar a rotina atualiza todos os drones que a usam (ou permitir cópia independente — decidir).

### 7.4 Exemplo de programas

```
MINERADOR DE FERRO:
  REPETIR SEMPRE:
    SE criatura por perto:
      enviar sinal "socorro"
      voltar à base
    SENÃO SE bateria baixa OU carga cheia:
      voltar à base
      descarregar
      recarregar
    SENÃO SE vejo minério [ferro]:
      ir até minério mais próximo [ferro]
      minerar
    SENÃO:
      explorar

DEFENSOR:
  REPETIR SEMPRE:
    SE minerador em perigo:
      ir até o minerador
    SENÃO SE recebi sinal "socorro":
      ir até origem do sinal
    SE inimigo no alcance:
      atirar
    SENÃO:
      ir até sinalizador "posto 1"
```

### 7.5 Papéis emergentes

- **Mineradores** — produzem minérios comuns e cristal
- **Defensores** — patrulham, guardam, respondem a sinais, protegem o jogador
- **Suporte** — constroem barreiras, consertam, acalmam áreas
- **Batedores** — escaneiam e marcam minérios para os mineradores

A **comunicação entre drones** é uma dinâmica central: sistemas cooperativos são descobertos pelo jogador, nunca ensinados.

---

## 8. Criaturas e combate

### 8.1 Agressão reativa (não por timer)

As criaturas reagem ao **impacto do jogador**, não a um relógio:

- **Barulho:** brocas e explosivos atraem criaturas. Brocas silenciosas mineram mais devagar e provocam menos.
- **Perturbação por região:** cada área tem um medidor que sobe com a extração (muito mais com cristal do Veio). Ao atingir limites, gera ataques.
- **Cristais sagrados:** alguns cristais do Veio são ninhos. Valem muito, mas extraí-los provoca um ataque grande.
- **Território:** túneis perto de tocas são mais perigosos.

O jogador escolhe o próprio ritmo: minerar agressivo e defender muito, ou minerar com cuidado e gastar menos em defesa.

### 8.2 Combate e drones abatidos

- Criaturas podem ser **mortas** e deixam **fragmentos de cristal** (seção 5.3).
- Pela lore, matar não extingue a espécie: o Veio sempre gera novas.
- Quando um drone é destruído, ele **não vira sucata imediatamente**. Ele fica **abatido** por um tempo:
  - exibe o **último trecho do seu log** (os últimos blocos executados e eventos: "bateria 8%", "criatura detectada", "sinal enviado: socorro", "sem resposta"…)
  - o jogador pode **consertá-lo em campo** com a ferramenta de reparo (ou um drone de suporte pode fazê-lo)
  - se não for consertado a tempo, vira **sucata reciclável**, devolvendo parte dos minérios

### 8.3 Tipos por camada (proposta)

Cada camada introduz criaturas que **quebram a estratégia da camada anterior**:

| Camada | Criatura | O que quebra | O que o jogador aprende |
|---|---|---|---|
| 1 | Rastejadores lentos | — (introdução) | atirar, voltar à base |
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

- **Log dos drones abatidos** (seção 8.2): mostra o que o drone estava fazendo quando caiu, dando pistas do que deu errado.
- **Debug visual** do bloco ativo em cada drone.
- **Comunicações da corporação** liberando tecnologias que sugerem novos usos.
- Desafios de cada camada desenhados para exigir um conceito novo.

### 9.3 Progressão de conceitos

1. Início: mover, cavar, voltar
2. Condicionais e sensores
3. Memória e variáveis
4. Comunicação entre drones
5. Funções, prioridades, coordenação de grupos

---

## 10. Base e manutenção

- **Base** na superfície (ou entrada da mina): recarga, descarga, **fabricação**, **ponto de envio** de cristal à corporação.
- **Energia da base** é limitada; mais drones consomem mais.
- **Manutenção:** drones danificados precisam de conserto; túneis podem ser invadidos e cortar rotas; jazidas se esgotam, forçando a operação a descer.

---

## 11. Interface (PC)

- Editor de blocos **lado a lado com a mina**: editar e ver o drone reagir em tempo real.
- Arrastar e soltar com mouse; copiar/colar blocos; atalhos de teclado.
- Clicar num drone mostra o **bloco que ele está executando** (debug visual).
- Drone abatido mostra seu **log** em um balão ou painel.
- **Painel de debug:** bloco ativo, histórico de ações, pausar e avançar passo a passo.
- Lista de rotinas salvas e quais drones usam cada uma.
- Atalhos para o jogador enviar sinais manuais.
- Futuro opcional: **modo texto** (mesmos comandos como código escrito).

---

## 12. Arquitetura técnica (direção sugerida)

- **Engine:** Godot 4, GDScript.
- **Mina:** TileMapLayer com terreno destrutível e dados por tile (tipo, dureza, minério, perturbação).
- **Programas como dados:** cada rotina é uma árvore de blocos serializável (Dictionary/JSON). Nada de lógica de drone "hardcoded".
- **Interpretador:** executa um bloco (ou passo) por *tick* de simulação, por drone. Permite:
  - mesmo programa em vários drones
  - destacar o bloco ativo
  - pausar/avançar passo a passo
  - salvar/carregar trivialmente
  - modo texto futuro sobre a mesma estrutura
- **Registro de blocos:** cada peça registra os tipos de bloco que libera. Adicionar uma peça = registrar novos blocos, sem mexer no interpretador.
- **Log por drone:** buffer circular com os últimos N blocos executados e eventos relevantes, exibido quando o drone é abatido.
- **Simulação desacoplada da renderização:** tick fixo de lógica; visual interpola.
- **Pathfinding** nos túneis escavados (AStarGrid2D ou similar), atualizado quando o terreno muda.
- **Sinais:** barramento de mensagens simples (canal, origem, posição), usado por drones e pelo jogador.
- **Inventário/economia:** recursos por tipo, receitas de fabricação definidas como dados.
- **Editor de blocos:** nós Control customizados (avaliar GraphEdit vs. implementação própria).

---

## 13. Escopo do primeiro protótipo

Objetivo: **validar o loop minerar → fabricar → programar → defender** na camada 1.

**Dentro do escopo**

- Uma camada de mina com terra, rocha, **ferro**, **cobre** e **cristal do Veio**
- Base simples com recarga, descarga, fabricação e ponto de envio de cristal
- Jogador controlável com **ferramenta de escavação**, **arma básica** e **ferramenta de reparo**
- 1 chassi de drone com slots
- Peças: broca, carga, bateria, scanner de minério, sensor de ameaça, arma básica, antena
- Fabricação de drones e peças com ferro e cobre
- Envio de cristal liberando ao menos 1 peça nova (validar o ciclo da corporação)
- Editor de blocos funcional com: mover, cavar, minerar, voltar à base, descarregar, recarregar, se/senão, repetir, ir até o minerador, sensores das peças acima, enviar/ouvir sinal, atirar
- Interpretador por tick com destaque do bloco ativo
- 1 tipo de criatura (rastejador) com agressão por barulho/perturbação
- Criaturas morrem e deixam fragmentos; 1 ou 2 upgrades simples de drone com fragmentos
- Drone abatido exibindo log, consertável pelo jogador, senão vira sucata
- Salvar/carregar rotinas

**Fora do escopo (por enquanto)**

- Camadas 2+, rocha de fronteira e criaturas avançadas
- Lore, narrativa e final
- Mobilidade avançada (gancho/jetpack), sinalizadores, barreiras
- Memória, funções, modo texto
- Arte final, áudio, menus completos
- Save completo do jogo

---

## 14. Questões em aberto

- Nome do jogo
- Detalhes da lore do Veio e caminhos de final
- Lista final de minérios e receitas
- Formato da relação com a corporação (créditos, reputação, árvore de tecnologias)
- Upgrades com fragmentos são permanentes? Têm limite por drone? Algum efeito colateral (ex.: drones com fragmentos atraem mais criaturas)?
- Editar rotina afeta todos os drones que a usam ou cria cópia?
- Quantos slots por chassi e se haverá chassis diferentes
- Tempo que um drone fica abatido antes de virar sucata
- Estilo visual (pixel art vs. outro)
- Mapa gerado proceduralmente ou desenhado à mão

---

## 15. Instruções para o Claude Code

Este documento descreve um jogo que ainda **não tem código**. Antes de escrever qualquer coisa:

1. **Analise o documento** e aponte riscos técnicos, ambiguidades e decisões que precisam ser tomadas antes de começar.
2. **Proponha a estrutura do projeto Godot 4**: pastas, cenas principais, scripts e autoloads.
3. **Proponha um plano em marcos** para chegar ao protótipo da seção 13, em passos pequenos e testáveis, começando pelo que valida o conceito mais cedo. Sugestão de ordem a avaliar:
   1. Mina em tiles escavável + câmera + jogador escavando
   2. Formato de dados dos programas + interpretador por tick (testável sem editor visual)
   3. Drone executando um programa fixo (minerar e voltar)
   4. Sistema de peças e registro de blocos
   5. Inventário, fabricação e envio de cristal
   6. Editor de blocos visual
   7. Criatura, perturbação, combate (jogador e drones) e fragmentos
   8. Drone abatido: log, conserto e sucata
   9. Sinais entre drones e do jogador
4. **Detalhe o formato de dados** de um programa (exemplo em JSON) e a interface do interpretador.
5. **Aguarde aprovação** do plano antes de criar arquivos.

Idioma: responder em **português**. Comentários de código podem ser em português ou inglês (perguntar a preferência).
