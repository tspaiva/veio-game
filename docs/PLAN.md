# Plano de desenvolvimento — protótipo

Baseado no [GDD](GDD.md) e nas [decisões](DECISIONS.md).

---

## 1. Escopo do protótipo (revisão da seção 13 do GDD)

Objetivo: validar o loop **explorar → minerar → fabricar → programar → defender** na camada 1.

Mantém tudo da seção 13 do GDD, com estes ajustes:

| Mudança | Motivo |
|---|---|
| + **3 classes** (Batedor, Minerador, Defensor), uma rotina por classe | D9 |
| + **Parâmetros por drone** | D9 |
| + **Neblina**; o scanner só vê tiles revelados | D7 |
| + **Escadas** para o jogador subir e descer | D2 |
| + **Bloco `QUANDO`** (interrupção) | D1 |
| + **Primeiro Minerador com rotina defeituosa** | D8 |
| + **Controles de velocidade** da simulação | D11 |
| Mapa **gerado por seed** | D3 |
| + **Build web** publicado pelo CI | D13 |

Continuam fora: camadas 2+, rocha de fronteira, elevador, jetpack, sinalizadores, barreiras, memória e variáveis, funções, modo texto, classe Suporte, rotinas extras, lore, arte e áudio finais, save completo.

---

## 2. Marcos

Cada marco termina **jogável ou testável**. M1 e M2 são independentes e podem andar em paralelo.

| # | Marco | Pronto quando… |
|---|---|---|
| M0 ✅ | **Fundação**: projeto Godot, estrutura de pastas, runner de testes, CI | `godot --headless` roda os testes, e o CI passa |
| M1 ✅ | **Mina e jogador**: gerador com seed (terra, rocha, ferro, cobre, cristal), neblina, câmera (zoom e arraste), jogador com gravidade cavando, escadas, **build web no CI + GitHub Pages** e toque básico (D13) | dá para descer cavando e subir pelas escadas; túneis persistem; a neblina revela ao redor; o build web abre no celular |
| M2 | **Interpretador headless**: formato do programa, registro de blocos por peça, pilha de frames, tarefas duradouras, `QUANDO`, parâmetros, orçamento de instruções, log circular | os programas de exemplo rodam num `FakeContext` e passam nos testes |
| M3 | **Minerador em campo**: drone voador, pathfinding, minerar, carga, bateria, base (descarga e recarga), destaque do bloco ativo, rotina defeituosa inicial | um Minerador trabalha sozinho por 10 minutos e o defeito aparece |
| M4 | **Classes e hardware**: chassis por classe, slots, falha por peça ausente, painel do drone com parâmetros | trocar uma peça muda o comportamento; dois mineradores com `minério alvo` diferentes |
| M5 | **Editor de blocos v1**: paleta filtrada pela classe, arrastar e encaixar, `se/senão`, `repetir`, `QUANDO`, parâmetros, salvar e carregar | **primeiro playtest do pilar central** |
| M6 | **Economia**: inventário, fabricação de drones e peças, envio de cristal, 1 desbloqueio da corporação | o ciclo minerar → fabricar → desbloquear fecha |
| M7 | **Ameaça**: rastejador, perturbação por chunk, barulho, combate do jogador, **Defensor**, fragmentos e 1–2 upgrades | minerar cristal provoca ataque, e defender rende fragmentos |
| M8 | **Drone abatido**: estado abatido, log em balão, conserto em campo, sucata | o log explica por que o drone caiu |
| M9 | **Sinais e Batedor**: barramento de mensagens, sinais manuais do jogador, Batedor com `explorar` | o `DEFENSOR` do GDD 7.4 funciona; Batedores ampliam o que os Mineradores enxergam |
| M10 | **Debug e playtest**: painel de debug (passo a passo, histórico), velocidade, ajuste fino | o loop completo do protótipo está jogável |

---

## 3. Estrutura do projeto

```
res://
├── project.godot
├── main.tscn                  # cena de entrada
├── core/                      # lógica pura, sem nós da cena: testável headless
│   ├── sim/                   # relógio de tick, velocidade, pausa
│   ├── program/               # program, interpreter, frame, task, drone_log
│   ├── blocks/                # block_def + definições por peça
│   └── economy/               # inventory, crafting
├── data/                      # Resources editáveis no inspetor
│   ├── parts/
│   ├── classes/               # chassis: scout, miner, defender
│   ├── recipes/
│   ├── tiles/
│   └── routines/              # rotinas iniciais (.json)
├── world/
│   ├── mine/                  # mine.tscn, terrain, mine_generator, nav_grid, fog
│   └── disturbance/
├── entities/
│   ├── player/
│   ├── drone/                 # drone.tscn, drone.gd, drone_context.gd
│   ├── creature/
│   └── base/
├── ui/
│   ├── block_editor/
│   ├── hud/
│   └── debug/
├── autoload/
└── tests/
    ├── framework/             # runner e TestCase
    └── unit/                  # test_*.gd
```

As pastas são criadas conforme cada marco precisa delas.

**Autoloads** (poucos, de propósito):

| Nome | Função | Marco |
|---|---|---|
| `Sim` | tick fixo, velocidade, pausa, passo a passo | M3 |
| `Blocks` | registro de blocos por peça | M2 |
| `Messages` | barramento de sinais (canal, origem, posição) | M9 |
| `Game` | inventário global, créditos, desbloqueios | M6 |

---

## 4. Formato de dados do programa

Árvore de blocos em JSON, com **id estável por bloco**. O id serve para destacar o bloco ativo, para o log e para o futuro modo texto. Condições são sub-árvores no mesmo formato. "Senão se" é um `if` dentro de `else`.

```json
{
  "format": 1,
  "class": "miner",
  "name": "Minerador",
  "params": {
    "target_ore": { "type": "ore", "default": "iron" }
  },
  "handlers": [
    { "id": 100, "op": "when",
      "cond": { "id": 101, "op": "threat_nearby" },
      "body": [
        { "id": 102, "op": "send_signal", "args": { "channel": "socorro" } },
        { "id": 103, "op": "return_to_base" }
      ]
    }
  ],
  "main": [
    { "id": 1, "op": "forever", "body": [
      { "id": 2, "op": "if",
        "cond": { "id": 3, "op": "or",
                  "a": { "id": 4, "op": "battery_low" },
                  "b": { "id": 5, "op": "cargo_full" } },
        "then": [
          { "id": 6, "op": "return_to_base" },
          { "id": 7, "op": "unload" },
          { "id": 8, "op": "recharge" }
        ],
        "else": [
          { "id": 9, "op": "if",
            "cond": { "id": 10, "op": "sees_ore", "args": { "ore": { "param": "target_ore" } } },
            "then": [
              { "id": 11, "op": "goto_nearest_ore", "args": { "ore": { "param": "target_ore" } } },
              { "id": 12, "op": "mine" }
            ],
            "else": [ { "id": 13, "op": "wait", "args": { "ticks": 10 } } ]
          }
        ]
      }
    ]}
  ]
}
```

- `args` aceita literais ou referências `{ "param": "<nome>" }`, resolvidas pelos valores do drone.
- Os valores dos parâmetros ficam no **drone**, não na rotina: `{ "target_ore": "copper" }`.

---

## 5. Interface do interpretador

```gdscript
# Block definition: each part registers its own.
class_name BlockDef extends RefCounted
var op: StringName          # "mine", "battery_low", ...
var part: StringName        # required part; &"" = built into chassis
var kind: Kind              # ACTION, CONDITION, VALUE, CONTROL
func evaluate(ctx: DroneContext, args: Dictionary) -> Variant  # conditions/values: instant
func start(ctx: DroneContext, args: Dictionary) -> Task        # actions: may span many ticks

# Long-running action.
class_name Task extends RefCounted
enum Status { RUNNING, SUCCESS, FAILURE }
func tick(ctx: DroneContext) -> Status
func cancel(ctx: DroneContext) -> void   # called when a `when` handler preempts

# One runner per drone.
class_name ProgramRunner extends RefCounted
signal block_entered(block_id: int)
enum State { RUNNING, IDLE, HALTED, ERROR }
func _init(program: Program, ctx: DroneContext, registry: BlockRegistry)
func tick() -> void
func reset() -> void
var current_block_id: int
var state: State
var log: DroneLog           # ring buffer of last N blocks/events

# What blocks can ask of / do in the world.
# The Drone implements it in-game; tests use a FakeContext.
class_name DroneContext extends RefCounted
func has_part(part: StringName) -> bool
func param(name: StringName) -> Variant
func is_revealed(cell: Vector2i) -> bool
func cell() -> Vector2i
# ...
```

**Ciclo de um tick:**

1. Avalia os handlers `QUANDO` (em ordem de prioridade). Se um dispara e não está ativo, chama `cancel()` na tarefa atual, descarta a pilha e empilha o corpo do handler.
2. Se há uma tarefa ativa, chama `task.tick()`. Se ela devolver `RUNNING`, o tick acaba aí.
3. Senão, avança a pilha executando blocos de controle e condições (instantâneos) até iniciar a próxima ação, com no máximo 32 passos (D11). Se o limite estourar, o estado vira `IDLE` e o log registra.
4. Se o bloco exige uma peça ausente, a ação falha e o log registra `"sem <peça>"` (D5).
5. Quando o corpo de um handler termina, o `main` reinicia do começo (D1).

---

## 6. Como rodar

Ver o [README](../README.md).
