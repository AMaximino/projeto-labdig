// Modelo paramétrico da caixa do jogo Aventura Financeira Evolution (OpenSCAD).
//
// Caixa de MDF cortado a laser com encaixes de dedo (finger joints): um corpo
// aberto em cima (fundo + 4 paredes) e uma tampa que encaixa por fora
// (topo + 4 abas). Na tampa ficam só os controles do jogador.
//
// É o mesmo modelo de caixa.py (medidas, encaixes, furos e componentes),
// escrito em OpenSCAD para ficar fácil de alterar. Mude um parâmetro abaixo
// e aperte F5 (prévia) ou F6 (render).
//
// Modos (variável MODO, também pela linha de comando com -D):
//   "montagem"  caixa montada em 3D, com adesivos e componentes (padrão)
//   "pecas"     todas as peças de MDF em 2D, lado a lado, para conferir
//   "corte"     só o contorno de corte da peça PECA, com kerf compensado
//   "gravacao"  só as linhas gravadas (onde colar os adesivos) da peça PECA
//
// Exemplos, na pasta modelagem/:
//   openscad -o saida/caixa_scad.stl caixa.scad
//   openscad -D 'ABRIR=150' -o saida/caixa_aberta.png --render caixa.scad
//   openscad -D 'MODO="corte"' -D 'PECA="tampa_topo"' -o tampa_topo.dxf caixa.scad
//   openscad -D 'MODO="gravacao"' -D 'PECA="tampa_topo"' -o tampa_topo_grav.dxf caixa.scad
//
// Coordenadas (vista de cima, jogador na frente): origem no canto frontal
// esquerdo da tampa, X para a direita (comprimento), Y para o fundo
// (largura), Z para cima, em mm.

/* [Modo] */
MODO = "montagem"; // [montagem, pecas, corte, gravacao]
PECA = "tampa_topo"; // [tampa_topo, tampa_aba_frente, tampa_aba_tras, tampa_aba_esq, tampa_aba_dir, corpo_fundo, corpo_frente, corpo_tras, corpo_lat_esq, corpo_lat_dir, teste_a, teste_b]
ABRIR = 0;            // quanto a tampa sobe na montagem (mm)
MOSTRAR_COMPONENTES = true;
MOSTRAR_ADESIVOS = true;
MOSTRAR_CORPO = true;
MOSTRAR_TAMPA = true;

/* [Caixa] */
// Medidas externas com a tampa fechada
CAIXA_C = 415;           // comprimento (X)
CAIXA_L = 315;           // largura (Y)
CAIXA_A = 205;           // altura total
TAMPA_A = 40;            // altura da tampa (topo + aba)

MDF = 3.0;               // espessura da chapa [ASSUMIDO: medir com paquímetro]
KERF = 0.15;             // largura do corte do laser [ASSUMIDO: cortar a peça de teste]
FOLGA_TAMPA = 0.5;       // folga de cada lado entre a aba da tampa e o corpo
DEDO = 18.0;             // largura aproximada de cada dedo do encaixe

/* [Botões e seletor] */
BOTAO_CORPO = 12.0;      // botão táctil 12×12
CAPA_DIAM = 12.0;        // [ASSUMIDO: medir a capa do kit]
FURO_BOTAO = 13.0;       // capa + 1 mm de folga
ALTURA_BOTAO_CAPA = 13.0;// da placa até o topo da capa [ASSUMIDO]
SOBRESSAI = 2.0;         // quanto a capa sai acima da tampa

FURO_SELETOR = 10.0;     // bucha de 3/8" + folga [ASSUMIDO: medir a rosca]
KNOB_DIAM = 24.0;
KNOB_A = 14.0;

/* [Placas] */
RC522_C = 60;  RC522_L = 40;
CARTAO_C = 85.6; CARTAO_L = 54.0; // cartão ISO/IEC 7810 ID-1
FPGA_C = 128;  FPGA_L = 99;       // Terasic DE0-CV (conferir)
ESP_C = 55;    ESP_L = 28;        // ESP32 DevKit
ESPACADOR = 10.0;                 // espaçadores da FPGA no fundo

/* [Recortes do corpo] */
RASGO_C = 50; RASGO_A = 25; RASGO_R = 6; // rasgo dos cabos USB na traseira
RASGO_Z = 20;                     // do chão até a borda de baixo do rasgo
LOGO_FRENTE = 130;                // lado do adesivo do logotipo na frente
LOGO_Z = 15;                      // do chão até a base do adesivo

MARGEM_MIN = 30;                  // distância mínima dos furos à borda da tampa
FOLGA_FUROS = 4;                  // madeira mínima entre dois furos

/* [Hidden] */
$fa = 3;
$fs = 0.4;

// --- Medidas derivadas -----------------------------------------------------

CORPO_C = CAIXA_C - 2 * (MDF + FOLGA_TAMPA);
CORPO_L = CAIXA_L - 2 * (MDF + FOLGA_TAMPA);
CORPO_A = CAIXA_A - MDF;          // a tampa apoia no topo das paredes
CORPO_X0 = MDF + FOLGA_TAMPA;     // posição do corpo sob a tampa
CORPO_Y0 = MDF + FOLGA_TAMPA;
RASGO_X = CORPO_C / 2;

FACE_INF = CAIXA_A - MDF;         // face de baixo do topo da tampa
TOPO = CAIXA_A;                   // face de cima da tampa
ESPACADOR_BOTOES = ALTURA_BOTAO_CAPA - MDF - SOBRESSAI;
PLACA_Z = FACE_INF - ESPACADOR_BOTOES;

// --- Cores -----------------------------------------------------------------

COR_MADEIRA = "#E3C9A0";
COR_MADEIRA_ESCURA = "#D2B385";
COR_ABA = "#CFE7D9";              // aba da tampa pintada de verde-menta
COR_TINTA = "#24343A";
COR_VERDE_PAINEL = "#2E7161";

// Cores das capas: as mesmas da pinagem da Semana 3
CAPA_AZUL = "#2F6DB5"; CAPA_BRANCO = "#F4F4F0"; CAPA_PRETO = "#2A2A2A";
CAPA_VERMELHO = "#C9433A"; CAPA_AMARELO = "#F1C232"; CAPA_VERDE = "#3E9A52";

// --- Adesivos da tampa -------------------------------------------------------
// [chave, título, x0, y0, comprimento, largura, fundo, borda]

ZONAS = [
    ["seletor", "1 ESCOLHA O ITEM",    22,  22,   150, 146, "#ECE5F6", "#6F5AA8"],
    ["cartao",  "2 PAGUE COM O CARTÃO", 182, 22,   110, 146, "#F3EEFA", "#6F5AA8"],
    ["partida", "PARTIDA",              302, 22,   91,  146, "#F7EFDF", "#B08A4A"],
    ["logo",    "",                     22,  180.5, 110, 110, "#FFFFFF", COR_VERDE_PAINEL],
    ["acao_1",  "TRABALHO E ESTUDO",    147, 178,  78,  115, "#DCEAF7", "#4F86C0"],
    ["acao_2",  "INVESTIMENTOS",        231, 178,  78,  115, "#DCF0E2", "#3F9258"],
    ["acao_3",  "COMPRAS",              315, 178,  78,  115, "#FCE3D3", "#C7684F"],
];

function zona(ch) = [for (z = ZONAS) if (z[0] == ch) z][0];
function zona_cx(z) = z[2] + z[4] / 2;
function zona_cy(z) = z[3] + z[5] / 2;

// --- Componentes da tampa ----------------------------------------------------

SELETOR_X = 97;  SELETOR_Y = 95;
SELETOR_PASSO = 30;              // graus entre posições (chave 1P12T)
SELETOR_RAIO_NUM = 28;           // círculo dos números
SELETOR_RAIO_ICONE = 47;         // círculo das ilustrações
ICONE_ITEM = 15;

RFID_X = 237; RFID_Y = 92;
ESP_X = 237;  ESP_Y = 150;       // ESP32 sob a tampa, atrás do RC522

ACAO_Y = 228;
ACAO_DX = 19;
PARTIDA_X = 359.5;
INICIAR_Y = 120; RESET_Y = 60;

function acao_x(ch, lado) = zona_cx(zona(ch)) + lado * ACAO_DX;

// [nome, x, y, cor da capa, zona]. Pinos e sinais: saida/lista_componentes.csv
BOTOES = [
    ["TRABALHAR", acao_x("acao_1", -1), ACAO_Y, CAPA_AZUL,     "acao_1"],
    ["ESTUDAR",   acao_x("acao_1",  1), ACAO_Y, CAPA_BRANCO,   "acao_1"],
    ["INVESTIR",  acao_x("acao_2", -1), ACAO_Y, CAPA_PRETO,    "acao_2"],
    ["RESGATAR",  acao_x("acao_2",  1), ACAO_Y, CAPA_VERMELHO, "acao_2"],
    ["COMPRAR",   acao_x("acao_3", -1), ACAO_Y, CAPA_AMARELO,  "acao_3"],
    ["VENDER",    acao_x("acao_3",  1), ACAO_Y, CAPA_VERDE,    "acao_3"],
    ["INICIAR",   PARTIDA_X, INICIAR_Y, CAPA_VERDE,    "partida"],
    ["RESET",     PARTIDA_X, RESET_Y,   CAPA_VERMELHO, "partida"],
];

// Furos da tampa: [nome, x, y, diâmetro, zona]
FUROS_TAMPA = concat(
    [for (b = BOTOES) [b[0], b[1], b[2], FURO_BOTAO, b[4]]],
    [["SELETOR", SELETOR_X, SELETOR_Y, FURO_SELETOR, "seletor"]]
);

// Ângulo (graus, anti-horário a partir de +X) da posição 1..10 do seletor.
// A posição 1 fica embaixo à esquerda e as demais seguem no sentido horário.
function angulo_seletor(pos) = 225 - SELETOR_PASSO * (pos - 1);
function pos_seletor(pos, raio) =
    [SELETOR_X + raio * cos(angulo_seletor(pos)), SELETOR_Y + raio * sin(angulo_seletor(pos))];

// --- Peças de MDF ------------------------------------------------------------
// [nome, comprimento, largura, bordas (baixo, direita, cima, esquerda), grupo,
//  plano no modelo 3D, destino (canto mínimo da peça montada)]
//
// Bordas: A = dedos nos segmentos ímpares (pontas recuadas), B = dedos nos
// segmentos pares (pontas salientes, complemento de A), L = lisa.
// Corpo: fundo com bordas A; paredes com borda de baixo B; nas quinas
// verticais a frente/trás usa B e as laterais A. A tampa é a mesma estrutura
// de cabeça para baixo: topo A, abas com a borda do topo B.

ZT = CAIXA_A - TAMPA_A;
PECAS = [
    ["tampa_topo",       CAIXA_C, CAIXA_L, ["A","A","A","A"], "tampa", "xy",       [0, 0, CAIXA_A - MDF]],
    ["tampa_aba_frente", CAIXA_C, TAMPA_A, ["B","B","L","B"], "tampa", "xz_baixo", [0, 0, ZT]],
    ["tampa_aba_tras",   CAIXA_C, TAMPA_A, ["B","B","L","B"], "tampa", "xz_baixo", [0, CAIXA_L - MDF, ZT]],
    ["tampa_aba_esq",    CAIXA_L, TAMPA_A, ["B","A","L","A"], "tampa", "yz_baixo", [0, 0, ZT]],
    ["tampa_aba_dir",    CAIXA_L, TAMPA_A, ["B","A","L","A"], "tampa", "yz_baixo", [CAIXA_C - MDF, 0, ZT]],
    ["corpo_fundo",      CORPO_C, CORPO_L, ["A","A","A","A"], "corpo", "xy",       [CORPO_X0, CORPO_Y0, 0]],
    ["corpo_frente",     CORPO_C, CORPO_A, ["B","B","L","B"], "corpo", "xz",       [CORPO_X0, CORPO_Y0, 0]],
    ["corpo_tras",       CORPO_C, CORPO_A, ["B","B","L","B"], "corpo", "xz",       [CORPO_X0, CORPO_Y0 + CORPO_L - MDF, 0]],
    ["corpo_lat_esq",    CORPO_L, CORPO_A, ["B","A","L","A"], "corpo", "yz",       [CORPO_X0, CORPO_Y0, 0]],
    ["corpo_lat_dir",    CORPO_L, CORPO_A, ["B","A","L","A"], "corpo", "yz",       [CORPO_X0 + CORPO_C - MDF, CORPO_Y0, 0]],
    // Peças de teste: cortar primeiro e conferir encaixe e furos
    ["teste_a",          60, 40,           ["L","L","B","L"], "teste", "xy",       [0, 0, 0]],
    ["teste_b",          60, 30,           ["A","L","L","L"], "teste", "xy",       [0, 0, 0]],
];

function peca(nome) = [for (p = PECAS) if (p[0] == nome) p][0];

// --- Encaixe de dedos --------------------------------------------------------

// Número ímpar de segmentos: o padrão fica simétrico nas duas pontas.
function n_dedos(comp) = let(n = floor(comp / DEDO)) max(n % 2 == 0 ? n - 1 : n, 3);

// Segmentos [início, fim, saliente] de uma borda.
function segmentos(comp, tipo) =
    tipo == "L" ? [[0, comp, true]]
    : let(n = n_dedos(comp), w = comp / n)
      [for (i = [0 : n - 1]) [i * w, (i + 1) * w, tipo == "A" ? i % 2 == 1 : i % 2 == 0]];

function ponta_saliente(tipo) = tipo == "B" || tipo == "L";

// Contorno de uma peça c × l com encaixes. Cada borda tem uma faixa de
// largura MDF onde os dedos alternam; o canto MDF × MDF só pertence à peça
// se as duas bordas que se encontram nele têm a ponta saliente.
// Pontos no sentido anti-horário.
function contorno_dedos(c, l, bordas) =
    let(cantos = [[0, 0], [c, 0], [c, l], [0, l]],
        dirs = [[1, 0], [0, 1], [-1, 0], [0, -1]],
        normais = [[0, 1], [-1, 0], [0, -1], [1, 0]],   // para dentro da peça
        comps = [c, l, c, l])
    limpar([for (i = [0 : 3])
        let(tipo = bordas[i], ant = bordas[(i + 3) % 4],
            p = cantos[i], d = dirs[i], n = normais[i], na = normais[(i + 3) % 4],
            comp = comps[i])
        each concat(
            [ponta_saliente(ant) && ponta_saliente(tipo) ? p : p + MDF * (na + n)],
            [for (s = segmentos(comp, tipo))
                let(a = max(s[0], MDF), b = min(s[1], comp - MDF), prof = s[2] ? 0 : MDF)
                if (b > a) each [p + d * a + n * prof, p + d * b + n * prof]]
        )]);

// Remove pontos repetidos em sequência (o primeiro e o último também).
function limpar(pts) =
    let(n = len(pts))
    [for (i = [0 : n - 1]) if (norm(pts[i] - pts[(i + n - 1) % n]) > 1e-7) pts[i]];

module ret_arred(cx, cy, c, l, r) {
    translate([cx, cy]) offset(r = r) square([c - 2 * r, l - 2 * r], center = true);
}

// --- Peças em 2D -------------------------------------------------------------

module recortes_2d(nome) {
    if (nome == "tampa_topo")
        for (f = FUROS_TAMPA) translate([f[1], f[2]]) circle(d = f[3]);
    if (nome == "corpo_tras")
        ret_arred(RASGO_X, RASGO_Z + RASGO_A / 2, RASGO_C, RASGO_A, RASGO_R);
    if (nome == "teste_a") {
        translate([17, 18]) circle(d = FURO_BOTAO);
        translate([43, 18]) circle(d = FURO_SELETOR);
    }
}

// Linhas gravadas: 1 mm fora de cada adesivo, guia para colar no lugar certo.
module gravacoes_2d(nome) {
    if (nome == "tampa_topo")
        for (z = ZONAS) ret_arred(zona_cx(z), zona_cy(z), z[4] + 2, z[5] + 2, 6);
    if (nome == "corpo_frente")
        ret_arred(CORPO_C / 2, LOGO_Z + LOGO_FRENTE / 2, LOGO_FRENTE + 2, LOGO_FRENTE + 2, 7);
}

module peca_2d(nome) {
    p = peca(nome);
    difference() {
        polygon(contorno_dedos(p[1], p[2], p[3]));
        recortes_2d(nome);
    }
}

// Peça como sai do laser: o corte come KERF/2 de cada lado da linha, então
// o contorno cresce KERF/2 e os furos diminuem KERF/2.
module peca_corte_2d(nome) {
    offset(delta = KERF / 2) peca_2d(nome);
}

// Linha fina (0,1 mm) sobre cada contorno gravado.
module peca_gravacao_2d(nome) {
    difference() {
        offset(delta = 0.05) gravacoes_2d(nome);
        offset(delta = -0.05) gravacoes_2d(nome);
    }
}

// --- Peças em 3D -------------------------------------------------------------

// Leva a peça extrudada (u, v, espessura) para o lugar dela na caixa.
module colocar(plano, destino, l) {
    translate(destino)
    if (plano == "xy") children();
    else if (plano == "xz") translate([0, MDF, 0]) rotate([90, 0, 0]) children();        // (u, -t, v)
    else if (plano == "xz_baixo") translate([0, 0, l]) rotate([-90, 0, 0]) children();   // (u, t, -v)
    else if (plano == "yz") rotate([0, 0, 90]) rotate([90, 0, 0]) children();                // (t, u, v)
    else if (plano == "yz_baixo")
        translate([MDF, 0, l]) rotate([0, 0, 90]) rotate([-90, 0, 0]) children();       // (-t, u, -v)
}

module peca_3d(nome) {
    p = peca(nome);
    colocar(p[5], p[6], p[2]) linear_extrude(MDF) peca_2d(nome);
}

// --- Adesivos e componentes --------------------------------------------------

module adesivos() {
    for (z = ZONAS) {
        color(z[6]) translate([0, 0, TOPO]) linear_extrude(0.4) difference() {
            ret_arred(zona_cx(z), zona_cy(z), z[4], z[5], 4.5);
            for (f = FUROS_TAMPA) if (f[4] == z[0]) translate([f[1], f[2]]) circle(d = f[3]);
        }
        if (z[1] != "")
            color(z[7]) translate([zona_cx(z), z[3] + z[5] - 9, TOPO + 0.4])
                linear_extrude(0.2) text(z[1], size = 5, halign = "center", valign = "center");
    }
    // Números 1–10 em volta do seletor e lugar de cada ilustração
    for (pos = [1 : 10]) {
        color(COR_TINTA) translate(concat(pos_seletor(pos, SELETOR_RAIO_NUM), [TOPO + 0.4]))
            linear_extrude(0.2) text(str(pos), size = 5, halign = "center", valign = "center");
        color("#FFFFFF") translate(concat(pos_seletor(pos, SELETOR_RAIO_ICONE), [TOPO + 0.4]))
            linear_extrude(0.2) square(ICONE_ITEM, center = true);
    }
    // Área "aproxime aqui" do cartão
    color("#6F5AA8") translate([0, 0, TOPO + 0.4]) linear_extrude(0.2) difference() {
        ret_arred(RFID_X, RFID_Y, CARTAO_C, CARTAO_L, 3.5);
        ret_arred(RFID_X, RFID_Y, CARTAO_C - 2, CARTAO_L - 2, 2.5);
    }
    // Logotipo na frente do corpo
    if (MOSTRAR_CORPO)
        color("#FFFFFF") translate([CORPO_X0 + CORPO_C / 2 - LOGO_FRENTE / 2, CORPO_Y0 - 0.4, LOGO_Z])
            cube([LOGO_FRENTE, 0.4, LOGO_FRENTE]);
}

module botao(b) {
    corpo_alt = 3.5;
    translate([b[1], b[2], PLACA_Z]) {
        color("#1E1E1E") translate([-BOTAO_CORPO / 2, -BOTAO_CORPO / 2, 0])
            cube([BOTAO_CORPO, BOTAO_CORPO, corpo_alt]);
        color(b[3]) translate([0, 0, corpo_alt]) {
            cylinder(d = CAPA_DIAM, h = ALTURA_BOTAO_CAPA - corpo_alt - 1.2);
            translate([0, 0, ALTURA_BOTAO_CAPA - corpo_alt - 1.2])
                cylinder(d1 = CAPA_DIAM, d2 = CAPA_DIAM - 2.4, h = 1.2);
        }
    }
}

module seletor() {
    translate([SELETOR_X, SELETOR_Y, 0]) {
        color("#9A9A9A") translate([0, 0, FACE_INF - 22]) cylinder(r = 14, h = 22);
        color("#C0C0C0") translate([0, 0, FACE_INF]) cylinder(r = 3, h = MDF + 4);
        color("#5E4B96") translate([0, 0, TOPO + 0.5]) {
            cylinder(d = KNOB_DIAM, h = KNOB_A - 2);
            translate([0, 0, KNOB_A - 2]) cylinder(d1 = KNOB_DIAM, d2 = KNOB_DIAM - 4, h = 2);
        }
        // Seta apontando para a posição 1
        color("#FFFFFF") rotate(angulo_seletor(1)) translate([6, 0, TOPO + 0.5 + KNOB_A])
            linear_extrude(0.6) square([9, 2.4], center = true);
    }
}

module componentes_tampa() {
    for (b = BOTOES) botao(b);
    seletor();
    // RC522 colado sob a tampa e ESP32 logo atrás
    color("#1A4DB3") translate([RFID_X - RC522_C / 2, RFID_Y - RC522_L / 2, FACE_INF - 2.6])
        cube([RC522_C, RC522_L, 1.6]);
    color("#151515") translate([ESP_X - ESP_C / 2, ESP_Y - ESP_L / 2, FACE_INF - 12])
        cube([ESP_C, ESP_L, 1.6]);
    // Placas perfuradas dos botões
    xs = [for (b = BOTOES) if (b[4] != "partida") b[1]];
    color("#B88A4A") {
        translate([min(xs) - 12, ACAO_Y - 12, PLACA_Z - 1.6])
            cube([max(xs) - min(xs) + 24, 24, 1.6]);
        translate([PARTIDA_X - 12, RESET_Y - 12, PLACA_Z - 1.6])
            cube([24, INICIAR_Y - RESET_Y + 24, 1.6]);
    }
}

module fpga() {
    color("#1A6B33")
        translate([CORPO_X0 + CORPO_C / 2 - FPGA_C / 2, CORPO_Y0 + CORPO_L - MDF - 20 - FPGA_L,
                   MDF + ESPACADOR])
            cube([FPGA_C, FPGA_L, 1.6]);
}

// --- Montagem ----------------------------------------------------------------

module corpo() {
    color(COR_MADEIRA_ESCURA)
        for (p = PECAS) if (p[4] == "corpo") peca_3d(p[0]);
    if (MOSTRAR_COMPONENTES) fpga();
}

module tampa() {
    color(COR_MADEIRA) peca_3d("tampa_topo");
    color(COR_ABA)
        for (p = PECAS) if (p[4] == "tampa" && p[0] != "tampa_topo") peca_3d(p[0]);
    if (MOSTRAR_ADESIVOS) adesivos();
    if (MOSTRAR_COMPONENTES) componentes_tampa();
}

module montagem() {
    if (MOSTRAR_CORPO) corpo();
    if (MOSTRAR_TAMPA) translate([0, 0, ABRIR]) tampa();
}

// Todas as peças de MDF em 2D, numa grade, com o nome embaixo de cada uma.
module todas_as_pecas() {
    colunas = 3;
    for (i = [0 : len(PECAS) - 1]) {
        p = PECAS[i];
        translate([(i % colunas) * (CAIXA_C + 30), -floor(i / colunas) * (CAIXA_L + 40)]) {
            color(COR_MADEIRA) peca_corte_2d(p[0]);
            color("blue") peca_gravacao_2d(p[0]);
            color("black") translate([0, -12]) text(p[0], size = 8);
        }
    }
}

// --- Conferências (as mesmas de caixa.py) -------------------------------------

function dist_furos(a, b) = norm([a[1] - b[1], a[2] - b[2]]) - (a[3] + b[3]) / 2;

module validar() {
    for (f = FUROS_TAMPA) {
        r = f[3] / 2;
        z = zona(f[4]);
        assert(MARGEM_MIN <= f[1] - r && f[1] + r <= CAIXA_C - MARGEM_MIN, str("margem X: ", f[0]));
        assert(MARGEM_MIN <= f[2] - r && f[2] + r <= CAIXA_L - MARGEM_MIN, str("margem Y: ", f[0]));
        assert(z[2] + 2 <= f[1] - r && f[1] + r <= z[2] + z[4] - 2, str("fora do adesivo: ", f[0]));
        assert(z[3] + 2 <= f[2] - r && f[2] + r <= z[3] + z[5] - 2, str("fora do adesivo: ", f[0]));
    }
    for (i = [0 : len(FUROS_TAMPA) - 2], j = [i + 1 : len(FUROS_TAMPA) - 1])
        assert(dist_furos(FUROS_TAMPA[i], FUROS_TAMPA[j]) >= FOLGA_FUROS,
               str("furos próximos: ", FUROS_TAMPA[i][0], " / ", FUROS_TAMPA[j][0]));
    for (i = [0 : len(BOTOES) - 2], j = [i + 1 : len(BOTOES) - 1])
        assert(norm([BOTOES[i][1] - BOTOES[j][1], BOTOES[i][2] - BOTOES[j][2]]) >= 2 * FURO_BOTAO,
               str("botões próximos: ", BOTOES[i][0], " / ", BOTOES[j][0]));
    for (i = [0 : len(ZONAS) - 1]) {
        a = ZONAS[i];
        // o adesivo não pode cobrir a faixa dos encaixes na borda da tampa
        assert(MDF + 5 <= a[2] && a[2] + a[4] <= CAIXA_C - MDF - 5, str("borda: ", a[0]));
        assert(MDF + 5 <= a[3] && a[3] + a[5] <= CAIXA_L - MDF - 5, str("borda: ", a[0]));
        for (j = [i + 1 : 1 : len(ZONAS) - 1]) {
            b = ZONAS[j];
            assert(!(a[2] - 3 < b[2] + b[4] && b[2] - 3 < a[2] + a[4] &&
                     a[3] - 3 < b[3] + b[5] && b[3] - 3 < a[3] + a[5]),
                   str("adesivos encostados: ", a[0], " / ", b[0]));
        }
    }
    sel = zona("seletor");
    for (pos = [1 : 10]) {
        c = pos_seletor(pos, SELETOR_RAIO_ICONE);
        r = ICONE_ITEM / 2 + 1.5;
        assert(sel[2] + 2 <= c[0] - r && c[0] + r <= sel[2] + sel[4] - 2, str("ícone ", pos, " (X)"));
        assert(sel[3] + 2 <= c[1] - r && c[1] + r <= sel[3] + sel[5] - 14, str("ícone ", pos, " (Y)"));
    }
    car = zona("cartao");
    assert(car[2] + 3 <= RFID_X - CARTAO_C / 2 && RFID_X + CARTAO_C / 2 <= car[2] + car[4] - 3,
           "cartão fora do adesivo");
    // Metal do seletor e da ESP32 longe da antena do RC522 (≥ 20 mm)
    assert(RFID_X - RC522_C / 2 - (SELETOR_X + 14) >= 20, "seletor perto do RC522");
    assert(ESP_Y - ESP_L / 2 - (RFID_Y + RC522_L / 2) >= 20, "ESP32 perto do RC522");
    assert(ESPACADOR_BOTOES > 0, "capa não alcança a tampa");
    // Rasgo longe dos encaixes; logotipo abaixo da aba da tampa
    assert(RASGO_Z >= MDF + 5 && RASGO_Z + RASGO_A <= CORPO_A - TAMPA_A - 5, "rasgo dos cabos");
    assert(LOGO_Z >= MDF + 5 && LOGO_Z + LOGO_FRENTE <= CORPO_A - (TAMPA_A - MDF) - 5,
           "logotipo da frente");
}

// --- Saída ---------------------------------------------------------------------

validar();
echo(str("MDF ", MDF, " mm, kerf ", KERF, " mm. Corpo ", CORPO_C, " × ", CORPO_L, " × ", CORPO_A,
         " mm; tampa ", CAIXA_C, " × ", CAIXA_L, " × ", TAMPA_A, " mm; espaçador dos botões ",
         ESPACADOR_BOTOES, " mm"));

if (MODO == "montagem") montagem();
else if (MODO == "pecas") todas_as_pecas();
else if (MODO == "corte") peca_corte_2d(PECA);
else if (MODO == "gravacao") peca_gravacao_2d(PECA);
