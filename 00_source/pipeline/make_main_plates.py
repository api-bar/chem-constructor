# Пластины по цветам на весь основной набор + bom.json; тестеры копируются из папки с готовыми 3MF
import json, os, shutil
from collections import Counter
from docs import plates, PN
from safeio import write_text, may_write
main=["H2","CO2","CH4_methane","C2H2_acetylene","C2H4_ethylene","NH3_ammonia","H2O_water","C2H5OH_ethanol","CH3COOH_acetic_acid","Gly_glycine","Ala_alanine","Val_valine","Ser_serine","Asn_asparagine"]
tot=Counter()
for n in main: tot.update(json.load(open(f"asm3/{n}.json"))["parts"])
files=plates("pkg/03_plates_by_color/full_set_main_molecules", tot)
write_text("pkg/03_plates_by_color/full_set_main_molecules/bom.json", json.dumps({"molecules":main,"counts":dict(tot),"files":files},ensure_ascii=False,indent=1))
print(sum(tot.values()),"деталей"); [print(f) for f in files]
# тестеры
os.makedirs("pkg/04_tester",exist_ok=True)
for f in ["00_test_prism_and_keys.3mf","07_hex_7x_single_7x_double.3mf","06_hydrogens_and_single_bonds.3mf","04_carbon_all_hybridizations.3mf"]:
    p=os.path.join(os.environ.get("TESTER_SRC","../04_tester"),f)   # готовые 3MF-тестеры (скрипта для них нет)
    if os.path.exists(p) and may_write(f"pkg/04_tester/{f}"): shutil.copy(p,"pkg/04_tester/")
