module processador_acao (
    input signed [20:0] saldo_in,
    input signed [20:0] salario_in,
    input signed [20:0] valorInvestido_in,
    input signed [20:0] gastosFixos_in,
    input signed [20:0] gastosUnicos_in,
    input [5:0]  acao,
    input processaE,
    input [9:0] seletor_item, //selecionar qual item interagir para comprar ou vende-lo
    input [9:0] itens_in, //quais itens o jogador ja tem

    output reg signed [20:0] saldo_out,
    output reg signed [20:0] salario_out,
    output reg signed [20:0] valorInvestido_out,
    output reg signed [20:0] gastosFixos_out,
    output reg signed [20:0] gastosUnicos_out,
    output reg [9:0] itens_out //atualizar os itens q o jogador ja tem
);
wire signed [20:0] custo_estudo = 20'd120;      // 12.000
wire signed [20:0] investimento = 20'd10;       // 1.000
wire signed [20:0] incremento_salario = 20'd40; // 4.000

reg signed [20:0] precos_item [0:9]; //feito em reg se quiser implementar algo alteravel
reg signed [20:0] preco; // preco do item selecionado
reg signed [20:0] despesas_item [0:9]; //feito em reg se quiser implementar algo alteravel
reg signed [20:0] despesa;

wire seletor_valido;
assign seletor_valido = (seletor_item != 0) && ((seletor_item & (seletor_item - 1)) == 0); //testa se so tem um bit ligado

initial begin
    precos_item[0] = 21'd600;   // carro 60k, lembrando q é x100
    precos_item[1] = 21'd1000;  // carro 100k
    precos_item[2] = 21'd2500;  // carro 200k
    precos_item[3] = 21'd5000;  // casa 500k
    precos_item[4] = 21'd9000;  // casa 900k
    precos_item[5] = 21'd19000; // casa 1900k
    precos_item[6] = 21'd120;   // pc gamer 12k
    precos_item[7] = 21'd80;    // coleçao de jogos de tabuleiro 8k -> implementar futuramente algo q de pra ficar comprando e faça show de luz
    precos_item[8] = 21'd420;   // coleçao de legos 42k -> implementar futuramente algo q de pra ficar comprando e faça show de luz
    precos_item[9] = 21'd350;   // viajar pelo mundo 35k -> implementar futuramente algo q de pra ficar comprando e faça show de luz
end

initial begin
    despesas_item[0] = 21'd36;  // carro 60k -> despesa 3600
    despesas_item[1] = 21'd48;  // carro 100k -> despesa 4800
    despesas_item[2] = 21'd80;  // carro 200k -> despesa 8000
    despesas_item[3] = 21'd24;   // casa 500k -> despesa 2400
    despesas_item[4] = 21'd32;   // casa 900k -> despesa 3200
    despesas_item[5] = 21'd60;  // casa 1900k -> despesa 6000
    despesas_item[6] = 21'd0;   // pc gamer 12k -> sem despesa
    despesas_item[7] = 21'd0;   // colecao de jogos de tabuleiro 8k -> sem despesa
    despesas_item[8] = 21'd0;   // colecao de legos 42k -> sem despesa
    despesas_item[9] = 21'd0;   // viajar pelo mundo 35k -> sem despesa
end

always @(*) begin
    case (seletor_item)
        10'b0000000001: preco = precos_item[0];
        10'b0000000010: preco = precos_item[1];
        10'b0000000100: preco = precos_item[2];
        10'b0000001000: preco = precos_item[3];
        10'b0000010000: preco = precos_item[4];
        10'b0000100000: preco = precos_item[5];
        10'b0001000000: preco = precos_item[6];
        10'b0010000000: preco = precos_item[7];
        10'b0100000000: preco = precos_item[8];
        10'b1000000000: preco = precos_item[9];
        default: preco = 0;
    endcase 
end


always @(*) begin
    case (seletor_item)
        10'b0000000001: despesa = despesas_item[0];
        10'b0000000010: despesa = despesas_item[1];
        10'b0000000100: despesa = despesas_item[2];
        10'b0000001000: despesa = despesas_item[3];
        10'b0000010000: despesa = despesas_item[4];
        10'b0000100000: despesa = despesas_item[5];
        10'b0001000000: despesa = despesas_item[6];
        10'b0010000000: despesa = despesas_item[7];
        10'b0100000000: despesa = despesas_item[8];
        10'b1000000000: despesa = despesas_item[9];
        default: despesa = 0;
    endcase 
end

//acoes = {estudar, trabalhar, investir, resgatar, comprar, vender};

localparam VENDER     = 6'b000001;
localparam COMPRAR    = 6'b000010;
localparam RESGATAR   = 6'b000100;
localparam INVESTIR   = 6'b001000;
localparam TRABALHAR  = 6'b010000;
localparam ESTUDAR    = 6'b100000;

    always @(*) begin
        // default: mantem valor
        saldo_out = saldo_in;
        salario_out = salario_in;
        valorInvestido_out = valorInvestido_in;
        gastosFixos_out = gastosFixos_in;
        gastosUnicos_out = gastosUnicos_in;
        itens_out = itens_in;

        if (processaE) begin
            case(acao)
                VENDER: begin
                    if (seletor_valido && ((itens_in & seletor_item) != 10'b0)) begin //ve se é valido (1 bit do seletor ligado) e se ele tem o item
                        saldo_out = saldo_in + preco; //quando compra um item, tem que descontar o custo do item do saldo
                        gastosFixos_out = gastosFixos_in - despesa;
                        gastosUnicos_out = gastosUnicos_in - preco;
                        itens_out = itens_in & (~seletor_item); //atualiza os itens q o jogador tem, removendo o item selecionado
                    end
                end
                COMPRAR: begin
                    if (seletor_valido && ((itens_in & seletor_item) == 10'b0)) begin //ve se ele nao tem o item ainda
                        saldo_out = saldo_in - preco; //quando compra um item, tem que descontar o custo do item do saldo
                        gastosFixos_out = gastosFixos_in + despesa;
                        gastosUnicos_out = gastosUnicos_in + preco;
                        itens_out = itens_in | seletor_item; //atualiza os itens q o jogador tem, adicionando o item selecionado
                    end
                end
                RESGATAR: begin
                    if (valorInvestido_in > investimento ) begin
                        saldo_out = saldo_in + investimento;
                        valorInvestido_out = valorInvestido_in - investimento;
                    end
                    else begin
                        saldo_out = saldo_in + valorInvestido_in;
                        valorInvestido_out = 21'b0;
                    end
                end
                INVESTIR: begin
                    saldo_out = saldo_in - investimento;
                    valorInvestido_out = valorInvestido_in + investimento;
                end
                TRABALHAR: begin
                    saldo_out = saldo_in + salario_in;
                end
                ESTUDAR: begin
                    saldo_out = saldo_in - custo_estudo;
                    salario_out = salario_in + incremento_salario;
                end
            endcase
        end
    end


endmodule