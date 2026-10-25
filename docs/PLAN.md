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
| M2 ✅ | **Interpretador headless**: formato do programa, registro de blocos por peça, pilha de frames, tarefas duradouras, `QUANDO`, parâmetros, orçamento de instruções, log circular | os programas de exemplo rodam num `FakeContext` e passam nos testes |
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
| `Blocks` | registro de blocos por peça | M3 |
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
- Blocos de controle: `if` (`cond`, `then`, `else`), `forever` (`body`), `repeat` (`args.times`, `body`), `repeat_until` (`cond`, `body`). `when` só aparece em `handlers`.
- Expressões: sensores (`battery_low`…), `and`/`or` (`a`, `b`), `not` (`a`) e `compare` (`cmp` entre `<`, `<=`, `>`, `>=`, `==`, `!=`; `a` e `b` podem ser expressões ou números).

---

## 5. Interface do interpretador

Implementada no M2. Regras de execução em D14.

| Arquivo | Papel |
|---|---|
| `core/program/program.gd` | `Program`: carrega o JSON (`from_json`, `load_file`), normaliza ids e valida (`validate(registry)` devolve erros em português) |
| `core/program/program_runner.gd` | `ProgramRunner`: um por drone; `tick()`, `reset()`, `set_program()`, `state`, `current_block_id`, sinal `block_entered`, `drone_log` |
| `core/program/task.gd` | `Task`: ação em andamento; `tick(ctx) -> Status` (RUNNING/SUCCESS/FAILURE) e `cancel(ctx)` |
| `core/program/drone_context.gd` | `DroneContext`: sensores e ações que os blocos usam. O drone implementa no M3; os testes usam `tests/support/fake_context.gd` |
| `core/program/drone_log.gd` | `DroneLog`: buffer circular de 32 entradas, com repetições agrupadas |
| `core/blocks/block_def.gd` | `BlockDef`: op, tipo (ação, condição, valor, controle, evento), peça que libera, rótulo, argumentos |
| `core/blocks/block_registry.gd` | `BlockRegistry`: blocos por op; `available_for(parts)` dá a paleta do editor |
| `core/blocks/standard_blocks.gd` | biblioteca do protótipo, agrupada por peça |
| `data/routines/*.json` | rotinas iniciais: `miner` (com o defeito da D8), `defender`, `scout` |

```gdscript
var registry := BlockRegistry.standard()
var program := Program.load_file("res://data/routines/miner.json")
var runner := ProgramRunner.new(program, drone_context, registry)
runner.tick()   # uma vez por tick de simulação (10 Hz)
```

**Adicionar uma peça:** criar os sensores e ações em `DroneContext` (e no drone) e registrar os blocos em `StandardBlocks`. O interpretador não muda.

## 6. Como rodar

Ver o [README](../README.md).
