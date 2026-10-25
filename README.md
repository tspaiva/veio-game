# Veio

Jogo 2D de mineração e automação com drones programáveis por blocos. Feito em Godot 4.

- [GDD](docs/GDD.md): documento de design, mantido atualizado
- [Decisões](docs/DECISIONS.md): registro das decisões (D1, D2…) refletidas no GDD
- [Plano](docs/PLAN.md): escopo do protótipo, marcos, estrutura e formato dos programas

**Status:** M0 (fundação) concluído.

## Requisitos

- [Godot 4.7.2-stable](https://godotengine.org/download/archive/4.7.2-stable/) (versão fixada; ver D12)

## Rodando

Abra a pasta no editor do Godot, ou rode pela linha de comando:

```sh
godot --path .
```

## Testes

```sh
./tools/run_tests.sh                       # todos os testes
./tools/run_tests.sh --filter=framework    # só os que contêm o texto
GODOT=/caminho/do/godot ./tools/run_tests.sh
```

Os testes ficam em `tests/unit/test_*.gd`, estendem `TestCase`, e cada método `test_*` é um teste. O CI (`.github/workflows/tests.yml`) roda a mesma suíte a cada push.
