module sel_dinheiro (
    input  [19:0] saldo,
    input  [19:0] salario,
    input  [19:0] valorInvestido,
    input  [19:0] rendimento,
    input  [19:0] gastosFixos,
    input  [19:0] gastosUnicos,
    input  [5:0]  config_display,
    output [23:0] dinheiro
);

    reg [19:0] dinheiro_bin;
    always @(*) begin
        case (config_display)
            6'b000001: dinheiro_bin = gastosUnicos;
            6'b000010: dinheiro_bin = gastosFixos;
            6'b000100: dinheiro_bin = rendimento;
            6'b001000: dinheiro_bin = valorInvestido;
            6'b010000: dinheiro_bin = salario;
            6'b100000: dinheiro_bin = saldo;
            default: dinheiro_bin = saldo;
        endcase
    end

    bin2bcd #(
        .BIN_WIDTH(20),
        .DIGITS(6)
    ) bin2bcd (
        .bin ( dinheiro_bin ),
        .bcd ( dinheiro )
    );

endmodule