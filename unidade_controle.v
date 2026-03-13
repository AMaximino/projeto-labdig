 /*---------------Laboratorio Digital-------------------------------------
 * Arquivo   : unidade_controle.v
 * Projeto   : Experiencia 6 - Projeto do
 *             Jogo do Desafio da Memória
 *---------------------------------------------------------------------------------------------------------------------
 * Descricao : Unidade de controle do circuito para um jogo de memória.
 *             
 *---------------------------------------------------------------------------------------------------------------------
 * Revisoes  :
 *     Data        Versao  Autor                                                  Descricao
 *     29/01/2026  1.0     André Maximino                                         criacao
 *     04/02/2026  2.0     André Maximino, Gabriel Prodossimo e Sophia Mariano    implementação do Modo
 *     04/02/2026  3.0     André Maximino, Gabriel Prodossimo e Sophia Mariano    implementação do Timeout
 *     10/02/2026  4.0     André Maximino, Gabriel Prodossimo e Sophia Mariano    implementação da lógica de rodadas
 *     21/02/2026  5.0     André Maximino                                         mudanças para a funcionalidade 
 *                                                                                "Voce inventa a sequencia
 *---------------------------------------------------------------------------------------------------------------------
 */


module unidade_controle (
    input      clock,
    input      reset,
    input      jogar,
    input      acao_pulso,
    input      eh_jogada,
    input      fim_rodada,
    input      fim_jogo,
    input      fim_perdeu,

    output reg rstED,
    output reg processar_acao,
    output reg extrato_fixo,
    output reg zeraCJ,
    output reg contaCJ,
    output reg zeraR,
    output reg registraR,
    output reg zeraCR,
    output reg contaCR,
    //output reg ligaLED,
    output reg terminou,
    output reg perdeu,
    output reg [4:0] estado //depuracao
    //output reg zeraM,
    //output reg registraM,
);

    // Define estados
    parameter inicial         = 5'b00000;  // 0
    parameter standby         = 5'b00001;  // 1
    parameter preparacao      = 5'b00010;  // 2
    parameter verificaPerdeu  = 5'b00011;  // 3
    parameter espera          = 5'b00100;  // 4
    parameter registra        = 5'b00101;  // 5
    parameter processarAcao   = 5'b00110;  // 6
    parameter extratoFixo     = 5'b00111;  // 7
    parameter verificaRodada  = 5'b01000;  // 8
    parameter proximaJogada   = 5'b01001;  // 9
    parameter novaRodada      = 5'b01010;  // A
    parameter verificaFim     = 5'b01011;  // B
    parameter fim             = 5'b01100;  // C
    parameter fimPerdeu       = 5'b01101;  // D

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
            inicial:        Eprox = standby;
            standby:        Eprox = (jogar) ? preparacao : standby;
            preparacao: begin
                if (prep_count == 1)
                    Eprox = (j_inicial) ? esperaPJogada  : escreveVermelho;
                else
                    Eprox = preparacao;
            end
            verificaPerdeu:  Eprox = (fim_perdeu) ? fimPerdeu : espera;
            registra:        Eprox = processarAcao;
            processarAcao:   Eprox = (eh_jogada) ? extratoFixo : verificaPerdeu;
            extratoFixo:     Eprox = verificaRodada;
            verificaRodada:  Eprox = (fim_rodada) ? novaRodada : proximaJogada; 
            proximaJogada:   Eprox = verificaPerdeu;
            novaRodada:      Eprox = verificaFim;
            verificaFim:     Eprox = (fim_jogo) ? fim : verificaPerdeu;
            fim:             Eprox = jogar ? preparacao : fim;
            fimPerdeu:       Eprox = jogar ? preparacao : fimPerdeu;
            default:         Eprox = inicial;
        endcase
    end

    // Logica de saida (maquina Moore)
    always @* begin
        rstED            = (Eatual == inicial) ? 1'b1 : 1'b0;
        processar_acao   = (Eatual == processarAcao) ? 1'b1 : 1'b0;
        extrato_fixo     = (Eatual == extratoFixo) ? 1'b1 : 1'b0;
        zeraCJ           = (Eatual == novaRodada) ? 1'b1 : 1'b0;
        contaCJ          = (Eatual == proximaJogada || Eatual == preparacao) ? 1'b1 : 1'b0;
        zeraR            = (Eatual == inicial) ? 1'b1 : 1'b0;
        registraR        = (Eatual == registra) ? 1'b1 : 1'b0;
        zeraCR           = (Eatual == preparacao) ? 1'b1 : 1'b0;
        contaCR          = (Eatual == novaRodada) ? 1'b1 : 1'b0;
        terminou         = (Eatual == fim) ? 1'b1 : 1'b0;
        fim_perdeu       = (Eatual == fimPerdeu) ? 1'b1 : 1'b0;
        
        // Saida de depuracao (estado)
        estado           = Eatual;
    end

endmodule