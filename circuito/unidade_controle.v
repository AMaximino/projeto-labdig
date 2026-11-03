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

    localparam [4:0] INICIO                    = 5'b00000;
    localparam [4:0] ESPERA_INICIO             = 5'b00001;
    localparam [4:0] INICIALIZA_JOGO           = 5'b00010;
    localparam [4:0] PREPARA_JOGO              = 5'b00011;
    localparam [4:0] ESPERA_ACAO               = 5'b00100;
    localparam [4:0] REGISTRA_ACAO             = 5'b00101;
    localparam [4:0] PROCESSA_ACAO             = 5'b00110;
    localparam [4:0] APLICA_DESPESA            = 5'b01101;
    localparam [4:0] VERIFICA_FALENCIA         = 5'b00111;
    localparam [4:0] VERIFICA_JOGADA           = 5'b01000;
    localparam [4:0] VERIFICA_FIM_JOGO         = 5'b01001;
    localparam [4:0] VERIFICA_FIM_RODADA       = 5'b01010;
    localparam [4:0] AVANCA_JOGADA             = 5'b01011;
    localparam [4:0] AVANCA_RODADA             = 5'b01100;
    localparam [4:0] VERIFICA_FALENCIA_DESPESA = 5'b01110;
    localparam [4:0] REGISTRA_DISPLAY          = 5'b11010;
    localparam [4:0] REGISTRA_DISPLAY_FINAL    = 5'b11011;
    localparam [4:0] REGISTRA_DISPLAY_FALENCIA = 5'b11100;
    localparam [4:0] FIM_JOGO                  = 5'b11101;
    localparam [4:0] FIM_FALENCIA              = 5'b11110;

    reg [4:0] estado_atual, proximo_estado;
    reg prep_count;

    // contador para estados que duram mais de 1 ciclo de clock
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            estado_atual <= INICIO;
            prep_count <= 0;
        end
        else begin
            estado_atual <= proximo_estado;

            // Contador ativo enquanto o jogo esta sendo preparado.
            if (estado_atual == PREPARA_JOGO)
                prep_count <= prep_count + 1;
            else
                prep_count <= 0;
        end
    end

    // Logica de proximo estado
    always @* begin
        proximo_estado = estado_atual;
        case (estado_atual)
            INICIO:                    proximo_estado = ESPERA_INICIO;
            ESPERA_INICIO:             proximo_estado = iniciar ? INICIALIZA_JOGO : ESPERA_INICIO;
            INICIALIZA_JOGO:           proximo_estado = PREPARA_JOGO;
            PREPARA_JOGO:              proximo_estado = ESPERA_ACAO;
            ESPERA_ACAO:               proximo_estado = acao_pulso ? REGISTRA_ACAO :
                                                        display_pulso ? REGISTRA_DISPLAY : ESPERA_ACAO;
            REGISTRA_ACAO:             proximo_estado = PROCESSA_ACAO;
            PROCESSA_ACAO:             proximo_estado = VERIFICA_FALENCIA;
            VERIFICA_FALENCIA:         proximo_estado = fim_perdeu ? FIM_FALENCIA : VERIFICA_JOGADA;
            VERIFICA_JOGADA:           proximo_estado = eh_jogada ? APLICA_DESPESA : ESPERA_ACAO;
            APLICA_DESPESA:            proximo_estado = VERIFICA_FALENCIA_DESPESA;
            VERIFICA_FALENCIA_DESPESA: proximo_estado = fim_perdeu ? FIM_FALENCIA : VERIFICA_FIM_JOGO;
            VERIFICA_FIM_JOGO:         proximo_estado = fim_jogo ? FIM_JOGO : VERIFICA_FIM_RODADA;
            VERIFICA_FIM_RODADA:       proximo_estado = fim_rodada ? AVANCA_RODADA : AVANCA_JOGADA;
            AVANCA_JOGADA:             proximo_estado = ESPERA_ACAO;
            AVANCA_RODADA:             proximo_estado = ESPERA_ACAO;
            REGISTRA_DISPLAY:          proximo_estado = ESPERA_ACAO;
            REGISTRA_DISPLAY_FINAL:    proximo_estado = FIM_JOGO;
            REGISTRA_DISPLAY_FALENCIA: proximo_estado = FIM_FALENCIA;
            FIM_JOGO:                  proximo_estado = iniciar ? INICIALIZA_JOGO :
                                                        display_pulso ? REGISTRA_DISPLAY_FINAL : FIM_JOGO;
            FIM_FALENCIA:              proximo_estado = iniciar ? INICIALIZA_JOGO :
                                                        display_pulso ? REGISTRA_DISPLAY_FALENCIA : FIM_FALENCIA;
            default:                   proximo_estado = INICIO;
        endcase
    end

    // Saidas Moore: dependem somente do estado atual.
    always @* begin
        desligaDisplay   = estado_atual == ESPERA_INICIO;
        rstED            = estado_atual == INICIO;
        init             = estado_atual == INICIALIZA_JOGO;
        processaE        = estado_atual == PROCESSA_ACAO;
        zeraCJ           = estado_atual == INICIO || estado_atual == PREPARA_JOGO ||
                           estado_atual == AVANCA_RODADA;
        rende            = estado_atual == AVANCA_RODADA;
        despesa          = estado_atual == APLICA_DESPESA;
        contaCJ          = estado_atual == AVANCA_JOGADA;
        zeraCR           = estado_atual == INICIO || estado_atual == PREPARA_JOGO;
        contaCR          = estado_atual == AVANCA_RODADA;
        zeraD            = estado_atual == INICIO;
        registraD        = estado_atual == REGISTRA_DISPLAY ||
                           estado_atual == REGISTRA_DISPLAY_FINAL ||
                           estado_atual == REGISTRA_DISPLAY_FALENCIA;
        zeraA            = estado_atual == INICIO;
        registraA        = estado_atual == REGISTRA_ACAO;
        zeraV            = estado_atual == INICIO;
        registraV        = estado_atual == INICIALIZA_JOGO ||
                           estado_atual == PROCESSA_ACAO ||
                           estado_atual == APLICA_DESPESA ||
                           estado_atual == AVANCA_RODADA;
        zeraM            = estado_atual == INICIO;
        registraM        = estado_atual == ESPERA_INICIO ||
                           estado_atual == FIM_JOGO ||
                           estado_atual == FIM_FALENCIA;
        terminou         = estado_atual == FIM_JOGO;
        perdeu           = estado_atual == FIM_FALENCIA;
        
        // Saida de depuracao (estado)
        estado           = estado_atual;
    end

endmodule