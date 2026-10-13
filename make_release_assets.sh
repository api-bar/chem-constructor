#!/bin/sh
# Запуск из корня распакованного полного набора (там, где есть 01_components … 04_tester):
#   sh make_release_assets.sh
# Создаёт 4 zip-ассета для релиза GitHub в папке ./release_assets
set -e
mkdir -p release_assets
zip -qr release_assets/chem_constructor_v1.0_components_stl.zip   01_components -i '*.stl'
zip -qr release_assets/chem_constructor_v1.0_plates_main_set.zip  03_plates_by_color
zip -qr release_assets/chem_constructor_v1.0_tester.zip           04_tester
zip -qr release_assets/chem_constructor_v1.0_molecules_models.zip 02_molecules -x '*.md' -x '*.png'
ls -la release_assets
