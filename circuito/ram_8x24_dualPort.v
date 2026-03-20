//ram de 8x24 dual-port
//ram[0]: conta
//ram[1]: salario
//ram[2]: valor investido
//ram[3]: rendimento
//ram[4]: gastos fixos
//ram[5]: gastos unicos

module ram_8x24_dualPort (
    input             clock,
    input             we,
    input      [23:0] data,
    input      [2:0]  addr_read,
    input      [2:0]  addr_write,
    output reg [23:0] data_out
);
    integer i;

    // Variavel RAM (armazena dados)
    reg [23:0] ram[0:7];

    // inicialização
    initial begin
        for (i = 0; i < 8; i = i + 1)
            ram[i] = 24'b0;
    end

    always @ (posedge clock)
    begin
        // Escrita da memoria
        if (we)
            ram[addr_write] <= data;
        // Leitura da memoria
        data_out <= ram[addr_read];
    end

endmodule