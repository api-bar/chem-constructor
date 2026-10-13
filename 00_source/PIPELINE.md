# Конвейер сборки v1.0 (00_source/pipeline)

Все скрипты запускаются из одной рабочей папки, в которой лежат `chem_constructor.scad`, `chemlib.py`, `molecules.py`,
`assemble3.py`, `seat_cache.json` (из `00_source/`) и скрипты из `pipeline/` (скопируйте их рядом).
Зависимости: OpenSCAD, Python 3 с `trimesh`, `numpy`, `shapely`, `manifold3d`, `matplotlib`, `usd-core`, `fast_simplification`, `scipy`.

| Шаг | Команда | Результат |
|---|---|---|
| 1. Детали | `sh build_parts.sh` (`PARTS_DIR=v26`) | STL всех атомов, связей, тестеров |
| 2. Проверка деталей | `PARTS_DIR=v26 python3 verify.py carbon oxygen bond_CC ...` | герметичность, одно тело, «острова» по слоям |
| 3. Сборка молекул | `python3 assemble3.py <молекула>...` | `asm3/<молекула>.glb` и `.json` (булева посадка, проверка пересечений и хиральности) |
| 4. Превью | `python3 make_previews.py` | `pkg/02_molecules/<молекула>/{.glb,.png}` |
| 5. USDZ (iPhone AR) | `python3 tousdz.py <молекула>...` (по 1–3 молекулы за вызов — тяжело) | `.usdz` |
| 6. README и пластины молекул | `python3 docs.py <молекула>...` | `README.md` и `plates/*.3mf` каждой молекулы |
| 7. Пластины основного набора | `python3 make_main_plates.py` | `03_plates_by_color/full_set_main_molecules/` + `bom.json` |
| 8. Общий README | `python3 make_main_readme.py` | `README.md` |

Ожидаемая структура рабочей папки: `v26/` (STL деталей), `asm3/` (сборки), `pkg/01_components/` (копия STL компонентов),
`pkg/02_molecules/`, `pkg/03_plates_by_color/`, `pkg/04_tester/`.

## Защита файлов из git
Скрипты не перезаписывают файлы, которые отслеживает git (README, `bom.json`, PNG-превью и т. п.): такие файлы пропускаются
с сообщением «пропуск (файл в git)». Перегенерировать их намеренно: `SAFEIO_FORCE=1 python3 <скрипт>.py`, затем проверить `git diff`.

## Что скриптом не покрыто
- 3MF-тестеры (`04_tester/*.3mf`) и PNG-превью компонентов (`01_components/*.png`) делались разовыми командами, скрипта в репозитории нет — файлы лежат в релизе готовыми.
- Скрипты восстановлены из истории работы; в них есть пути и допущения под ту рабочую папку (`pkg/`, `asm3/`, `v26/`),
  а `make_main_plates.py` копирует готовые 3MF-тестеры из `TESTER_SRC` (по умолчанию `../04_tester`; если папки нет, шаг пропускается).
  Полный прогон с нуля после восстановления не проводился — проверьте на одной молекуле (например, `H2O_water`) перед массовой сборкой.
