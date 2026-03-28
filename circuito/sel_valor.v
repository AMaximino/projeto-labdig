module sel_valor (
    input  [20:0] saldo_init,
    input  [20:0] salario_init,
    input  [20:0] valorInvestido_init,
    input  [20:0] rendimento_init,
    input  [20:0] gastosFixos_init,
    input  [20:0] gastosUnicos_init,
    input  [20:0] saldo_proc,
    input  [20:0] salario_proc,
    input  [20:0] valorInvestido_proc,
    input  [20:0] rendimento_proc,
    input  [20:0] gastosFixos_proc,
    input  [20:0] gastosUnicos_proc,
    input  [20:0] saldo_evento,
    input  [20:0] salario_evento,
    input  [20:0] valorInvestido_evento,
    input  [20:0] rendimento_evento,
    input  [20:0] gastosFixos_evento,
    input  [20:0] gastosUnicos_evento,
    input         init,
    input         processaE,
    output [20:0] saldo_out,
    output [20:0] salario_out,
    output [20:0] valorInvestido_out,
    output [20:0] rendimento_out,
    output [20:0] gastosFixos_out,
    output [20:0] gastosUnicos_out
);

    multiplexador muxSaldo (
        .s1    ( saldo_init ),
        .s2    ( saldo_proc ),
        .s3    ( saldo_evento ),
        .ctrl1 ( init ),
        .ctrl2 ( processaE ),
        .out   ( saldo_out )
    );
    multiplexador muxSalario (
        .s1    ( salario_init ),
        .s2    ( salario_proc ),
        .s3    ( salario_evento ),
        .ctrl1 ( init ),
        .ctrl2 ( processaE ),
        .out   ( salario_out )
    );
    multiplexador muxValorInvestido (
        .s1    ( valorInvestido_init ),
        .s2    ( valorInvestido_proc ),
        .s3    ( valorInvestido_evento ),
        .ctrl1 ( init ),
        .ctrl2 ( processaE ),
        .out   ( valorInvestido_out )
    );
    multiplexador muxRendimento (
        .s1    ( rendimento_init ),
        .s2    ( rendimento_proc ),
        .s3    ( rendimento_evento ),
        .ctrl1 ( init ),
        .ctrl2 ( processaE ),
        .out   ( rendimento_out )
    );
    multiplexador muxGastosFixos (
        .s1    ( gastosFixos_init ),
        .s2    ( gastosFixos_proc ),
        .s3    ( gastosFixos_evento ),
        .ctrl1 ( init ),
        .ctrl2 ( processaE ),
        .out   ( gastosFixos_out )
    );
    multiplexador muxGastosUnicos (
        .s1    ( gastosUnicos_init ),
        .s2    ( gastosUnicos_proc ),
        .s3    ( gastosUnicos_evento ),
        .ctrl1 ( init ),
        .ctrl2 ( processaE ),
        .out   ( gastosUnicos_out )
    );
    

endmodule