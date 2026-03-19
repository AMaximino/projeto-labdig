module unidade_controle ( //provisoria
    input      clock,
    input      reset,
    input      iniciar,
    input      jogada_pulso,
    input      fim_jogo,
    input      fim_perdeu,
    input      fim_rodada,

    output reg rstED,
    output reg we,
    output reg zeraCJ,
    output reg contaCJ,
    output reg zeraCR,
    output reg contaCR,
    output reg registraD,

    output reg terminou,
    output reg perdeu,
    output reg [4:0] estado
);

    // Define estados
    parameter inicial           = 5'b00000;  // 0
    parameter standby           = 5'b00001;  // 1
    parameter preparacao        = 5'b00010;  // 2
    parameter espera            = 5'b00011;  // 3
    parameter verificaPerdeu    = 5'b00100;  // 4
    parameter verificaFim       = 5'b00101;  // 5
    parameter verificaFimRodada = 5'b00110;  // 6
    parameter novaRodada        = 5'b00111;  // 7
    parameter proximaJogada     = 5'b01000;  // 8
    parameter fim               = 5'b01001;  // 9
    parameter fimPerdeu         = 5'b01010;  // A

    // Variaveis de estado
    reg [4:0] Eatual, Eprox;
    reg prep_count;

    // contador para estados que duram mais de 1 ciclo de clock
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            Eatual <= inicial;
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
            inicial:          Eprox = standby;
            standby:          Eprox = (iniciar) ? preparacao : standby;
            preparacao: begin
                if (prep_count == 1)
                    Eprox = espera;
                else
                    Eprox = preparacao;
            end
            espera:            Eprox = (jogada_pulso) ? verificaPerdeu : espera;
            verificaPerdeu:    Eprox = (fim_perdeu) ? fimPerdeu : verificaFim;
            verificaFim:       Eprox = (fim_jogo) ? fim : verificaFimRodada;
            verificaFimRodada: Eprox = (fim_rodada) ? novaRodada : proximaJogada;
            novaRodada:        Eprox = espera;
            proximaJogada:     Eprox = espera;
            fim:               Eprox = (iniciar) ? preparacao : fim;
            fimPerdeu:         Eprox = (iniciar) ? preparacao : fimPerdeu;
            default:         Eprox = inicial;
        endcase
    end

    // Logica de saida (maquina Moore)
    always @* begin
        rstED            = (Eatual == inicial) ? 1'b1 : 1'b0;
        we               = 1'b0;
        zeraCJ           = (Eatual == preparacao || Eatual == novaRodada) ? 1'b1 : 1'b0;
        contaCJ          = (Eatual == proximaJogada) ? 1'b1 : 1'b0;
        zeraCR           = (Eatual == preparacao) ? 1'b1 : 1'b0;
        contaCR          = (Eatual == novaRodada) ? 1'b1 : 1'b0;
        registraD        = 1'b0;
        terminou         = (Eatual == fim) ? 1'b1 : 1'b0;
        perdeu           = (Eatual == fimPerdeu) ? 1'b1 : 1'b0;
        
        // Saida de depuracao (estado)
        estado           = Eatual;
    end

endmodule