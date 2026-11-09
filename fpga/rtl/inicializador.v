module inicializador (
    output signed [20:0] saldo,
    output signed [20:0] salario,
    output signed [20:0] valorInvestido,
    output signed [20:0] gastosFixos,
    output signed [20:0] gastosUnicos,
    output [9:0] itens
);


assign saldo = 21'd150;        // 15000
assign salario = 21'd64;       // 6400 por quadrimestre
assign valorInvestido = 21'd0; // 0
assign gastosFixos = 21'd40;   // 4000 por quadrimestre
assign gastosUnicos = 21'd0;   // 0
assign itens = 10'd0;

endmodule