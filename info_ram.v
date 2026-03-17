//ram de 8x24 dual-port
//ram[0]: conta
//ram[1]: salario
//ram[2]: valor investido
//ram[3]: rendimento
//ram[4]: gastos fixos
//ram[5]: gastos unicos

module info_ram (
    input        clock,
    input        we,
    input  [23:0] data,
    input  [2:0] addr_read,
    input  [2:0] addr_write,
    output [23:0] data_out
);


    // Variavel RAM (armazena dados)
    reg [2:0] ram[23:0];

    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 8'b0;
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