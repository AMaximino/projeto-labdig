module multiplexador #(parameter N=1) (
    input signed [N-1:0] s1,
    input signed [N-1:0] s2,
    input signed [N-1:0] s3,
    input ctrl1,
    input ctrl2,
    output [N-1:0] out
);

    assign out = (ctrl1) ? s1 : ((ctrl2) ? s2 : s3);

endmodule