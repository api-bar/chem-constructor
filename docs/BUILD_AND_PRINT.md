# Сборка модели для печати из исходников

Печатные STL и 3MF в git не публикуются. Их собирают локально из `00_source/chem_constructor.scad` и скриптов в `00_source/pipeline/`. На принтер уходят отдельные атомы и связи (STL или пластина 3MF). Файл `.glb` — сборка для просмотра, как детали стыкуются; одним телом на стол её не отправляют.

Команды ниже запускаются из папки `00_source`.

## Что понадобится

- [OpenSCAD](https://openscad.org/). Гравировка символов и длин связей использует шрифт **DejaVu Sans Bold** — он должен быть установлен в системе.
- Python 3 и пакеты `numpy`, `trimesh`, `manifold3d` (булева проверка посадки ключа в паз). Файла зависимостей в репозитории нет:

```bash
python3 -m pip install numpy trimesh manifold3d
```

## 1. Деталь в STL

Имя детали — значение `PART` в `chem_constructor.scad` (цепочка `if (PART == …)` ближе к концу файла). Одна деталь:

```bash
cd 00_source
mkdir -p v2
openscad -D 'PRESET="toddler"' -D 'PART="carbon"' -o v2/carbon.stl chem_constructor.scad
```

`toddler` — рабочий масштаб 90 мм/Å. Углерод считается около 5 минут, остальные атомы быстрее. Имя файла совпадает с `PART`: сборка молекулы ищет `v2/carbon.stl`, `v2/bond_OH.stl` и так далее.

Имена для печати:

| Группа | `PART` |
|---|---|
| Атомы | `hydrogen`, `carbon`, `nitrogen`, `oxygen`, `lp_cap_B`, `fluorine`, `chlorine`, `sodium`, `potassium`, `magnesium`, `calcium`, `sulfur`, `phosphorus` |
| Одинарные связи | `bond_CC`, `bond_CH`, `bond_CO`, `bond_CN`, `bond_NH`, `bond_OH`, `bond_HH` и пары новых элементов (`bond_NaCl`, `bond_HF`, …) |
| Двойные и тройные | `bond_CdC`, `bond_CdO`, `bond_NdO`, `bond_CtC`, `bond_CtN`, `bond_OO`, `bond_NN`, `bond_SdO`, `bond_PdO`, … |
| Универсальные | `bond_U1`, `bond_U2`, `bond_UD1`, `bond_UD2`, `bond_UT` |
| Проверка посадки | `test_prism`, `test_key_A`, `test_key_dbl` |

Пакетный скрипт `pipeline/build_parts.sh` экспортирует старый набор (H, O, N, C, заглушка, основные связи, тестовые ключи). По умолчанию он пишет в `v26/`. Пластины и сборка молекул читают `v2/`:

```bash
cd 00_source
PARTS_DIR=v2 sh pipeline/build_parts.sh
```

Новые элементы, связь N=O и универсальные связи этот скрипт не рендерит. Их задают отдельной командой `openscad`, как углерод выше.

Одинарная связь зависит от параметра `FLEX` (в файле по умолчанию `"spring"`):

```bash
openscad -D 'PRESET="toddler"' -D 'FLEX="spring"' -D 'PART="bond_CC"' -o v2/bond_CC.stl chem_constructor.scad
openscad -D 'PRESET="toddler"' -D 'FLEX="slots"'  -D 'PART="bond_CC"' -o v2/bond_CC_slots.stl chem_constructor.scad
```

`spring` — решётка-стент, `slots` — трубка с прорезями. Двойные и тройные связи от `FLEX` не зависят: они всегда сплошные, с гравировкой длины в Å. У длинной одинарной связи гравировка длины в текущем исходнике не ставится: она есть у короткого сплошного стержня и у двойных/тройных (`STATUS.md`).

Пример жёсткой двойной связи:

```bash
openscad -D 'PRESET="toddler"' -D 'PART="bond_CdC"' -o v2/bond_CdC.stl chem_constructor.scad
```

## 2. Молекула и пластина

Описание молекул — словарь `MOL` в `molecules.py`. Уже заданы вода, метан, этилен, аминокислоты, NaCl, H₂SO₄ и остальные из списков `V1` и `NEW` в `pipeline/make_main_plates.py`.

Когда все STL этой молекулы лежат в `00_source/v2/`:

```bash
cd 00_source
python3 pipeline/rebuild_v2.py H2O_water
```

Без аргументов скрипт собирает все молекулы из `V1` и `NEW`. Первый запуск долго считает посадку ключа в паз и пишет углы в `seat_cache_v2.json`. Повторный запуск берёт углы из кэша.

На выходе:

| Файл | Назначение |
|---|---|
| `00_source/asm_v2/H2O_water.glb` | сборка для просмотра (Blender, любой просмотрщик glTF) |
| `00_source/asm_v2/H2O_water.json` | список деталей и шаги сборки; строка `столкновения` — пересечения деталей |
| `02_molecules/H2O_water/README.md` | состав и порядок сборки |
| `02_molecules/H2O_water/plates/*.3mf` | детали разложены по цветам филамента на стол 256×256 мм |

В слайсер открывают `.3mf` из `plates/` или отдельный `.stl` из `v2/`.

### Своя молекула

Узел в `MOL` — `(имя_атома, {номер_паза: (кратность, дочерний_узел, паз_ребёнка)})`. Заглушка неподелённой пары азота — строка `"cap"`. Номера пазов — комментарий в начале `molecules.py` и раздел «Атомы» в `docs/KIT_v2_CATALOG.md`. Вода уже записана так: кислород, пазы 0 и 1 — водород.

После правки `molecules.py` недостающие STL кладут в `v2/` и запускают:

```bash
python3 pipeline/rebuild_v2.py имя_молекулы
```

## 3. Настройки слайсера

Принтер — Bambu Lab A1 (стол 256×256 мм). Те же параметры кратко приведены в `README.md`, раздел «Печать».

- **Атомы** — PLA, плоскостью с гравировкой вниз, слой 0,2 мм, 3 стенки, заполнение 15 %. Поддержки: Enable support, tree (auto), **Support critical regions only**. Островок есть в устье нижнего паза у углерода и азота.
- **Связи** — PETG. Гибкие spring и slots — только PETG. Печать **стоя**, без поддержек, brim 5–8 мм, 4 стенки, заполнение 100 %.
- Гибкие связи можно печатать лёжа (слои вдоль оси, прочнее на изгиб, нужны поддержки). Раскладка — пластина 06, описание в `docs/README_beta4.md`.
- Первой печатают призму с ключами (`PART="test_prism"` и ключи `test_key_*`) и проверяют щелчок и вращение. Зазоры подгоняются параметрами `peg_clr`, `peg_lip`, `peg_bump`, `snap_clr`, `tip_clr` в начале `chem_constructor.scad`, после чего детали рендерятся заново.

Дальше связь вставляется в паз до щелчка: одинарную — бугорками в бороздки, двойную и тройную — ввинчиванием по часовой стрелке. Порядок для конкретной молекулы пишет `rebuild_v2.py` в `02_molecules/<имя>/README.md`.

## Связанные документы

- `README.md` — крепление и краткие настройки печати
- `docs/KIT_v2_CATALOG.md` — состав набора, пазы, каталог молекул
- `docs/FLEX_BONDS.md` — устройство spring и slots
- `docs/README_beta4.md` — посадка ключей и печать гибких связей лёжа
- `STATUS.md` — что уже собрано и что ещё рендерится
