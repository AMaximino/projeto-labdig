module sel_valor (
    input  [20:0] saldo_init,
    input  [20:0] salario_init,
    input  [20:0] valorInvestido_init,
    input  [20:0] gastosFixos_init,
    input  [20:0] gastosUnicos_init,
    input  [9:0]  itens_init,
    input  [20:0] saldo_proc,
    input  [20:0] salario_proc,
    input  [20:0] valorInvestido_proc,
    input  [20:0] gastosFixos_proc,
    input  [20:0] gastosUnicos_proc,
    input  [9:0]  itens_proc,
    input  [20:0] saldo_evento,
    input  [20:0] salario_evento,
    input  [20:0] valorInvestido_evento,
    input  [20:0] gastosFixos_evento,
    input  [20:0] gastosUnicos_evento,
    input         init,
    input         processaE,
    output [20:0] saldo_out,
    output [20:0] salario_out,
    output [20:0] valorInvestido_out,
    output [20:0] gastosFixos_out,
    output [20:0] gastosUnicos_out,
    output [9:0]  itens_out
);

    multiplexador #(.N(21)) muxSaldo (
        .s1    ( saldo_init ),
        .s2    ( saldo_proc ),
        .s3    ( saldo_evento ),
        .ctrl1 ( init ),
        .ctrl2 ( processaE ),
        .out   ( saldo_out )
    );
    multiplexador #(.N(21)) muxSalario (
        .s1    ( salario_init ),
        .s2    ( salario_proc ),
        .s3    ( salario_evento ),
        .ctrl1 ( init ),
        .ctrl2 ( processaE ),
        .out   ( salario_out )
    );
    multiplexador #(.N(21)) muxValorInvestido (
        .s1    ( valorInvestido_init ),
        .s2    ( valorInvestido_proc ),
        .s3    ( valorInvestido_evento ),
        .ctrl1 ( init ),
        .ctrl2 ( processaE ),
        .out   ( valorInvestido_out )
    );
    multiplexador #(.N(21)) muxGastosFixos (
        .s1    ( gastosFixos_init ),
        .s2    ( gastosFixos_proc ),
        .s3    ( gastosFixos_evento ),
        .ctrl1 ( init ),
        .ctrl2 ( processaE ),
        .out   ( gastosFixos_out )
    );
    multiplexador #(.N(21)) muxGastosUnicos (
        .s1    ( gastosUnicos_init ),
        .s2    ( gastosUnicos_proc ),
        .s3    ( gastosUnicos_evento ),
        .ctrl1 ( init ),
        .ctrl2 ( processaE ),
        .out   ( gastosUnicos_out )
    );
    multiplexador #(.N(10)) muxItens (
        .s1    ( itens_init ),
        .s2    ( itens_proc ),
        .s3    ( itens_proc ),
        .ctrl1 ( init ),
        .ctrl2 ( processaE ),
        .out   ( itens_out )
    );
    

endmodule