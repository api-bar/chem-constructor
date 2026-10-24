"""Проверка плоскостности sp²-фрагментов с двойной связью.

Для каждой двойной связи, у которой на обоих концах есть заместители, собирает пару «атом–связь–атом»
по посадке из seat_cache_v2.json и печатает двугранные углы заместителей. Плоско = 0° или 180°.

Запуск из рабочей папки, где лежат v2/<деталь>.stl, chemlib.py и seat_cache_v2.json:
    python3 check_planar.py          # код возврата 1, если нарушена плоскость у обязательных связей (C=C, N=O)
Известно: C=N и N=N пока не плоские (см. docs/SP2_PLANARITY.md); они печатаются как предупреждение.
"""
import sys
import numpy as np
from chemlib import S, SOCK, bond_local, atom_on_bond, seat_bond, seat_atom

TOL = 1.0  # градусов


def dihedral(p0, p1, p2, p3):
    b0, b1, b2 = p0 - p1, p2 - p1, p3 - p2
    b1n = b1 / np.linalg.norm(b1)
    v, w = b0 - np.dot(b0, b1n) * b1n, b2 - np.dot(b2, b1n) * b1n
    return float(np.degrees(np.arctan2(np.dot(np.cross(b1n, v), w), np.dot(v, w))))


def check(name, a_el, a_sock, b_el, b_sock, bond, length_A, subs_a, subs_b):
    """Двугранные углы заместителей (пазы subs_a у первого атома, subs_b у второго) вдоль двойной связи."""
    L = length_A * S
    a = seat_bond(a_el, a_sock, bond, L, 1)
    x = seat_atom(bond, L, 2, b_el, b_sock)
    Mc = bond_local(a_el, a_sock, bond, L, 1, a) @ atom_on_bond(b_el, b_sock, L, 2, x)
    c2 = Mc[:3, 3]
    angles = [dihedral(SOCK[a_el][i] * 60, np.zeros(3), c2, c2 + Mc[:3, :3] @ SOCK[b_el][j] * 60)
              for i in subs_a for j in subs_b]
    dev = max(min(abs(d) % 180, 180 - abs(d) % 180) for d in angles)  # отклонение от 0°/180°
    return name, angles, dev


CASES = [  # (обязательно, параметры)
    (True,  ("C=C  H2C=CH2", "carbon", 4, "carbon", 4, "bond_CdC", 1.34, [0, 1], [0, 1])),
    (True,  ("N=O  HO-N=O ", "nitrogen", 5, "oxygen", 2, "bond_NdO", 1.15, [0], [0, 1])),
    (False, ("C=N  H2C=NH ", "carbon", 4, "nitrogen", 5, "bond_CdN", 1.28, [0, 1], [0, 1])),
    (False, ("N=N  HN=NH  ", "nitrogen", 5, "nitrogen", 5, "bond_NdN", 1.25, [0, 1], [0, 1])),
]

if __name__ == "__main__":
    bad = 0
    for strict, args in CASES:
        name, angles, dev = check(*args)
        ok = dev <= TOL
        mark = "OK " if ok else ("FAIL" if strict else "warn")
        print(f"{mark} {name}: двугранные {[round(d, 1) for d in angles]}, отклонение от плоскости {dev:.1f}°")
        bad += (not ok) and strict
    sys.exit(1 if bad else 0)
