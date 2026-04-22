module unidade_controle (
    input      clock,
    input      reset,
    input      iniciar,
    input      acao_pulso,
    input      eh_jogada,
    input      display_pulso,
    input      fim_jogo,
    input      fim_perdeu,
    input      fim_rodada,

    output reg desligaDisplay,
    output reg rstED,
    output reg init,
    output reg processaE,
    output reg rende,
    output reg despesa,
    output reg zeraCJ,
    output reg contaCJ,
    output reg zeraCR,
    output reg contaCR,
    output reg zeraD,
    output reg registraD,
    output reg zeraA,
    output reg registraA,
    output reg zeraV,
    output reg registraV,
    output reg zeraM,
    output reg registraM,

    output reg terminou,
    output reg perdeu,
    output reg [4:0] estado
);

    // Define estados
    parameter start             = 5'b00000;  // 0
    parameter registraModo      = 5'b00001;  // 1
    parameter inicializar       = 5'b00010;  // 2
    parameter preparacao        = 5'b00011;  // 3
    parameter espera            = 5'b00100;  // 4
    parameter registraAcao      = 5'b00101;  // 5
    parameter processarAcao     = 5'b00110;  // 6
    parameter aplicarDespesa    = 5'b01101;  // D
    parameter verificaPerdeu    = 5'b00111;  // 7
    parameter jogadaOuAcao      = 5'b01000;  // 8
    parameter verificaFim       = 5'b01001;  // 9
    parameter verificaFimRodada = 5'b01010;  // A
    parameter proximaJogada     = 5'b01011;  // B
    parameter novaRodada        = 5'b01100;  // C


    parameter registraDisplay   = 5'b11010;
    parameter registraDisplayF  = 5'b11011;
    parameter registraDisplayFP = 5'b11100;
    parameter fim               = 5'b11101;
    parameter fimPerdeu         = 5'b11110;

    // Variaveis de estado
    reg [4:0] Eatual, Eprox;
    reg prep_count;

    // contador para estados que duram mais de 1 ciclo de clock
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            Eatual <= start;
            prep_count <= 0;
        end
        else begin
            Eatual <= Eprox;

            // Contador ativo no estado preparacao
            if (Eatual == preparacao)
                prep_count <= prep_count + 1;
            else
                prep_count <= 0;
        end
    end

    // Logica de proximo estado
    always @* begin
        Eprox = Eatual;
        case (Eatual)
            start:            Eprox = registraModo;
            registraModo:     Eprox = (iniciar) ? inicializar : registraModo;
            inicializar:      Eprox = preparacao;
            preparacao: /*begin
                            if (prep_count == 1)
                                Eprox = espera;
                            else
                                Eprox = preparacao;
                        end */ 
                               Eprox = espera;
            espera:            Eprox = (acao_pulso) ? registraAcao : ((display_pulso) ? registraDisplay : espera);
            registraAcao:      Eprox = processarAcao;
            processarAcao:     Eprox = aplicarDespesa;
            aplicarDespesa:    Eprox = verificaPerdeu;
            verificaPerdeu:    Eprox = (fim_perdeu) ? fimPerdeu : jogadaOuAcao;
            jogadaOuAcao:      Eprox = (eh_jogada) ? verificaFim : espera;
            verificaFim:       Eprox = (fim_jogo) ? fim : verificaFimRodada;
            verificaFimRodada: Eprox = (fim_rodada) ? novaRodada : proximaJogada;
            proximaJogada:     Eprox = espera;
            novaRodada:        Eprox = espera;
            registraDisplay:   Eprox = espera;
            registraDisplayF:  Eprox = fim;
            registraDisplayFP: Eprox = fimPerdeu;
            fim:               Eprox = (iniciar) ? inicializar : ((display_pulso) ? registraDisplayF : fim);
            fimPerdeu:         Eprox = (iniciar) ? inicializar : ((display_pulso) ? registraDisplayFP : fimPerdeu);

            default:           Eprox = start;
        endcase
    end

    // Logica de saida (maquina Moore)
    always @* begin
        desligaDisplay   = (Eatual == registraModo) ? 1'b1 : 1'b0;
        rstED            = (Eatual == start) ? 1'b1 : 1'b0;
        init             = (Eatual == inicializar) ? 1'b1 : 1'b0;
        processaE        = (Eatual == processarAcao) ? 1'b1 : 1'b0;
        zeraCJ           = (Eatual == start || Eatual == preparacao || Eatual == novaRodada) ? 1'b1 : 1'b0;
        rende            = (Eatual == novaRodada) ? 1'b1 : 1'b0;
        despesa          = (Eatual == aplicarDespesa) ? 1'b1 : 1'b0;
        contaCJ          = (Eatual == proximaJogada) ? 1'b1 : 1'b0;
        zeraCR           = (Eatual == start || Eatual == preparacao) ? 1'b1 : 1'b0;
        contaCR          = (Eatual == novaRodada) ? 1'b1 : 1'b0;
        zeraD            = (Eatual == start) ? 1'b1 : 1'b0;
        registraD        = (Eatual == registraDisplay || Eatual == registraDisplayF || Eatual == registraDisplayFP) ? 1'b1 : 1'b0;
        zeraA            = (Eatual == start) ? 1'b1 : 1'b0;
        registraA        = (Eatual == registraAcao) ? 1'b1 : 1'b0;
        zeraV            = (Eatual == start) ? 1'b1 : 1'b0;
        registraV        = (Eatual == inicializar || Eatual == processarAcao || Eatual == aplicarDespesa || Eatual == novaRodada) ? 1'b1 : 1'b0;
        zeraM            = (Eatual == start) ? 1'b1 : 1'b0;
        registraM        = (Eatual == registraModo || Eatual == fim || Eatual == fimPerdeu) ? 1'b1 : 1'b0;
        /*registraV[0]     =
        registraV[1]     =
        registraV[2]     =
        registraV[3]     =
        registraV[4]     =
        registraV[5]     =*/
        terminou         = (Eatual == fim) ? 1'b1 : 1'b0;
        perdeu           = (Eatual == fimPerdeu) ? 1'b1 : 1'b0;
        
        // Saida de depuracao (estado)
        estado           = Eatual;
    end

endmodule