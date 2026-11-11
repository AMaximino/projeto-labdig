`timescale 1ns/1ps
// Verifica o evento de telemetria 14 (seletor_item) gerado pelo fluxo_dados:
// - so informa posicoes validas (um bit ligado) estaveis por 40 ciclos;
// - ignora o "bounce" ao girar e posicoes sem item;
// - so envia com a UC em ESPERA_ACAO;
// - nao repete a mesma posicao, e reenvia apos init (nova sessao).
module seletor_item_telemetria_tb;
    reg clock = 1'b0;
    always #5 clock = ~clock;

    reg [9:0] seletor_item = 10'd0;
    reg fsm_espera_acao = 1'b1;
    reg rstED = 1'b0;
    reg init = 1'b0;

    wire telemetry_send;
    wire [7:0] telemetry_event;
    wire [3:0] telemetry_item;

    fluxo_dados dut (
        .clock          ( clock ),
        .estudar        ( 1'b0 ), .trabalhar ( 1'b0 ), .investir ( 1'b0 ),
        .resgatar       ( 1'b0 ), .comprar   ( 1'b0 ), .vender   ( 1'b0 ),
        .config_display ( 6'd0 ),
        .seletor_item   ( seletor_item ),
        .fsm_espera_acao( fsm_espera_acao ),
        .rfid_item_id   ( 4'd0 ),
        .rfid_item_valid( 1'b0 ),
        .rstED ( rstED ), .init ( init ), .processaE ( 1'b0 ), .rende ( 1'b0 ),
        .despesa ( 1'b0 ), .zeraCJ ( rstED ), .contaCJ ( 1'b0 ), .zeraCR ( rstED ),
        .contaCR ( 1'b0 ), .zeraD ( rstED ), .registraD ( 1'b0 ), .zeraA ( rstED ),
        .registraA ( 1'b0 ), .zeraV ( rstED ), .registraV ( 1'b0 ), .zeraM ( rstED ),
        .registraM ( 1'b0 ),
        .telemetry_send ( telemetry_send ),
        .telemetry_event( telemetry_event ),
        .telemetry_item ( telemetry_item )
    );

    integer pulses = 0;
    reg [3:0] last_item = 4'd0;
    reg [7:0] last_event = 8'd0;
    reg previous_send = 1'b0;
    always @(posedge clock) begin
        previous_send <= telemetry_send;
        if (telemetry_send && !previous_send) begin
            pulses = pulses + 1;
            last_item = telemetry_item;
            last_event = telemetry_event;
        end
        if (telemetry_send && previous_send) begin
            $display("FALHOU: telemetry_send ficou em 1 por dois ciclos seguidos");
            $fatal(1);
        end
    end

    task expect_pulses(input integer expected, input [3:0] item, input [255:0] what);
        begin
            if (pulses !== expected || (expected > 0 && (last_event !== 8'd14 || last_item !== item))) begin
                $display("FALHOU: %0s (pulsos=%0d esperado=%0d, evento=%0d item=%0d)",
                         what, pulses, expected, last_event, last_item);
                $fatal(1);
            end
        end
    endtask

    integer i;
    initial begin
        rstED = 1'b1; repeat (3) @(posedge clock); rstED = 1'b0;

        // Posicao valida estavel -> um evento com o item 3.
        seletor_item = 10'b0000000100;
        repeat (60) @(posedge clock);
        expect_pulses(1, 4'd3, "item 3 estavel");

        // Mesma posicao por mais tempo -> nao repete.
        repeat (100) @(posedge clock);
        expect_pulses(1, 4'd3, "sem repeticao");

        // Bounce ao girar: muda a cada 5 ciclos, passando por posicoes invalidas.
        for (i = 0; i < 20; i = i + 1) begin
            seletor_item = (i % 2) ? 10'b0000000000 : (10'b1 << (i % 10));
            repeat (5) @(posedge clock);
        end
        expect_pulses(1, 4'd3, "bounce ignorado");

        // Assenta no item 5.
        seletor_item = 10'b0000010000;
        repeat (60) @(posedge clock);
        expect_pulses(2, 4'd5, "item 5 apos girar");

        // Posicao sem item (dois bits) -> ignorada.
        seletor_item = 10'b0000110000;
        repeat (60) @(posedge clock);
        expect_pulses(2, 4'd5, "posicao invalida ignorada");

        // Fora de ESPERA_ACAO -> fica pendente ate voltar.
        fsm_espera_acao = 1'b0;
        seletor_item = 10'b1000000000;
        repeat (80) @(posedge clock);
        expect_pulses(2, 4'd5, "espera ESPERA_ACAO");
        fsm_espera_acao = 1'b1;
        repeat (3) @(posedge clock);
        expect_pulses(3, 4'd10, "envia ao voltar para ESPERA_ACAO");

        // Nova sessao (init): inicio_sessao e depois a posicao de novo.
        @(negedge clock) init = 1'b1;
        @(negedge clock) init = 1'b0;
        repeat (60) @(posedge clock);
        if (pulses !== 5 || last_event !== 8'd14 || last_item !== 4'd10) begin
            $display("FALHOU: reenvio apos init (pulsos=%0d evento=%0d item=%0d)", pulses, last_event, last_item);
            $fatal(1);
        end

        $display("PASS seletor_item: estabilidade, bounce, posicao invalida, ESPERA_ACAO e reenvio apos init.");
        $finish;
    end
endmodule
