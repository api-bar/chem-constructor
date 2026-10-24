#!/bin/sh
# Архивы комплекта v2.0-beta5 для площадки продажи (не для GitHub: бинарники в репозиторий и в GitHub Release не выкладываются).
# Запуск из корня репозитория, когда рядом с README.md лежат папки с бинарниками (01_components … 07_v2_new_elements):
#   sh make_kit_archives.sh
# Результат — шесть zip в ./dist (папка в git не попадает). Пути внутри архивов совпадают со структурой набора:
# распаковка всех архивов в одну папку с объединением даёт полную папку набора. Текст (*.md) и PNG уже в git, в архивы не входят.
set -e
V=v2.0-beta5
mkdir -p dist
zip -qr dist/chem_constructor_${V}_components_stl.zip   01_components -i '*.stl'
zip -qr dist/chem_constructor_${V}_plates.zip           03_plates -x '*.DS_Store'
zip -qr dist/chem_constructor_${V}_tester.zip           04_tester 06_v2_test_plates -x '*.md' -x '*.DS_Store'
zip -qr dist/chem_constructor_${V}_molecules_models.zip 02_molecules -x '*.png' -x '*.DS_Store'
zip -qr dist/chem_constructor_${V}_flex_bonds.zip       05_flex_bonds -x '*.png' -x '*.DS_Store'
zip -qr dist/chem_constructor_${V}_new_elements.zip     07_v2_new_elements -x '*.md' -x '*.png' -x '*.DS_Store'
ls -la dist
