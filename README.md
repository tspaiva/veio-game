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

A publicação no GitHub Pages (para abrir no celular por um link) fica desligada até ser configurada (D13):

1. O Pages precisa estar disponível: repositório **público**, ou conta GitHub Pro/Team se ele for privado.
2. Settings → Pages → Source: **GitHub Actions**.
3. Settings → Secrets and variables → Actions → Variables: crie `PAGES_ENABLED` com o valor `true`.

Depois disso, cada push na branch padrão publica o jogo. Para abrir um mapa específico, use `?seed=123` no fim do link.
