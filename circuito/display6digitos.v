module display6digitos (
    input [23:0] dinheiro,
    input enable,
    input [41:0] display
);

    hexa7seg d6 (
        .hexa ( dinheiro[23:20] ),
        .enable ( enable ),
        .display ( display_dinheiro[41:35] )
    );

    hexa7seg d5 (
        .hexa ( dinheiro[19:16] ),
        .enable ( enable ),
        .display ( display_dinheiro[34:28] )
    );

    hexa7seg d4 (
        .hexa ( dinheiro[15:12] ),
        .enable ( enable ),
        .display ( display_dinheiro[27:21] )
    );

    hexa7seg d3 (
        .hexa ( dinheiro[11:8] ),
        .enable ( enable ),
        .display ( display_dinheiro[20:14] )
    );

    hexa7seg d2 (
        .hexa ( dinheiro[7:4] ),
        .enable ( enable ),
        .display ( display_dinheiro[13:7] )
    );

    hexa7seg d1 (
        .hexa ( dinheiro[3:0] ),
        .enable ( enable ),
        .display ( display_dinheiro[6:0] )
    );

endmodule