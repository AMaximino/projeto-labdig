/*------------------------------------------------------------------------------------------
  --Arquivo   : display_4_digitos
  --Projeto   : Aventura Financeira
 -----------------------------------------------------------------------------------------
  --Descricao : decodificador hexadecimal para 
  --            display de 7 segmentos com 12 fios
  --
  --entrada : quatro valores de 4 bits a serem mostrados
  --saida   : sseg - codigo de 7 bits para display de 4 digitos
 -----------------------------------------------------------------------------------------
  --Revisoes  :
  --    Data        Versao  Autor                                            Descricao
  --    13/09/2025  1.0     Canal WR Kits                                     criacao
  --    13/03/2026  2.0     André, Gabriel e Sophia                           conversão para verilog
  --    13/03/2026  3.0     André, Gabriel e Sophia                           adição das entradas dinamicas
  -----------------------------------------------------------------------------------------
*/


module display_4_digitos (
    input wire clk,                  // Clock de 50MHz
    input wire [3:0] valor3,         // Valor Hexa para o dígito 3 (Milhar)
    input wire [3:0] valor2,         // Valor Hexa para o dígito 2 (Centena)
    input wire [3:0] valor1,         // Valor Hexa para o dígito 1 (Dezena)
    input wire [3:0] valor0,         // Valor Hexa para o dígito 0 (Unidade)
    output reg [6:0] display,        // Segmentos A-G
    output reg [3:0] catodos         // Seletor de qual display ligar
);

    // Registradores internos para temporização
    reg [16:0] counter_aux = 0;
    reg clk_multiplex = 0;
    reg [1:0] seletor_digito = 0;
    reg [3:0] hexa_atual;

    // --- 1. Divisor de Frequência (~1ms para cada dígito) ---
    always @(posedge clk) begin
        if (counter_aux == 49999) begin // 50.000 ciclos de 20ns = 1ms
            counter_aux <= 0;
            clk_multiplex <= ~clk_multiplex;
        end else begin
            counter_aux <= counter_aux + 1;
        end
    end

    //2. Contador de Varredura (Troca o dígito ativo) ---
    always @(posedge clk_multiplex) begin
        seletor_digito <= seletor_digito + 1;
    end

    // 3. Seletor de Dados e Catodos ---
    always @(*) begin
        case (seletor_digito)
            2'b00: begin
                hexa_atual = valor0;
                catodos = 4'b0001; // Liga display 0 (Unidade)
            end
            2'b01: begin
                hexa_atual = valor1;
                catodos = 4'b0010; // Liga display 1 (Dezena)
            end
            2'b10: begin
                hexa_atual = valor2;
                catodos = 4'b0100; // Liga display 2 (Centena)
            end
            2'b11: begin
                hexa_atual = valor3;
                catodos = 4'b1000; // Liga display 3 (Milhar)
            end
            default: begin
                hexa_atual = 4'h0;
                catodos = 4'b0000;
            end
        endcase
    end

    // --- 4. Conversor Hexa para 7 Segmentos (Sua lógica ajustada) ---
    // Nota: Ajustei para 0 = aceso e 1 = apagado, comum em muitas placas
    // Se a sua placa for o contrário, basta inverter os bits.
    always @(*) begin
        case (hexa_atual)
            4'h0: display = 7'b1000000;
            4'h1: display = 7'b1111001;
            4'h2: display = 7'b0100100;
            4'h3: display = 7'b0110000;
            4'h4: display = 7'b0011001;
            4'h5: display = 7'b0010010;
            4'h6: display = 7'b0000010;
            4'h7: display = 7'b1111000;
            4'h8: display = 7'b0000000;
            4'h9: display = 7'b0010000;
            4'ha: display = 7'b0001000;
            4'hb: display = 7'b0000011;
            4'hc: display = 7'b1000110;
            4'hd: display = 7'b0100001;
            4'he: display = 7'b0000110;
            4'hf: display = 7'b0001110;
            default: display = 7'b1111111;
        endcase
    end

endmodule