# Сборка молекул v2 из STL в ./v2 и запись README, пластин и BOM.
# Запуск из 00_source:
#   python3 pipeline/rebuild_v2.py
#   python3 pipeline/rebuild_v2.py NaCl H2
# STL деталей кладёт OpenSCAD: openscad -D 'PART="bond_NaCl"' -o v2/bond_NaCl.stl chem_constructor.scad
import os, sys
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)
sys.path.insert(0, ROOT)
sys.path.insert(0, os.path.join(ROOT, "pipeline"))
from molecules import MOL
from assemble3 import assemble
from docs import molecule_doc
from make_main_plates import V1, NEW, bom

def main(names):
    missing = [n for n in names if n not in MOL]
    if missing:
        raise SystemExit("нет в molecules.py: " + ", ".join(missing))
    for n in names:
        assemble(n)
        molecule_doc(n)
    have = [n for n in V1 + NEW if os.path.exists(f"asm_v2/{n}.json")]
    if set(V1) <= set(have):
        bom(V1, os.path.join("..", "03_plates", "full_set_v1_molecules"))
    if set(NEW) <= set(have):
        bom(NEW, os.path.join("..", "03_plates", "new_element_molecules"))

if __name__ == "__main__":
    main(sys.argv[1:] or (V1 + NEW))
