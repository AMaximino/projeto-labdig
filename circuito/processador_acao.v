module processador_acao (
    input signed [20:0] saldo_in,
    input signed [20:0] salario_in,
    input signed [20:0] valorInvestido_in,
    input signed [20:0] rendimento_in,
    input signed [20:0] gastosFixos_in,
    input signed [20:0] gastosUnicos_in,
    input [5:0]  acao,
    input processaE,

    output reg signed [20:0] saldo_out,
    output reg signed [20:0] salario_out,
    output reg signed [20:0] valorInvestido_out,
    output reg signed [20:0] rendimento_out,
    output reg signed [20:0] gastosFixos_out,
    output reg signed [20:0] gastosUnicos_out
);
wire signed [20:0] custo_estudo = 20'd1000;
wire signed [20:0] investimento = 20'd1000;
wire signed [20:0] incremento_salario = 20'd1000;

//acoes = {estudar, trabalhar, investir, resgatar, comprar, vender};

localparam VENDER     = 6'b000001;
localparam COMPRAR    = 6'b000010;
localparam RESGATAR   = 6'b000100;
localparam INVESTIR   = 6'b001000;
localparam TRABALHAR  = 6'b010000;
localparam ESTUDAR    = 6'b100000;

    always @(*) begin
        // default: mantém valor
        saldo_out = saldo_in;
        salario_out = salario_in;
        valorInvestido_out = valorInvestido_in;
        rendimento_out = valorInvestido_in >> 5;
        gastosFixos_out = gastosFixos_in;
        gastosUnicos_out = gastosUnicos_in;

        if (processaE) begin
            case(acao)
                RESGATAR: begin
                    saldo_out = saldo_in + investimento;
                    valorInvestido_out = valorInvestido_in - investimento;
                end
                INVESTIR: begin
                    saldo_out = saldo_in - investimento;
                    valorInvestido_out = valorInvestido_in + investimento;
                end
                TRABALHAR: begin
                    saldo_out = saldo_in + salario_in;
                end
                ESTUDAR: begin
                    saldo_out = saldo_in - custo_estudo;
                    salario_out = salario_in + incremento_salario;
                end
            endcase
        end
    end


endmodule

/*module processador_acao (
    input clock,
    input signed [20:0] saldo_in,
    input signed [20:0] salario_in,
    input signed [20:0] valorInvestido_in,
    input signed [20:0] rendimento_in,
    input signed [20:0] gastosFixos_in,
    input signed [20:0] gastosUnicos_in,
    input [5:0]  acao,
    input init,
    input processaE,

    output reg signed [20:0] saldo_out,
    output reg signed [20:0] salario_out,
    output reg signed [20:0] valorInvestido_out,
    output reg signed [20:0] rendimento_out,
    output reg signed [20:0] gastosFixos_out,
    output reg signed [20:0] gastosUnicos_out
);
wire signed [20:0] custo_estudo = 21'd1000;
wire signed [20:0] investimento = 21'd1000;
wire signed [20:0] incremento_salario = 21'd1000;

//acoes = {estudar, trabalhar, investir, resgatar, comprar, vender};

localparam VENDER     = 6'b000001;
localparam COMPRAR    = 6'b000010;
localparam RESGATAR   = 6'b000100;
localparam INVESTIR   = 6'b001000;
localparam TRABALHAR  = 6'b010000;
localparam ESTUDAR    = 6'b100000;

    always @(posedge clock) begin
        if ( init ) begin
            saldo_out <= 21'd1500;
            salario_out <= 21'd100;
            valorInvestido_out <= 21'd0;
            rendimento_out <= 21'd0;
            gastosFixos_out <= 21'd50;
            gastosUnicos_out <= 21'd0;
        end
        else begin
            rendimento_out <= valorInvestido_in >> 5; //3,125% ao trimestre (rodada)
            if (processaE)
                case(acao)
                    VENDER: ;
                    COMPRAR: ;
                    RESGATAR: begin
                        saldo_out <= saldo_in + investimento;
                        valorInvestido_out <= valorInvestido_in - investimento;
                    end
                    INVESTIR: begin
                        saldo_out <= saldo_in - investimento;
                        valorInvestido_out <= valorInvestido_in + investimento;
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


endmodule*/