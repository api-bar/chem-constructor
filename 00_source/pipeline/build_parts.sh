#!/bin/sh
# Печатные детали из chem_constructor.scad -> $PARTS_DIR (по умолчанию v26). Углерод считается ~5 мин, остальное быстрее.
OUT=${PARTS_DIR:-v26}; mkdir -p $OUT
for p in hydrogen oxygen nitrogen carbon lp_cap_B \
         bond_CC bond_CH bond_CO bond_CN bond_NH bond_OH bond_HH bond_OO bond_NN bond_CdC bond_CdO bond_CtC bond_CtN \
         test_key_A test_key_B test_key_C test_key_dbl test_prism; do
  openscad -D 'PRESET="toddler"' -D "PART=\"$p\"" -o $OUT/$p.stl chem_constructor.scad || echo "FAIL $p"
done
