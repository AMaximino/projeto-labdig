module processador_acao #(parameter N = 20)(
    input  [N-1:0] saldo_in,
    input  [N-1:0] salario_in,
    input  [N-1:0] valor_investido_in,
    input  [N-1:0] rendimento_in,
    input  [N-1:0] gastos_fixos_in,
    input  [N-1:0] gastos_unicos_in,
    input  [5:0]   acao,

    output reg  [N-1:0] saldo_out,
    output reg [N-1:0] salario_out,
    output reg [N-1:0] valor_investido_out,
    output reg  [N-1:0] rendimento_out,
    output reg  [N-1:0] gastos_fixos_out,
    output reg [N-1:0] gastos_unicos_out
);
wire custo_estudo = 10'b1111101000;
wire investimento = 10'b1111101000;
wire incremento_salario = 10'b1111101000;

//saldo    assign acoes = {estudar, trabalhar, investir, resgatar, comprar, vender};

always @(*) begin
    case(acao)
        0: saldo_out = saldo_out; //vender
        2: saldo_out = saldo_out; //comprar
        4: saldo_out =  saldo_in + investimento; //resgatar
        8: saldo_out =  saldo_in - investimento; //investir
        16: saldo_out = saldo_in + salario_in; //trabalhar
        32:  saldo_out = saldo_in - custo_estudo; //estudar
        default saldo_out = saldo_in;
    endcase
end

//salario

always @(*) begin
    salario_out = salario_in + incremento_salario;
end

//valor investido    assign acoes = {estudar, trabalhar, investir, resgatar, comprar, vender};

always @(*) begin
    case(acao)
        4: valor_investido_out =  valor_investido_in - investimento; //resgatar
        8: valor_investido_out =  valor_investido_in + investimento; //investir
        default: valor_investido_out = valor_investido_in;
    endcase
end

//rendimento 
always @(*) begin
    rendimento_out = valor_investido_in >> 5; //3,125% ao trimestre (rodada)
end

//gastos_fixos_out
always @(*) begin
    gastos_fixos_out = gastos_fixos_in; 
end

//gastos_unicos_out
always @(*) begin
    gastos_unicos_out = gastos_unicos_in;
end 


endmodule