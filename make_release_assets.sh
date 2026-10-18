#!/bin/sh
# Ассеты релиза v2.0-beta5. Запуск из корня ветки v2, когда рядом с README.md лежат папки с бинарниками
# (01_components … 07_v2_new_elements распакованы или лежат локально):
#   sh make_release_assets.sh
# Результат — шесть zip в ./release_assets (папка в git не попадает).
# Пути внутри архивов совпадают со структурой ветки: распаковка в корень клона даёт полную папку набора.
# Текст (*.md) и PNG в архивы не входят — они уже в git.
set -e
V=v2.0-beta5
mkdir -p release_assets
zip -qr release_assets/chem_constructor_${V}_components_stl.zip   01_components -i '*.stl'
zip -qr release_assets/chem_constructor_${V}_plates.zip           03_plates -x '*.DS_Store'
zip -qr release_assets/chem_constructor_${V}_tester.zip           04_tester 06_v2_test_plates -x '*.md' -x '*.DS_Store'
zip -qr release_assets/chem_constructor_${V}_molecules_models.zip 02_molecules -x '*.png' -x '*.DS_Store'
zip -qr release_assets/chem_constructor_${V}_flex_bonds.zip       05_flex_bonds -x '*.png' -x '*.DS_Store'
zip -qr release_assets/chem_constructor_${V}_new_elements.zip     07_v2_new_elements -x '*.md' -x '*.png' -x '*.DS_Store'
ls -la release_assets
