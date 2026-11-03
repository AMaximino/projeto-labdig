`timescale 1ns/1ps

module processador_acao_tb;
    reg signed [20:0] saldo;
    reg signed [20:0] salario = 21'sd64;
    reg signed [20:0] investido = 21'sd0;
    reg signed [20:0] gastos_fixos = 21'sd40;
    reg signed [20:0] gastos_unicos = 21'sd0;
    reg [5:0] acao = 6'b000010;
    reg processa = 1'b1;
    reg [9:0] seletor = 10'b0000000001;
    reg [9:0] itens = 10'b0;
    wire signed [20:0] saldo_out;
    wire signed [20:0] salario_out;
    wire signed [20:0] investido_out;
    wire signed [20:0] gastos_fixos_out;
    wire signed [20:0] gastos_unicos_out;
    wire [9:0] itens_out;
    wire aceita;

    processador_acao dut (
        .saldo_in(saldo),
        .salario_in(salario),
        .valorInvestido_in(investido),
        .gastosFixos_in(gastos_fixos),
        .gastosUnicos_in(gastos_unicos),
        .acao(acao),
        .processaE(processa),
        .seletor_item(seletor),
        .itens_in(itens),
        .saldo_out(saldo_out),
        .salario_out(salario_out),
        .valorInvestido_out(investido_out),
        .gastosFixos_out(gastos_fixos_out),
        .gastosUnicos_out(gastos_unicos_out),
        .itens_out(itens_out),
        .acao_aceita(aceita)
    );

    initial begin
        saldo = 21'sd599;
        #1;
        if (aceita || saldo_out !== saldo || itens_out !== itens ||
            gastos_unicos_out !== gastos_unicos || gastos_fixos_out !== gastos_fixos)
            $fatal(1, "Compra sem saldo suficiente alterou o estado");

        saldo = 21'sd600;
        #1;
        if (!aceita || saldo_out !== 21'sd0 || itens_out !== 10'b1 ||
            gastos_unicos_out !== 21'sd600 || gastos_fixos_out !== 21'sd76)
            $fatal(1, "Compra aprovada nao atualizou o snapshot esperado");

        $display("Compra insuficiente preserva o estado; compra valida e aceita.");
        $finish;
    end
endmodule
