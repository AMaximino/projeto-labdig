module display6digitos (
    input [23:0] dinheiro,
    input enable,
    output [41:0] display
);

    dec7seg d6 (
        .dec     ( dinheiro[23:20] ),
        .enable  ( enable ),
        .display ( display[41:35] )
    );

    dec7seg d5 (
        .dec     ( dinheiro[19:16] ),
        .enable  ( enable ),
        .display ( display[34:28] )
    );

    dec7seg d4 (
        .dec     ( dinheiro[15:12] ),
        .enable  ( enable ),
        .display ( display[27:21] )
    );

    dec7seg d3 (
        .dec     ( dinheiro[11:8] ),
        .enable  ( enable ),
        .display ( display[20:14] )
    );

    dec7seg d2 (
        .dec     ( dinheiro[7:4] ),
        .enable  ( enable ),
        .display ( display[13:7] )
    );

    dec7seg d1 (
        .dec     ( dinheiro[3:0] ),
        .enable  ( enable ),
        .display ( display[6:0] )
    );

endmodule