# Veio

Jogo 2D de mineração e automação com drones programáveis por blocos. Feito em Godot 4.

- [GDD](docs/GDD.md): documento de design, mantido atualizado
- [Decisões](docs/DECISIONS.md): registro das decisões (D1, D2…) refletidas no GDD
- [Plano](docs/PLAN.md): escopo do protótipo, marcos, estrutura e formato dos programas

**Status:** M0 (fundação) e M1 (mina e jogador) concluídos. Próximo: M2 (interpretador).

## Requisitos

- [Godot 4.7.2-stable](https://godotengine.org/download/archive/4.7.2-stable/) (versão fixada; ver D12)

## Rodando

Abra a pasta no editor do Godot, ou rode pela linha de comando:

```sh
godot --path .                 # mapa aleatório
godot --path . -- --seed=123   # mapa fixo
```

### Controles

| PC | Celular | Ação |
|---|---|---|
| A / D | ◀ ▶ | andar |
| Espaço / W | ▲ | pular |
| W / S | ▲ ▼ | subir e descer escada |
| clique esquerdo (segurar) | tocar e segurar | cavar |
| clique direito | MODO, depois tocar | colocar escada (1 ferro) |
| Q | MODO | alternar entre cavar e escada |
| roda do mouse | pinça | zoom |
| botão do meio (arrastar) | — | mover a câmera |
| C | — | voltar a câmera ao jogador |
| N | — | novo mapa |

## Testes

```sh
./tools/run_tests.sh                       # todos os testes
./tools/run_tests.sh --filter=generator    # só os que contêm o texto
GODOT=/caminho/do/godot ./tools/run_tests.sh
```

Os testes ficam em `tests/unit/test_*.gd`, estendem `TestCase`, e cada método `test_*` é um teste.

## Build web

```sh
./tools/export_web.sh                      # gera build/web
cd build/web && python3 -m http.server     # abrir http://localhost:8000
```

Precisa dos templates de exportação web do Godot 4.7.2 (`web_nothreads_*`).

## CI

O workflow `.github/workflows/ci.yml` roda os testes e gera o build web a cada push. O build fica disponível como artefato da execução.

Com o GitHub Pages ativado (Settings → Pages → Source: **GitHub Actions**), cada push na branch padrão publica o jogo em `https://tspaiva.github.io/veio-game/`, que dá para abrir no celular (D13). Sem o Pages ativo, a publicação é pulada. Para publicar sem push: Actions → ci → **Run workflow**. Para abrir um mapa específico, use `?seed=123` no fim do link.
