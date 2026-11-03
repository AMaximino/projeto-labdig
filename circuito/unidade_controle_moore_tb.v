`timescale 1ns/1ps

module unidade_controle_moore_tb;
    reg clock = 1'b0;
    reg reset = 1'b0;
    reg iniciar = 1'b0;
    reg acao_pulso = 1'b0;
    reg eh_jogada = 1'b0;
    reg display_pulso = 1'b0;
    reg fim_jogo = 1'b0;
    reg fim_perdeu = 1'b0;
    reg fim_rodada = 1'b0;

    wire desligaDisplay;
    wire rstED;
    wire init;
    wire processaE;
    wire rende;
    wire despesa;
    wire zeraCJ;
    wire contaCJ;
    wire zeraCR;
    wire contaCR;
    wire zeraD;
    wire registraD;
    wire zeraA;
    wire registraA;
    wire zeraV;
    wire registraV;
    wire zeraM;
    wire registraM;
    wire terminou;
    wire perdeu;
    wire [4:0] estado;

    always #5 clock = ~clock;

    unidade_controle dut (
        .clock(clock),
        .reset(reset),
        .iniciar(iniciar),
        .acao_pulso(acao_pulso),
        .eh_jogada(eh_jogada),
        .display_pulso(display_pulso),
        .fim_jogo(fim_jogo),
        .fim_perdeu(fim_perdeu),
        .fim_rodada(fim_rodada),
        .desligaDisplay(desligaDisplay),
        .rstED(rstED),
        .init(init),
        .processaE(processaE),
        .rende(rende),
        .despesa(despesa),
        .zeraCJ(zeraCJ),
        .contaCJ(contaCJ),
        .zeraCR(zeraCR),
        .contaCR(contaCR),
        .zeraD(zeraD),
        .registraD(registraD),
        .zeraA(zeraA),
        .registraA(registraA),
        .zeraV(zeraV),
        .registraV(registraV),
        .zeraM(zeraM),
        .registraM(registraM),
        .terminou(terminou),
        .perdeu(perdeu),
        .estado(estado)
    );

    initial begin
        reset = 1'b1;
        #1;
        if (estado !== 5'b00000 || !rstED) $fatal(1, "INICIO state outputs are incorrect");

        iniciar = 1'b1;
        acao_pulso = 1'b1;
        display_pulso = 1'b1;
        #1;
        if (estado !== 5'b00000 || !rstED || desligaDisplay)
            $fatal(1, "Moore outputs changed before the state transition");

        reset = 1'b0;
        @(posedge clock);
        #1;
        if (estado !== 5'b00001 || !desligaDisplay || rstED)
            $fatal(1, "ESPERA_INICIO state outputs are incorrect");

        @(posedge clock);
        #1;
        if (estado !== 5'b00010 || !init || desligaDisplay)
            $fatal(1, "INICIALIZA_JOGO state outputs are incorrect");

        $display("Moore outputs remain state-based; named states keep separate transitions.");
        $finish;
    end
endmodule
