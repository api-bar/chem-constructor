# Описание молекул: узел = (атом, {паз: (кратность, дочерний_узел, паз_ребёнка) | "cap"})
# Пазы: углерод 0-3 одинарные (sp3), sp2 = 0,1 + двойной 4; sp(=,=) = 4,5; sp(-,≡) = 1 + тройной 6
#       кислород 0,1 одинарные, 2 двойной;  азот 0-2 одинарные, 3 заглушка, 4 тройной;  водород 0
H=("hydrogen",{})
def h(): return (1,H,0)
def CH3(): return ("carbon",{1:h(),2:h(),3:h()})          # метил, присоединяется пазом 0
def OH(): return ("oxygen",{1:h()})                         # гидроксил, присоединяется пазом 0
def NH2(): return ("nitrogen",{1:h(),2:h(),3:"cap"})        # аминогруппа, присоединяется пазом 0
def Od(): return ("oxygen",{})                              # карбонильный O, присоединяется двойным пазом 2
def COOH(): return ("carbon",{4:(2,Od(),2),1:(1,OH(),0)})   # карбоксил (sp2), присоединяется пазом 0
def CONH2(): return ("carbon",{4:(2,Od(),2),1:(1,NH2(),0)}) # амид, присоединяется пазом 0
def CH2(r): return ("carbon",{1:r,2:h(),3:h()})             # -CH2-R, присоединяется пазом 0
def aa(R, cfg="L"):                                         # аминокислота: Cα {N, COOH, R, H}; R — (кратность, узел, паз) или h()
    return ("carbon",{0:(1,NH2(),0),1:(1,COOH(),0),2:R,3:h()})
MOL={
 "H2":            ("hydrogen",{0:(1,H,0)}),
 "CO2":           ("carbon",{4:(2,Od(),2),5:(2,Od(),2)}),
 "CH4_methane":   ("carbon",{0:h(),1:h(),2:h(),3:h()}),
 "C2H2_acetylene":("carbon",{6:(3,("carbon",{1:h()}),6),1:h()}),
 "C2H4_ethylene": ("carbon",{4:(2,("carbon",{0:h(),1:h()}),4),0:h(),1:h()}),
 "NH3_ammonia":   ("nitrogen",{0:h(),1:h(),2:h(),3:"cap"}),
 "H2O_water":     ("oxygen",{0:h(),1:h()}),
 "C2H5OH_ethanol":("carbon",{0:(1,CH2((1,OH(),0)),0),1:h(),2:h(),3:h()}),
 "CH3COOH_acetic_acid": ("carbon",{0:(1,COOH(),0),1:h(),2:h(),3:h()}),
 "Gly_glycine":   aa(h()),
 "Ala_alanine":   aa((1,CH3(),0)),
 "Val_valine":    aa((1,("carbon",{1:(1,CH3(),0),2:(1,CH3(),0),3:h()}),0)),
 "Ser_serine":    aa((1,CH2((1,OH(),0)),0)),
 "Asn_asparagine":aa((1,CH2((1,CONH2(),0)),0)),
 "methyl_acetate_ester": ("carbon",{0:(1,("carbon",{4:(2,Od(),2),1:(1,("oxygen",{1:(1,CH3(),0)}),0)}),0),1:h(),2:h(),3:h()}),
 "Gly-Gly_dipeptide": ("carbon",{0:(1,NH2(),0),1:(1,("carbon",{4:(2,Od(),2),1:(1,("nitrogen",{1:h(),2:(1,("carbon",{1:(1,COOH(),0),2:h(),3:h()}),0),3:"cap"}),0)}),0),2:h(),3:h()}),
}
CHIRAL={"Ala_alanine","Val_valine","Ser_serine","Asn_asparagine"}   # L = S у всех этих
MOL.update({
 "Thr_threonine": aa((1,("carbon",{1:(1,OH(),0),2:(1,CH3(),0),3:h()}),0)),
 "Leu_leucine":   aa((1,CH2((1,("carbon",{1:(1,CH3(),0),2:(1,CH3(),0),3:h()}),0)),0)),
 "Asp_aspartic_acid": aa((1,CH2((1,COOH(),0)),0)),
 "Lys_lysine":    aa((1,CH2((1,CH2((1,CH2((1,CH2((1,NH2(),0)),0)),0)),0)),0)),
})
CHIRAL|={"Thr_threonine","Leu_leucine","Asp_aspartic_acid","Lys_lysine"}
# Новые элементы. Пазы: F,Cl,Na,K,H — 0; Mg,Ca — 0 и 1 (180°); S — 0,1 двойные, 2,3 одинарные; P — 0 двойной, 1,2,3 одинарные.
def X(name): return (name,{})
MOL.update({
 "HF": ("hydrogen",{0:(1,X("fluorine"),0)}),
 "HCl": ("hydrogen",{0:(1,X("chlorine"),0)}),
 "F2": ("fluorine",{0:(1,X("fluorine"),0)}),
 "Cl2": ("chlorine",{0:(1,X("chlorine"),0)}),
 "NaCl": ("sodium",{0:(1,X("chlorine"),0)}),
 "NaH": ("sodium",{0:h()}),
 "NaOH": ("sodium",{0:(1,OH(),0)}),
 "KCl": ("potassium",{0:(1,X("chlorine"),0)}),
 "KOH": ("potassium",{0:(1,OH(),0)}),
 "MgCl2": ("magnesium",{0:(1,X("chlorine"),0),1:(1,X("chlorine"),0)}),
 "MgO": ("magnesium",{0:(1,X("oxygen"),0)}),
 "CaCl2": ("calcium",{0:(1,X("chlorine"),0),1:(1,X("chlorine"),0)}),
 "CaOH2": ("calcium",{0:(1,OH(),0),1:(1,OH(),0)}),
 "H2S": ("sulfur",{2:h(),3:h()}),
 "SO2": ("sulfur",{0:(2,Od(),2),1:(2,Od(),2)}),
 "H2SO4": ("sulfur",{0:(2,Od(),2),1:(2,Od(),2),2:(1,OH(),0),3:(1,OH(),0)}),
 "PH3": ("phosphorus",{1:h(),2:h(),3:h()}),
 "H3PO4": ("phosphorus",{0:(2,Od(),2),1:(1,OH(),0),2:(1,OH(),0),3:(1,OH(),0)}),
 "CH3F": ("carbon",{0:(1,X("fluorine"),0),1:h(),2:h(),3:h()}),
 "CH3Cl": ("carbon",{0:(1,X("chlorine"),0),1:h(),2:h(),3:h()}),
 "NF3": ("nitrogen",{0:(1,X("fluorine"),0),1:(1,X("fluorine"),0),2:(1,X("fluorine"),0),3:"cap"}),
})
