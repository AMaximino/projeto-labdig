module multiplexador (
    input signed [20:0] s1,
    input signed [20:0] s2,
    input signed [20:0] s3,
    input ctrl1,
    input ctrl2,
    output [20:0] out
);

    assign out = (ctrl1) ? s1 : ((ctrl2) ? s2 : s3);

endmodule