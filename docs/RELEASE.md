# Релиз v1.0: что где лежит

В git — исходники, документация и PNG-превью молекул (около 1,5 МБ). Печатные и 3D-файлы — в ассетах релиза **v1.0**
(GitHub: Releases → v1.0 → Assets). Архивы собраны так, что пути внутри совпадают со структурой репозитория:
распаковка в корень репозитория с объединением папок даёт полную папку набора.

| Ассет | Размер | Содержимое | Распаковывается в |
|---|---|---|---|
| `chem_constructor_v1.0_components_stl.zip` | ≈10 МБ | `01_components/*.stl` — 18 деталей для печати | `01_components/` |
| `chem_constructor_v1.0_plates_main_set.zip` | ≈61 МБ | `03_plates_by_color/…` — пластины по цветам на 14 основных молекул и `bom.json` | `03_plates_by_color/` |
| `chem_constructor_v1.0_tester.zip` | ≈9 МБ | `04_tester/` — призма, ключи, тестовые пластины | `04_tester/` |
| `chem_constructor_v1.0_molecules_models.zip` | ≈227 МБ | для каждой из 20 молекул: `.glb` (Blender), `.usdz` (iPhone AR) и `plates/` (3MF по цветам) | `02_molecules/<молекула>/` |
| `chem_constructor_v1.0.zip` (по желанию) | ≈293 МБ | весь набор одним архивом, в корне папка `chem_constructor_v1.0/` | отдельно от репозитория |

## Как собрать полную папку из репозитория и ассетов
```
git clone <адрес репозитория> chem_constructor && cd chem_constructor
# скачайте 4 ассета в эту папку, затем:
for z in chem_constructor_v1.0_*.zip; do unzip -o "$z"; done
```
`.gitignore` работает как белый список: в git попадают только `*.md`, `*.py`, `*.scad`, `*.json`, `*.sh`, `LICENSE` и PNG-превью молекул (`02_molecules/*/*.png`). Распакованные STL, 3MF, GLB, USDZ и zip в коммиты не попадут.

## Как выпустить релиз
1. `git tag v1.0 && git push --tags`.
2. На GitHub: Releases → Draft a new release → тег `v1.0` → загрузить ассеты из таблицы выше.
3. В описание релиза вставить краткое содержание (что в наборе, что печатать первым — `04_tester/00_test_prism_and_keys.3mf`, ограничения v1).

## Лицензия
[CC BY-NC-SA 4.0](../LICENSE) — на весь набор: модели, документацию и скрипты. При публикации на площадках моделей указывайте ту же лицензию.

## Как получить ассеты из полного набора
Если у вас уже распакован полный набор (папки `01_components` … `04_tester`), положите в его корень `make_release_assets.sh`
и выполните `sh make_release_assets.sh` — в `release_assets/` появятся четыре zip из таблицы выше.
