// =====================================================================
//  Химический конструктор — прототип v0.1
//  Атомы с байонетными пазами (плоский ключ, поворот 90°) + упругие стержни-связи
//  Bambu Lab A1, PETG для стержней, PLA/PETG для атомов
//
//  Использование:
//    openscad -D 'PART="carbon"' -o carbon.stl chem_constructor.scad
//  PART: carbon | oxygen | hydrogen | lp_cap | bond_CC | bond_CO | bond_CH | bond_OH
//        | fit_test (пластина с пазами всех классов для подбора допусков) | assembly
// =====================================================================

PART = "assembly";
LAM = 40;                 // угол подъёма винтовой линии ключей, град. 40° — предел вертикальной печати без поддержек
                          // (смещение кромки 0.2/(0.85*tan(LAM)) = 0.28 мм на слой). Фиксацию даёт коническая щель, не винт.
PRESET = "toddler";
HAND = -1;   // -1: правый винт (буравчик) — ввинчивать по часовой, глядя на атом; +1: против часовой
function lead(w, lam = LAM) = 2*PI*(0.85*w/2)*tan(lam);   // ход винта, мм на оборот
function twist_for(w, len, lam = LAM) = 360*len/lead(w, lam);   // закрутка на длине ключа       // "adult" (40 мм/Å, мелкие детали, 5+) | "toddler" (90 мм/Å, 1–3 года, EN 71)

$fn = 72;

TD = (PRESET == "toddler");

// ---------- Масштаб ----------
SCALE = TD ? 90 : 40;       // мм на 1 Å

// ---------- Допуски и замок ----------
clr      = TD ? 0.30 : 0.25;   // зазор на сторону для FDM (подбирать по fit_test)
wall     = TD ? 4.0  : 2.5;    // толщина губы, за которую заходит ключ
key_len  = TD ? 9.0  : 5.0;    // длина витой лопасти одинарного ключа внутри атома
// закрутка одинарных ключей считается по классу: ctw(c)
neck_d   = TD ? 7.0  : 3.5;    // диаметр шейки, проходящей сквозь губу
lip_chamfer = TD ? 1.0 : 0.6;  // фаска входа паза
snap_clr  = TD ? 0.45 : 0.3;   // зазор витой щели
tip_clr   = TD ? 0.15 : 0.10;  // целевой зазор по ширине в губе при полностью вставленном ключе (клин конусного ключа)
slot_tip_clr = TD ? 0.25 : 0.18;  // зазор щели у дна: щель коническая (клин в глубине), у входа snap_clr
// Защёлка «бугорок–лунка» У ОСНОВАНИЯ: бугорок на плоской стороне лопасти рядом с манжетой, лунка в губе паза
// (губа — наружная стенка, её не режут соседние пазы). Податливость даёт наклон связи / изгиб упругого стержня:
// зазор кончика 0.45 на плече лопасти + зазор губы 0.3. Высота бугорка ~0.8.
det_h   = TD ? 0.9 : 0.55;     // высота бугорка над плоскостью лопасти
det_d   = TD ? 3.6 : 2.4;      // диаметр сферы бугорка
det_pos = TD ? 4.5 : 2.8;      // глубина центра бугорка/лунки от поверхности атома (внутри губы)
det_gap = 0.25;                // зазор лунки

// ---------- Двойная связь: массивный витой ключ (класс A, O=O) ----------
dbl_w     = TD ? 28 : 14;      // двойная 28×7
dbl_t     = TD ? 7 : 3.5;
dbl_len   = TD ? 18 : 9;       // длина лопасти внутри шара
dbl_twist = HAND * twist_for(dbl_w, 18, LAM);
dbl_neck  = TD ? 12 : 6;       // шейка сквозь губу
dbl_clr   = snap_clr;
L_OO = 1.21;                   // O=O, Å
L_HH = 0.74;                   // H–H, Å
ANG_H2O = 104.5;               // угол H–O–H

// ---------- Стержни ----------
rod_d        = TD ? 12.0 : 5.0;
rod_neck_d   = TD ? 9.0  : 3.6;
rod_neck_frac= 0.45;
rod_min_for_neck = TD ? 40 : 20;
rod_flat     = 0;              // плоскость снизу стержня — только для печати лёжа; связи печатаем стоя

// ---------- Атомы ----------
flat_cut = TD ? 3.0 : 2.0;
USE_COV_RADII = false;      // true: радиус шара = K_COV × ковалентный радиус -> видимые стержни пропорциональны реальным длинам
K_COV = 0.45;
RCOV = [["C",0.76],["O",0.66],["N",0.71],["H",0.31]];   // Å
R_C = USE_COV_RADII ? K_COV*0.76*SCALE : (TD ? 28 : 15);
R_O = USE_COV_RADII ? K_COV*0.66*SCALE : (TD ? 26 : 14);
R_N = USE_COV_RADII ? K_COV*0.71*SCALE : (TD ? 26 : 14);
R_H = USE_COV_RADII ? K_COV*0.31*SCALE : (TD ? 20 : 10);
lp_bump = false;            // неподелённые пары — всегда отдельные заглушки (для малышей вклеиваются)
glue_groove = true;         // кольцевая канавка на шейке ключа — резервуар под клей
groove_w = TD ? 1.5 : 1.0;  groove_d = TD ? 0.35 : 0.25;

// ---------- Данные элементов: [символ, Z (заряд ядра), атомная масса, валентность] ----------
EL = [ ["H", 1, "1.008", "I"], ["C", 6, "12.011", "IV"], ["N", 7, "14.007", "III"], ["O", 8, "15.999", "II"] ];
function el(sym) = [ for (e = EL) if (e[0] == sym) e ][0];

// ---------- Гравировка ----------
FONT = "DejaVu Sans:style=Bold";
eng_depth = TD ? 1.0 : 0.8;          // глубина букв
spot_depth = TD ? 3.0 : 1.5;         // глубина плоской площадки под надпись на сфере
sym_size  = TD ? 9 : 5.5;            // высота символа элемента
sub_size  = TD ? 3.8 : 2.6;          // мелкий текст (валентность, масса, номер) — не ниже ~2.5 мм для сопла 0.4
label_flat = TD ? 4.5 : 2.2;         // глубина плоской площадки под расширенную гравировку на дне атома
sup_size  = TD ? 4.5 : 2.8;            // заряд справа сверху (для ионов)
LABEL_DIR = [cos(60)*cos(30), sin(60)*cos(30), sin(30)];  // между гнёздами, смотрит вверх — печатается чисто

// ---------- Классы электроотрицательности: [имя, ширина лезвия, толщина лезвия] ----------
// Перекрёстные размеры: шире -> тоньше, чтобы чужой ключ не входил ни в один паз
// Замок: за губу заходит (w - t)/2 - clr; у класса C это ~3 мм в toddler
// Витой ключ: класс кодируется перекрёстными размерами лопасти (шире -> тоньше); замок — лапки на кончике
// 4-й элемент — угол подъёма винтовой линии для класса (меньше -> держит сильнее). B держал слабее — ему 16°.
// v0.17: профиль паза кодирует КРАТНОСТЬ связи, а не класс электроотрицательности.
// Все одинарные — один профиль SGL (A=B=C), двойная — dbl_w×dbl_t, тройная — TRP (зарезервировано).
SGL_W = TD ? 18 : 9;  SGL_T = TD ? 6 : 3.2;      // одинарная 18×6
TRP_W = TD ? 26 : 13; TRP_T = TD ? 10 : 5;   // тройная 26×10
trp_len   = TD ? 22 : 11;
trp_twist = HAND * twist_for(TRP_W, trp_len, LAM);
L_NN = 1.10;                   // N≡N, Å
L_CdC = 1.34; L_CdO = 1.21; L_CtC = 1.20; L_CtN = 1.16;   // C=C, C=O, C≡C, C≡N, Å
CLASS = [ ["A", SGL_W, SGL_T, LAM], ["B", SGL_W, SGL_T, LAM], ["C", SGL_W, SGL_T, LAM] ];
// Самотормозящий винт: угол подъёма винтовой линии lam на эффективном радиусе 0.85*w/2 меньше угла трения
function ctw(c) = HAND * twist_for(cw(c), key_len, CLASS[c][3]);
A = 0; B = 1; C = 2;
function cw(c) = CLASS[c][1];
function ct(c) = CLASS[c][2];

// ---------- Длины связей, Å ----------
L_CC = 1.54; L_CO = 1.43; L_CH = 1.09; L_OH = 0.96; L_NH = 1.01; L_CN = 1.47;

// ---------- Тетраэдрические направления (одно гнездо вверх) ----------
s3 = sqrt(8)/3;
TET = [ [0,0,1],
        [s3, 0, -1/3],
        [s3*cos(120), s3*sin(120), -1/3],
        [s3*cos(240), s3*sin(240), -1/3] ];

// =====================================================================
//  Примитивы
// =====================================================================

// Стадион: прямоугольник w×t со скруглёнными концами (радиус t/2).
// Крайние точки лезвия на радиусе w/2 -> плавное вращение в круглой полости.
module stadium(w, t) {
    hull() {
        translate([ (w-t)/2, 0]) circle(d = t);
        translate([-(w-t)/2, 0]) circle(d = t);
    }
}

// Ориентировать children() с оси +Z на вектор v
module orient(v) {
    n = norm(v);
    polar = acos(v[2]/n);
    az = atan2(v[1], v[0]);
    rotate([0, polar, az]) children();
}

// =====================================================================
//  Витой ключ и винтовой паз — единый механизм для всех связей
//  Лопасть (канонический кадр): кончик в z=0, основание в z=len (+extra)
// =====================================================================
module tw_blade(w, t, len, twist, ew = 0, et = 0, extra = 0, ew_top = -1, et_top = -1) {
    h = len + extra;
    // сечение у кончика (z=0): w+ew × t+et; у входа (z=h): w+ew_top × t+et_top (если заданы) — коническая щель
    // ВАЖНО: scale в linear_extrude с twist действует в глобальных осях после поворота, поэтому масштаб — только равномерный
    sc = ew_top < 0 ? 1 : (w + ew_top)/(w + ew);
    linear_extrude(height = h, twist = twist * h / len, slices = max(12, round(h*2)), scale = sc)
        stadium(w + ew, t + et);
}
// Ключ: 0 — поверхность шара, уходит внутрь по +Z. Шейка сквозь губу (+ канавка под клей), витая лопасть,
// кончик расщеплён на две лапки с витым утолщением -> защёлка в донной камере.
module tw_key_end(w, t, len, twist, neck, flen = 0, gap = 0, lip = 0, r_atom = 0) {
    // Лопасть непрерывна от поверхности шара (z=0) до кончика (z = wall+clr+len), закрутка та же по всей длине.
    // КОНУСНЫЙ КЛЮЧ: у кончика номинальное сечение, к основанию шире на 2*(snap_clr - tip_clr) -> клин в губе.
    // Манжета КРУГЛАЯ: конус 45° от стержня до Ø(w+g+1), торец вогнут по сфере атома (r_atom) — закрывает
    // и основание лопасти, и устье щели; снаружи видны только стержень и круглый раструб.
    L = wall + clr + len;  g = 2*(snap_clr - tip_clr);
    dc = w + g + 0.1;  hc = (dc - rod_d)/2;   // раструб по ширине лопасти (+0.1, чтобы грани не совпадали — CGAL)
    translate([0, 0, L]) rotate([180, 0, 0]) {
        tw_blade(w, t, len, twist, 0, 0, wall + clr + 0.03, g, g);
        // бугорок защёлки: в локальной системе ЗАКРУЧЕННОЙ лопасти на своей высоте (угол сечения = -twist*z'/len)
        zb = L - det_pos;
        translate([0, 0, zb]) rotate(-twist * zb / len)
            translate([0, (t + g*zb/L)/2 - (det_d/2 - det_h), 0]) sphere(d = det_d);

    }
    rb = dc/2;
    zmax = r_atom > 0 ? r_atom - sqrt(r_atom*r_atom - rb*rb) + 0.05 : 0;  // кромка раструба лежит на сфере (заглубление 0.05)
    difference() {
        union() {
            translate([0, 0, -hc]) cylinder(d1 = rod_d, d2 = dc, h = hc + 0.01);
            if (zmax > 0) cylinder(d = dc, h = zmax);
        }
        if (r_atom > 0) translate([0, 0, r_atom]) sphere(r = r_atom);   // тот же $fn, что у шара атома
    }
}
// Паз (вычитаемая геометрия), ось +Z, r — радиус шара. phase — поворот витой щели (для блокировок)
module tw_socket(w, t, len, twist, neck, r, phase = 0) {
    tip = r - wall - clr - len;
    // равномерная щель с зазором snap_clr; клин обеспечивает конусный ключ (см. tw_key_end)
    // коническая щель: у дна зазор slot_tip_clr, у входа snap_clr (равномерный масштаб — см. tw_blade)
    translate([0, 0, tip - tip_clr]) rotate(phase)
        tw_blade(w, t, len, twist, 2*slot_tip_clr, 2*slot_tip_clr, wall + clr + 4 + tip_clr, 2*snap_clr, 2*snap_clr);
    // зенковка устья по форме щели (+0.6 мм, 1 мм), повёрнута на угол щели у поверхности — прячется под раструб
    mouth_ang = phase - twist * (len + wall + clr + 2*tip_clr) / len;
    translate([0, 0, r - 1]) linear_extrude(1 + 2, scale = 1.06) rotate(mouth_ang) stadium(w + 2*snap_clr + 0.6, t + 2*snap_clr + 0.6);
    // лунка защёлки: напротив бугорка при полностью вставленном ключе (кончик ключа на z = tip)
    // лунка: та же высота над кончиком, что у бугорка, повёрнута на угол щели на этой высоте
    zr = (wall + clr + len) - det_pos + tip_clr;                     // высота над началом витой щели
    hs = wall + clr + 4 + tip_clr + len;                              // полная высота витой щели
    cz = slot_tip_clr + (snap_clr - slot_tip_clr) * zr / hs;          // зазор щели на этой высоте (коническая)
    translate([0, 0, tip - tip_clr]) translate([0, 0, zr]) rotate(phase - twist * zr / len)
        translate([0, t/2 + cz - (det_d/2 - det_h), 0]) sphere(d = det_d + 2*det_gap);
    // зеркальная лунка на той же глубине в противоположной стенке: ключ садится любой стороной
    translate([0, 0, tip - tip_clr]) translate([0, 0, zr]) rotate(phase - twist * zr / len)
        translate([0, -(t/2 + cz - (det_d/2 - det_h)), 0]) sphere(d = det_d + 2*det_gap);
}

// Подпись связи на стержне (вдоль оси, на боку Ø rod_d), глубина eng_depth
module rod_label(x1, x2, lbl, sz = 4.5) {
    // стержень в середине утонён до rod_neck_d (если длиннее rod_min_for_neck) — гравируем на радиусе утонения
    rr = (x2 - x1 + 4 + 2*(x2 - x1 + 4 > 0 ? 0 : 0)) > 0 ? ((x2 - x1) > rod_min_for_neck*rod_neck_frac - 4 ? rod_neck_d/2 : rod_d/2) : rod_d/2;
    if (lbl != "") translate([(x1 + x2)/2, 0, rr - eng_depth]) linear_extrude(eng_depth + 0.5)
        text(lbl, size = sz, font = FONT, halign = "center", valign = "center");
}
// ---- одинарные (по классам) ----
function hc_of(w) = (w + 2*(snap_clr - tip_clr) + 1 - rod_d)/2;   // высота круглой манжеты (конус 45° до Ø w+g+1)
module socket(c, r)  tw_socket(cw(c), ct(c), key_len, ctw(c), neck_d, r);
module key_end(c, r_atom = 0)    tw_key_end(cw(c), ct(c), key_len, ctw(c), neck_d, 0, 0, 0, r_atom);

// ---- двойная (класс A, O=O) ----
module dbl_blade(ew = 0, et = 0, extra = 0) tw_blade(dbl_w, dbl_t, dbl_len, dbl_twist, ew, et, extra);
module dbl_key_end(r_atom = 0) tw_key_end(dbl_w, dbl_t, dbl_len, dbl_twist, dbl_neck, 0, 0, 0, r_atom);
module trp_key_end(r_atom = 0) tw_key_end(TRP_W, TRP_T, trp_len, trp_twist, dbl_neck, 0, 0, 0, r_atom);
module trp_socket(r, phase = 0) tw_socket(TRP_W, TRP_T, trp_len, trp_twist, dbl_neck, r, phase);
function single_cav_z(r) = (r - wall - clr - key_len/2) * cos(ANG_H2O/2);
module dbl_socket(r, extra = 0) {
    tip = r - wall - clr - dbl_len;
    k = dbl_twist / dbl_len;
    tw_socket(dbl_w, dbl_t, dbl_len, dbl_twist, dbl_neck, r, k * (single_cav_z(r) - tip) + extra);
}

// =====================================================================
//  Гравировка: плоская площадка на сфере + символ, Z, масса, валентность, заряд (вычитаемая геометрия)
// =====================================================================
module label(r, dir, sym, valence = "", charge = "", depth = spot_depth, znum = "", mass = "") {
    chord = sqrt(2*r*depth - depth*depth);
    orient(dir) {
        translate([0, 0, r - depth]) cylinder(r = chord, h = depth + 2);
        translate([0, 0, r - depth - eng_depth]) linear_extrude(eng_depth + 0.01) {
            y0 = sym_size*0.05;
            text_c(sym, sym_size, [0, y0]);
            if (znum != "")    text_l(str(znum), sub_size, [-chord*0.66, y0 + sym_size*0.5]);
            if (charge != "")  text_r(charge,    sup_size, [ chord*0.66, y0 + sym_size*0.5]);
            if (valence != "") text_c(valence,   sub_size, [0, y0 - sub_size*1.35]);
            if (mass != "")    text_c(mass,      sub_size*0.9, [0, y0 - sub_size*2.7]);
        }
    }
}
module text_c(s, sz, p) translate(p) text(s, size = sz, font = FONT, halign = "center", valign = "baseline");
module text_l(s, sz, p) translate(p) text(s, size = sz, font = FONT, halign = "left",   valign = "baseline");
module text_r(s, sz, p) translate(p) text(s, size = sz, font = FONT, halign = "right",  valign = "baseline");
module el_label(r, sym, charge = "") { e = el(sym); label(r, [0,0,-1], sym, e[3], charge, label_flat, e[1], e[2]); }

// =====================================================================
//  Атом
//  sockets: список [класс, направление]
// =====================================================================
module atom(r, sockets, lab = []) {
    difference() {
        sphere(r);
        for (s = sockets) orient(s[1]) socket(s[0], r);
        if (len(lab) > 0) label(r, lab[0], lab[1], lab[2], lab[3], lab[4], len(lab) > 5 ? lab[5] : "", len(lab) > 6 ? lab[6] : "");
        // плоскость снизу для стола (глубже, если на дне расширенная подпись)
        fc = (len(lab) > 0 && lab[0] == [0,0,-1]) ? lab[4] : flat_cut;
        translate([0, 0, -r - 50 + fc]) cube(100, center = true);
    }
}

// =====================================================================
//  Заглушка неподелённой пары
// =====================================================================
module lone_pair_cap(c) {
    // ключ вниз (-Z), шапка — hull от сечения основания лопасти к приплюснутой сфере: печать без нависаний
    g = 2*(snap_clr - tip_clr);  L = wall + clr + key_len;
    rotate([180, 0, 0]) key_end(c, R_N);
    hull() {
        linear_extrude(0.02) rotate(-ctw(c) * L / key_len) stadium(cw(c) + g, ct(c) + g);   // угол основания как у лопасти
        translate([0, 0, 6]) scale([1, 1, 0.5]) sphere(d = 18);
    }
}

// =====================================================================
//  Связь (стержень с двумя ключами). Атом 1 в x=0, атом 2 в x=L.
//  Печатается лёжа вдоль X, лезвия плашмя.
// =====================================================================
module bond(L_A, c1, r1, c2, r2, lbl = "") {
    L  = L_A * SCALE;
    x1 = r1;  x2 = L - r2;
    rod_len = x2 - x1;
    assert(rod_len > 6, "Стержень слишком короткий: уменьшите радиусы атомов или увеличьте SCALE");

    difference() {
        union() {
            translate([x1 + hc_of(cw(c1)) - 0.5, 0, 0]) rotate([0, 90, 0]) cylinder(d = rod_d, h = rod_len - hc_of(cw(c1)) - hc_of(cw(c2)) + 1);
            translate([x1, 0, 0]) rotate([0, -90, 0]) key_end(c1, r1);
            translate([x2, 0, 0]) rotate([0,  90, 0]) key_end(c2, r2);
        }
        // утонение в середине для упругости
        if (rod_len > rod_min_for_neck) {
            nl = rod_len * rod_neck_frac;
            translate([x1 + (rod_len - nl)/2, 0, 0]) rotate([0, 90, 0])
                difference() {
                    cylinder(d = rod_d + 2, h = nl);
                    // утонение с переходами 45° (без ступенек — печать стоя без нависаний)
                    ch = (rod_d - rod_neck_d)/2;
                    translate([0,0,-1]) cylinder(d = rod_neck_d, h = nl + 2);
                    cylinder(d1 = rod_d + 0.02, d2 = rod_neck_d, h = ch);
                    translate([0,0,nl - ch]) cylinder(d1 = rod_neck_d, d2 = rod_d + 0.02, h = ch);
                }
        }
        rod_label(x1 + hc_of(cw(c1)) + 2, x2 - hc_of(cw(c2)) - 2, lbl);
        // плоскость снизу для стола (только участок стержня между манжетами)
        if (rod_flat > 0) { hc1 = (cw(c1) + 2*(snap_clr-tip_clr) + 2 - rod_d)/2; hc2 = (cw(c2) + 2*(snap_clr-tip_clr) + 2 - rod_d)/2;
            translate([x1 + hc1, -10, -rod_d/2 - 10 + rod_flat]) cube([rod_len - hc1 - hc2, 20, 10]); }
    }
}

// =====================================================================
//  Неразъёмные компоненты (toddler): руки-водороды и функциональные группы
// =====================================================================
// Водород, сросшийся с центральным атомом: стержень + шар H на направлении +Z от центра (r_center — радиус центрального атома)
module fused_h(r_center, L_A) {
    L = L_A * SCALE;
    translate([0, 0, r_center - 2]) cylinder(d = rod_d, h = L - R_H - r_center + 4);
    translate([0, 0, L]) difference() { sphere(R_H); label(R_H, [0,0,1], "H", "", "", spot_depth); }
}
// Плоскость снизу по самой нижней точке детали (для стола)
module with_flat(zmin) {
    difference() { children(); translate([0, 0, zmin + flat_cut - 50]) cube(100, center = true); }
}
// Группа: центральный атом радиуса r, класса cx; free_dirs — гнёзда, arm_dirs — сросшиеся H (длина L_H_A), bump_dirs — неподелённые пары
module group(r, cx, free_dirs, arm_dirs, bump_dirs, L_H_A, sym = "", val = "") {
    zmin = min([ -r, for (d = arm_dirs) d[2]*L_H_A*SCALE - R_H ]);
    with_flat(zmin) union() {
        atom(r, [ for (d = free_dirs) [cx, d] ], [LABEL_DIR, sym, val, "", spot_depth]);
        for (d = arm_dirs)  orient(d) fused_h(r, L_H_A);
        for (d = bump_dirs) orient(d) translate([0, 0, r - 3]) scale([1, 1, 0.55]) sphere(d = r * 0.7);
    }
}
// Рука-водород с ключом класса c на конце: шар H внизу (на столе), стержень вверх, ключ на верхнем конце.
// Печатать стоя. r_partner — радиус атома, к которому она крепится.
module h_arm(c, L_A, r_partner) {
    L = L_A * SCALE;
    with_flat(-R_H) union() {
        difference() { sphere(R_H); label(R_H, [0,0,-1], "H", "I", "", flat_cut); }
        translate([0, 0, R_H - 2]) cylinder(d = rod_d, h = L - r_partner - R_H + 2);
        translate([0, 0, L - r_partner]) key_end(c);
    }
}

module group_CH3() group(R_C, C, [TET[0]],          [TET[1], TET[2], TET[3]], [],       L_CH, "C", "IV");
module group_CH2() group(R_C, C, [TET[0], TET[1]],  [TET[2], TET[3]],         [],       L_CH, "C", "IV");
module group_OH()  group(R_O, A, [TET[0]],          [TET[1]],                 [TET[2], TET[3]], L_OH, "O", "II");
module group_NH2() group(R_N, B, [TET[0]],          [TET[1], TET[2]],         [TET[3]], L_NH, "N", "III");
module h_arm_C() h_arm(C, L_CH, R_C);   // H–C  (неполярная)
module h_arm_O() h_arm(A, L_OH, R_O);   // H–O  (полярная)
module h_arm_N() h_arm(B, L_NH, R_N);   // H–N  (полярная)

// =====================================================================
//  Пластина для подбора допусков: пазы всех классов + три ключа
// =====================================================================
module fit_test() {
    Hb = wall + clr + key_len + 4;
    difference() {
        translate([-16, -16, 0]) cube([96, 32, Hb]);
        for (i = [0:2]) translate([i*32, 0, 0]) socket(i, Hb);
    }
    // ключи шляпкой вниз: печать без поддержек, лопасть вверх
    for (i = [0:2]) translate([i*32, 34, 0]) { cylinder(d = 24, h = 5); translate([0,0,5]) key_end(i); }
}

// Тест двойного паза: блок с винтовым пазом + витой ключ с ручкой
module fit_test_dbl() {
    Hb = wall + clr + dbl_len + 4;
    difference() { translate([-20, -20, 0]) cube([40, 40, Hb]); dbl_socket(Hb); }
    translate([50, 0, 0]) { cylinder(d = 30, h = 5); translate([0,0,5]) dbl_key_end(); }   // шляпкой вниз
}

// ---------- Тестовые ключи с крылатой ручкой (как барашек) и буквой класса ----------
module wing_handle(len, wd, h, lbl) {
    difference() {
        hull() { for (s = [-1, 1]) translate([s*(len - wd)/2, 0, 0]) cylinder(d = wd, h = h); }
        // буква на обоих концах верхней грани ручки
        for (s = [-1, 1]) translate([s*(len/2 - wd*0.55), 0, h - eng_depth])
            linear_extrude(eng_depth + 0.01) text(lbl, size = wd*0.6, font = FONT, halign = "center", valign = "center");
        // насечки для пальцев по бокам
        for (s = [-1, 1]) for (i = [-1, 0, 1]) translate([i*wd*0.9, s*wd/2, h/2]) rotate([0, 90, 0]) cylinder(d = 1.6, h = wd*0.6, center = true);
    }
}
module test_key(c)  { wing_handle(TD ? 46 : 26, TD ? 12 : 7, TD ? 8 : 5, CLASS[c][0]); translate([0, 0, TD ? 8 : 5]) key_end(c); }
module test_key_dbl() { hh = (dbl_w + 2 - rod_d)/2 + 1; wing_handle(TD ? 56 : 32, TD ? 14 : 8, hh, "="); translate([0, 0, hh]) dbl_key_end(); }   // ручка выше манжеты

// ---------- Минимальный тест-блок: стаканы с пазами на общем основании ----------
module test_cups() {
    wallc = 3; base_t = 5;
    items = [ ["A", 0], ["B", 1], ["C", 2], ["=", -1] ];   // -1 = двойной
    function cup_d(i) = (i < 0 ? dbl_w : cw(i)) + 2*snap_clr + 2*wallc + 2;
    function cup_h(i) = wall + clr + (i < 0 ? dbl_len : key_len) + snap_clr + 3;
    pitch = TD ? 34 : 18;  x0 = -1.5*pitch;
    difference() {
        union() {
            translate([x0 - cup_d(-1)/2 - 2, -cup_d(-1)/2 - (TD ? 14 : 8), 0]) cube([3*pitch + cup_d(-1) + 4, cup_d(-1) + (TD ? 14 : 8), base_t]);
            for (k = [0:3]) translate([x0 + k*pitch, 0, 0]) cylinder(d = cup_d(items[k][1]), h = cup_h(items[k][1]));
        }
        for (k = [0:3]) translate([x0 + k*pitch, 0, 0]) let(i = items[k][1]) { if (i < 0) dbl_socket(cup_h(i)); else socket(i, cup_h(i)); }
        // буквы на основании перед стаканами
        for (k = [0:3]) translate([x0 + k*pitch, -cup_d(-1)/2 - (TD ? 7 : 4), base_t - eng_depth])
            linear_extrude(eng_depth + 0.01) text(items[k][0], size = TD ? 8 : 4.5, font = FONT, halign = "center", valign = "center");
    }
}

// ---------- Минимальная призма: сверху двойной паз, на боках A, B, C, C; пазы пересекаются внутри (как в атомах) ----------
prism_w = TD ? 36 : 20;                                   // сторона основания
prism_h = wall + clr + dbl_len + snap_clr + 3;            // высота = глубина двойного паза + дно 3 мм
module test_prism() {
    hw = prism_w/2;
    faces = [ [[1,0,0], "A", 0], [[0,1,0], "B", 1], [[-1,0,0], "C", 2], [[0,-1,0], "C", 2] ];
    difference() {
        translate([-hw, -hw, 0]) cube([prism_w, prism_w, prism_h]);
        dbl_socket(prism_h);
        translate([0, 0, prism_h/2]) for (f = faces) orient(f[0]) socket(f[2], hw);
        translate([0, 0, prism_h/2]) cylinder(d = 24, h = 10, center = true);   // вычистить центр, где пазы пересекаются (иначе остаются «островки»)
        // буквы: на боках — в верхнем углу грани; сверху — "=" в углу
        // в кадре orient(): локальный -X = вверх (мировой +Z), локальный Y — вдоль грани; текст повернут на 90°, чтобы стоял прямо
        translate([0, 0, prism_h/2]) for (f = faces) orient(f[0]) translate([-(prism_h*0.5 - 6), hw*0.62, hw - eng_depth])
            linear_extrude(eng_depth + 0.01) rotate(90) text(f[1], size = TD ? 7 : 4, font = FONT, halign = "center", valign = "center");
        translate([hw*0.7, hw*0.7, prism_h - eng_depth]) linear_extrude(eng_depth + 0.01) text("=", size = TD ? 7 : 4, font = FONT, halign = "center", valign = "center");
    }
}

// Тест-кубик: на каждой грани свой паз. Верх — двойной, бока — A, B, C; четвёртый бок — ещё один C (самый ходовой, для сравнения с другим зазором)
cube_s = TD ? 60 : 32;
module test_cube() {
    hs = cube_s/2;
    faces = [ [[1,0,0], "A", 0], [[0,1,0], "B", 1], [[-1,0,0], "C", 2], [[0,-1,0], "C", 2] ];
    difference() {
        translate([0, 0, hs]) cube(cube_s, center = true);
        translate([0, 0, hs]) {
            for (f = faces) orient(f[0]) socket(f[2], hs);
            dbl_socket(hs);
            // буквы классов на гранях: рядом с пазом, в верхнем углу грани
            for (f = faces) orient(f[0]) translate([hs*0.62, hs*0.62, hs - eng_depth])
                linear_extrude(eng_depth + 0.01) text(f[1], size = TD ? 9 : 5, font = FONT, halign = "center", valign = "center");
            translate([hs*0.62, hs*0.62, hs - eng_depth]) linear_extrude(eng_depth + 0.01) text("=", size = TD ? 9 : 5, font = FONT, halign = "center", valign = "center");
        }
    }
}

// =====================================================================
//  Детали
// =====================================================================
// Углерод со всеми гибридизациями на одном шаре R=28 (8 пазов, лопасти исходные 18×6 / 28×7 / 26×10):
//  sp3 — 4 одинарных (тетраэдр); sp2 — одинарные T0,T1 + двойной C_D в их плоскости (130° от T0, 120° от T1);
//  sp(=,=) — двойные C_D и -C_D (180°); sp(-,≡) — одинарный T1 + тройной напротив него (180°).
//  Устья: одинарный T0 и -C_D касаются кромками (~0.4 мм) в одной точке поверхности, остальные не пересекаются.
C_D = [-0.76604, 0.00000, -0.64279];
C_D_PHASE = -55.5;   // поворот щели двойного паза углерода: задаёт плоскость этилена (двугранный угол меняется на 2×C_D_PHASE)
C_T = [-0.94281, -0.00000, 0.33333];
module carbon() {
    difference() {
        atom(R_C, [ for (d = TET) [C, d] ], [[0,0,-1], "C", "IV", "", label_flat, 6, "12.011"]);
        orient(C_D)  dbl_socket(R_C, C_D_PHASE);
        orient(-C_D) dbl_socket(R_C);
        orient(C_T)  trp_socket(R_C);
    }
}
module carbon_sp3_only() atom(R_C, [ for (d = TET) [C, d] ], [[0,0,-1], "C", "IV", "", label_flat, 6, "12.011"]);
// sp2: два одинарных + двойной под 120° в плоскости XZ; двойной — по +Z (вверх), одинарные ниже на 120°
SP2 = [ [0,0,1], [ sin(120), 0, cos(120)], [-sin(120), 0, cos(120)] ];
module carbon_sp2() {
    difference() {
        atom(R_C, [ [C, SP2[1]], [C, SP2[2]] ], [[0,0,-1], "C", "IV", "", label_flat, 6, "12.011"]);
        dbl_socket(R_C);
        hyb_label("sp2");
    }
}
// sp, два двойных на 180° (CO2): двойные по ±X; дно плоское без пазов
module carbon_sp_dd() {
    difference() {
        atom(R_C, [], [[0,0,-1], "C", "IV", "", label_flat, 6, "12.011"]);
        orient([1,0,0]) dbl_socket(R_C);
        orient([-1,0,0]) dbl_socket(R_C);
        hyb_label("sp =");
    }
}
// sp, одинарный + тройной на 180° (HC≡CH, HC≡N): тройной по +X, одинарный по -X
module carbon_sp_st() {
    difference() {
        atom(R_C, [ [C, [-1,0,0]] ], [[0,0,-1], "C", "IV", "", label_flat, 6, "12.011"]);
        orient([1,0,0]) trp_socket(R_C);
        hyb_label("sp ≡");
    }
}

// =====================================================================
//  Универсальный углерод: все гибридизации на одном шаре R=32 (ориентации наборов подобраны численно,
//  устья не перекрываются, запас 1.6°). Наборы: sp3 (4 одинарных), sp2 (2 одинарных + двойной, 120°),
//  sp (2 двойных, 180°), sp (одинарный + тройной, 180°). Дно свободно под подпись.
// =====================================================================
R_CU = 32;
CU_SINGLES = [ [0.71072, 0.23198, -0.66412], [-0.89831, 0.07677, -0.43261], [0.05103, 0.62856, 0.77609], [0.13655, -0.93731, 0.32064], [0.18230, -0.72067, -0.66888], [-0.07314, 0.95179, -0.29790], [-0.84730, 0.50637, 0.16024] ];
CU_DOUBLES = [ [-0.10917, -0.23112, 0.96678], [0.69315, 0.71569, 0.08563], [-0.69315, -0.71569, -0.08563] ];
CU_TRIPLES = [ [0.84730, -0.50637, -0.16024] ];
module carbon_uni() {
    difference() {
        atom(R_CU, [ for (v = CU_SINGLES) [C, v] ], [[0,0,-1], "C", "IV", "", label_flat, 6, "12.011"]);
        for (v = CU_DOUBLES) orient(v) dbl_socket(R_CU);
        for (v = CU_TRIPLES) orient(v) trp_socket(R_CU);
    }
}
// подпись гибридизации — на дне, под основной подписью (мелко, справа)
module hyb_label(t) {
    translate([0, 0, -R_C + label_flat - eng_depth]) linear_extrude(eng_depth + 0.01)
        translate([0, -sub_size*4.3]) text(t, size = sub_size*0.9, font = FONT, halign = "center", valign = "baseline");
}
module hydrogen() atom(R_H, [ [C, [0,0,1]] ], [[0,0,-1], "H", "I", "", label_flat, 1, "1.008"]);
// кислород: 2 гнезда под связи + 2 гнезда под заглушки (все класса A)
// Кислород v2: одинарные O–H под ANG_H2O, двойной O=O по биссектрисе (+Z); полости пересекаются -> взаимная блокировка
O_S1 = [ sin(ANG_H2O/2), 0, cos(ANG_H2O/2)];
O_S2 = [-sin(ANG_H2O/2), 0, cos(ANG_H2O/2)];
O_LP = [ [0,  sin(ANG_H2O/2), -cos(ANG_H2O/2)], [0, -sin(ANG_H2O/2), -cos(ANG_H2O/2)] ];
module oxygen() {
    difference() {
        union() {
            sphere(R_O);
            for (d = O_LP) orient(d) translate([0, 0, R_O - 3]) scale([1, 1, 0.55]) sphere(d = R_O * 0.7);
        }
        orient(O_S1) socket(A, R_O);
        orient(O_S2) socket(A, R_O);
        dbl_socket(R_O);
        el_label(R_O, "O");                                       // символ, Z=8, валентность II, масса 15.999
        translate([0, 0, -R_O - 50 + label_flat]) cube(100, center = true);
    }
}
// Кислород v1 (промежуточный вариант, для доработки): 4 тетраэдрических паза класса A —
// 2 под связи + 2 под заглушки/будущие «слабые» водородные связи (лёд, ДНК)
module oxygen_4sock() {
    if (lp_bump) {
        atom(R_O, [ [A, TET[0]], [A, TET[1]] ], [[0,0,-1], "O", "II", "", label_flat, 8, "15.999"]);
        for (i = [2:3]) orient(TET[i]) translate([0, 0, R_O - 3]) scale([1, 1, 0.55]) sphere(d = R_O * 0.7);
    } else atom(R_O, [ for (d = TET) [A, d] ], [[0,0,-1], "O", "II", "", label_flat, 8, "15.999"]);
}

module bond_CC() bond(L_CC, C, R_C, C, R_C, "");
module bond_CO() bond(L_CO, C, R_C, A, R_O, "");
module bond_CH() bond(L_CH, C, R_C, C, R_H, "");
module bond_OH() bond(L_OH, A, R_O, C, R_H, "");
module bond_CN() bond(L_CN, C, R_C, B, R_N, "");
module bond_NH() bond(L_NH, B, R_N, C, R_H, "");
// Двойная связь: стержень с витыми ключами на обоих концах (одна закрутка)
module bond_dbl(L_A, r1, r2, lbl = "") {
    L = L_A * SCALE;  x1 = r1;  x2 = L - r2;  rod_len = x2 - x1;
    difference() {
        union() {
            translate([x1 + hc_of(dbl_w) - 0.5, 0, 0]) rotate([0, 90, 0]) cylinder(d = rod_d, h = rod_len - 2*hc_of(dbl_w) + 1);
            translate([x1, 0, 0]) rotate([0, -90, 0]) dbl_key_end(r1);
            translate([x2, 0, 0]) rotate([0,  90, 0]) dbl_key_end(r2);
        }
        rod_label(x1 + hc_of(dbl_w) + 2, x2 - hc_of(dbl_w) - 2, lbl);
        if (rod_flat > 0) { hc = (dbl_w + 2*(snap_clr-tip_clr) + 2 - rod_d)/2; translate([x1 + hc, -20, -rod_d/2 - 10 + rod_flat]) cube([rod_len - 2*hc, 40, 10]); }
    }
}
module bond_trp(L_A, r1, r2, lbl = "") {
    L = L_A * SCALE;  x1 = r1;  x2 = L - r2;  rod_len = x2 - x1;
    difference() {
        union() {
            translate([x1 + hc_of(TRP_W) - 0.5, 0, 0]) rotate([0, 90, 0]) cylinder(d = rod_d, h = rod_len - 2*hc_of(TRP_W) + 1);
            translate([x1, 0, 0]) rotate([0, -90, 0]) trp_key_end(r1);
            translate([x2, 0, 0]) rotate([0,  90, 0]) trp_key_end(r2);
        }
        if (rod_flat > 0) { hc = (dbl_w + 2*(snap_clr-tip_clr) + 2 - rod_d)/2; translate([x1 + hc, -20, -rod_d/2 - 10 + rod_flat]) cube([rod_len - 2*hc, 40, 10]); }
    }
}
module bond_OO() bond_dbl(L_OO, R_O, R_O, "=");
module bond_NN() bond_trp(L_NN, R_N, R_N, "≡");
module bond_CdC() bond_dbl(L_CdC, R_C, R_C, "=");
module bond_CdO() bond_dbl(L_CdO, R_C, R_O, "=");
module bond_CtC() bond_trp(L_CtC, R_C, R_C, "≡");
module bond_CtN() bond_trp(L_CtN, R_C, R_N, "≡");
module bond_HH() bond(L_HH, C, R_H, C, R_H, "");
module assembly_H2() { color("white") rotate([0,90,0]) hydrogen(); color("gray") bond_HH(); color("white") translate([L_HH*SCALE,0,0]) rotate([0,-90,0]) hydrogen(); }
// Проверка взаимной блокировки: пересечение полостей (должно быть непустым)
module block_check() intersection() { dbl_socket(R_O); orient(O_S1) socket(A, R_O); }
module assembly_O2() {
    color("red") rotate([0, 90, 0]) oxygen();
    color("orange") bond_OO();
    color("red") translate([L_OO*SCALE, 0, 0]) rotate([0, -90, 0]) oxygen();
}
// азот: 3 гнезда под связи + 1 под заглушку (все класса B)
module nitrogen() {
    difference() {
        atom(R_N, [ for (d = TET) [B, d] ], [[0,0,-1], "N", "III", "", label_flat, 7, "14.007"]);
        orient(-TET[3]) trp_socket(R_N);   // тройной паз N≡N — напротив неподелённой пары
    }
}

// Сборка метанола CH3–OH для визуальной проверки
module assembly() {
    color("dimgray") carbon();
    // 3 водорода на нижних гнёздах углерода (гнездо H смотрит на углерод)
    for (i = [1:3]) {
        d = TET[i];
        color("white")  translate(d * L_CH * SCALE) orient(-d) hydrogen();
        color("silver") orient_x(d) bond_CH();
    }
    // кислород сверху: его гнездо TET[0] смотрит вниз на углерод
    dO = TET[0];
    pO = dO * L_CO * SCALE;
    color("red")    translate(pO) rotate([0,0,60]) rotate([0,180,0]) oxygen();
    color("orange") orient_x(dO) bond_CO();
    // направления остальных гнёзд кислорода после его поворота
    oDirs = [ for (i=[1:3]) let(v=TET[i], m=[-v[0], v[1], -v[2]])
              [ m[0]*cos(60)-m[1]*sin(60), m[0]*sin(60)+m[1]*cos(60), m[2] ] ];
    // O–H на первом, заглушки на двух других
    dH = oDirs[0];
    color("white")  translate(pO + dH * L_OH * SCALE) orient(-dH) hydrogen();
    color("orange") translate(pO) orient_x(dH) bond_OH();
    if (!lp_bump) for (i=[1:2]) color("pink") translate(pO + oDirs[i]*R_O) orient(oDirs[i]) lone_pair_cap(A);
}
// Сборка из групп: метанол = CH3 + C–O + OH;  рядом вода = OH + рука H–O
module assembly_groups() {
    color("dimgray") group_CH3();
    dO = TET[0]; pO = dO * L_CO * SCALE;
    color("orange") orient_x(dO) bond_CO();
    color("red") translate(pO) rotate([0,0,60]) rotate([0,180,0]) group_OH();
    // вода
    translate([160, 0, 0]) {
        color("red") group_OH();
        color("white") translate([0,0,L_OH*SCALE]) rotate([180,0,0]) h_arm_O();
    }
}
// повернуть стержень (лежит вдоль +X) на направление v
module orient_x(v) {
    n = norm(v);
    polar = acos(v[2]/n);
    az = atan2(v[1], v[0]);
    rotate([0, polar, az]) rotate([0, -90, 0]) children();
}

// =====================================================================
if (PART == "carbon")   carbon();
if (PART == "oxygen")   oxygen();
if (PART == "oxygen_4sock") oxygen_4sock();   // промежуточный вариант с 4 пазами (слабые связи)
if (PART == "hydrogen") hydrogen();
if (PART == "lp_cap")   lone_pair_cap(A);
if (PART == "lp_cap_A") lone_pair_cap(A);
if (PART == "lp_cap_B") lone_pair_cap(B);
if (PART == "nitrogen") nitrogen();
if (PART == "bond_NH")  bond_NH();
if (PART == "bond_OO")  bond_OO();
if (PART == "bond_NN")  bond_NN();
if (PART == "bond_CdC") bond_CdC();
if (PART == "bond_CdO") bond_CdO();
if (PART == "bond_CtC") bond_CtC();
if (PART == "bond_CtN") bond_CtN();
if (PART == "carbon_sp2") carbon_sp2();
if (PART == "carbon_uni") carbon_uni();
if (PART == "carbon_sp_dd") carbon_sp_dd();
if (PART == "carbon_sp_st") carbon_sp_st();
if (PART == "bond_HH")  bond_HH();
if (PART == "assembly_H2") assembly_H2();
if (PART == "block_check") block_check();
if (PART == "assembly_O2") assembly_O2();
if (PART == "bond_CC")  bond_CC();
if (PART == "bond_CO")  bond_CO();
if (PART == "bond_CH")  bond_CH();
if (PART == "bond_OH")  bond_OH();
if (PART == "bond_CN")  bond_CN();
if (PART == "assembly_groups") assembly_groups();
if (PART == "fit_test") fit_test();
if (PART == "test_cube") test_cube();
if (PART == "test_cups") test_cups();
if (PART == "test_prism") test_prism();
if (PART == "test_key_A") test_key(A);
if (PART == "test_key_B") test_key(B);
if (PART == "test_key_C") test_key(C);
if (PART == "test_key_dbl") test_key_dbl();
if (PART == "fit_test_dbl") fit_test_dbl();
if (PART == "group_CH3") group_CH3();
if (PART == "group_CH2") group_CH2();
if (PART == "group_OH")  group_OH();
if (PART == "group_NH2") group_NH2();
if (PART == "h_arm_C")   h_arm_C();
if (PART == "h_arm_O")   h_arm_O();
if (PART == "h_arm_N")   h_arm_N();
if (PART == "assembly") assembly();
echo(twist_A = ctw(A), twist_B = ctw(B), twist_C = ctw(C), twist_dbl = dbl_twist);
// макет для подбора фазы: шар углерода только с двойным пазом C_D
module carbon_dproxy() difference() { sphere(R_C); orient(C_D) dbl_socket(R_C, C_D_PHASE); }
if (PART == "carbon_dproxy") carbon_dproxy();
