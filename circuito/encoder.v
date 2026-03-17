module encoder #(parameter N = 1)(
    input  [N-1:0] entrada,
    output reg [$clog2(N)-1:0] saida
);

integer i;

always @(*) begin
    saida = 0;
    for (i = 0; i < N; i = i + 1)
        if (entrada[i])
            saida = i;
end

endmodule