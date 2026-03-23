module processador_acao #(parameter N = 20)(
    input clock,
    input  [N-1:0] saldo_in,
    input  [N-1:0] salario_in,
    input  [N-1:0] valor_investido_in,
    input  [N-1:0] rendimento_in,
    input  [N-1:0] gastos_fixos_in,
    input  [N-1:0] gastos_unicos_in,
    input  [5:0]   acao,
    input init,
    input processaE,

    output reg  [N-1:0] saldo_out,
    output reg  [N-1:0] salario_out,
    output reg  [N-1:0] valor_investido_out,
    output reg  [N-1:0] rendimento_out,
    output reg  [N-1:0] gastos_fixos_out,
    output reg  [N-1:0] gastos_unicos_out
);
wire [N-1:0] custo_estudo = 20'd1000;
wire [N-1:0] investimento = 20'd1000;
wire [N-1:0] incremento_salario = 20'd1000;

//saldo    assign acoes = {estudar, trabalhar, investir, resgatar, comprar, vender};

localparam VENDER     = 6'b000001;
localparam COMPRAR    = 6'b000010;
localparam RESGATAR   = 6'b000100;
localparam INVESTIR   = 6'b001000;
localparam TRABALHAR  = 6'b010000;
localparam ESTUDAR    = 6'b100000;

always @(posedge clock) begin
    if ( init ) begin
        saldo_out <= 20'd1500;
        salario_out <= 20'd100;
        valor_investido_out <= 20'd0;
        gastos_fixos_out <= 20'd50;
        rendimento_out <= 20'd0;
        gastos_unicos_out <= 20'd0;
    end
    else begin
        rendimento_out <= valor_investido_in >> 5; //3,125% ao trimestre (rodada)
        if (processaE)
            case(acao)
                VENDER: ;
                COMPRAR: ;
                RESGATAR: begin
                    saldo_out <= saldo_in + investimento;
                    valor_investido_out <= valor_investido_in - investimento;
                end
                INVESTIR: begin
                    saldo_out <= saldo_in - investimento;
                    valor_investido_out <= valor_investido_in + investimento;
                end
                TRABALHAR: begin
                    saldo_out <= saldo_in + salario_in;
                end
                ESTUDAR: begin
                    saldo_out <= saldo_in - custo_estudo;
                    salario_out <= salario_in + incremento_salario;
                end
            endcase
    end
end


endmodule