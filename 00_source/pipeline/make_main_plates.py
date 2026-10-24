# Пластины по цветам и bom.json. Запуск из 00_source, после rebuild_v2.py.
import json, os
from collections import Counter
from docs import plates

V1 = ["H2","CO2","CH4_methane","C2H2_acetylene","C2H4_ethylene","NH3_ammonia","H2O_water","C2H5OH_ethanol","CH3COOH_acetic_acid",
      "Gly_glycine","Ala_alanine","Val_valine","Ser_serine","Asn_asparagine","Thr_threonine","Leu_leucine","Asp_aspartic_acid","Lys_lysine",
      "methyl_acetate_ester","Gly-Gly_dipeptide"]
NEW = ["HF","HCl","F2","Cl2","NaCl","NaH","NaOH","KCl","KOH","MgCl2","MgO","CaCl2","CaOH2","H2S","SO2","H2SO4","PH3","H3PO4","CH3F","CH3Cl","NF3"]

def bom(names, folder):
    tot = Counter()
    for n in names:
        tot.update(json.load(open(f"asm_v2/{n}.json"))["parts"])
    os.makedirs(folder, exist_ok=True)
    files = plates(folder, tot, bed=256)
    json.dump({"molecules": names, "counts": dict(tot), "files": files}, open(os.path.join(folder, "bom.json"), "w"), ensure_ascii=False, indent=1)
    print(folder, sum(tot.values()), "деталей")
    return files

if __name__ == "__main__":
    bom(V1, os.path.join("..", "03_plates", "full_set_v1_molecules"))
    bom(NEW, os.path.join("..", "03_plates", "new_element_molecules"))
