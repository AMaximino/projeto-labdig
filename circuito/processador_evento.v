module processador_evento (
    input signed [20:0] saldo_in,
    input signed [20:0] salario_in,
    input signed [20:0] valorInvestido_in,
    input signed [20:0] rendimento_in,
    input signed [20:0] gastosFixos_in,
    input signed [20:0] gastosUnicos_in,
    input rende,
    input despesa,
    output reg signed [20:0] saldo_out,
    output reg signed [20:0] salario_out,
    output reg signed [20:0] valorInvestido_out,
    output reg signed [20:0] rendimento_out,
    output reg signed [20:0] gastosFixos_out,
    output reg signed [20:0] gastosUnicos_out
);

    always @(*) begin
        // default: mantem valor
        saldo_out = saldo_in;
        salario_out = salario_in;
        valorInvestido_out = valorInvestido_in;
        rendimento_out = valorInvestido_in >> 5; //3,125% ao trimestre (rodada)
        gastosFixos_out = gastosFixos_in;
        gastosUnicos_out = gastosUnicos_in;
        if ( rende ) begin
            valorInvestido_out = valorInvestido_in + rendimento_in;
        end
        if ( despesa ) begin
            saldo_out = saldo_in - gastosFixos_in;
        end
    end

endmodule