#pragma once

// Copie este arquivo para config.h e preencha os valores da sua rede.
// Nao coloque config.h no Git: ele contem credenciais locais.
#define AEF_WIFI_SSID "NOME_DA_REDE_WIFI"
#define AEF_WIFI_PASSWORD "SENHA_DA_REDE_WIFI"

// IPv4 do computador que executa/encaminha o broker MQTT, na rede Wi-Fi.
// Nao use localhost: esse nome apontaria para a propria ESP32.
#define AEF_MQTT_HOST "192.168.1.100"
#define AEF_MQTT_PORT 1883
#define AEF_MQTT_USERNAME ""
#define AEF_MQTT_PASSWORD ""

#define AEF_DEVICE_ID "aef-fpga-01"

// Topico MQTT (o backend usa a variavel MQTT_TOPIC com o mesmo valor).
// #define AEF_MQTT_TOPIC "aventura_financeira/telemetria"

// Modo de teste: 1 = cartao sem cadastro vira automaticamente o proximo item
// livre, do mais barato ao mais caro (8, 7, 9, 10, 1, ...). Vale ate reiniciar.
#define AEF_RFID_AUTO_ASSIGN 0

// Logs no Monitor Serial (USB, 115200 baud). A FPGA usa a UART2, entao os logs
// nao interferem nos quadros. Use 0 para silenciar.
#define AEF_DEBUG 1

// Pinagem opcional. Descomente apenas se precisar mudar o padrao do firmware.
// #define AEF_PIN_RFID_SCK 18
// #define AEF_PIN_RFID_MISO 19
// #define AEF_PIN_RFID_MOSI 23
// #define AEF_PIN_RFID_SS 5
// #define AEF_PIN_RFID_RST 22
// #define AEF_PIN_FPGA_RX 16   // recebe uart_tx da FPGA
// #define AEF_PIN_FPGA_TX 17   // envia para rfid_rx da FPGA

// Cadastre os UIDs reais (hexadecimal, sem espaços) para habilitar os cartões.
// Deixe vazio os itens sem cartão. Cada UID mapeia para o produto do mesmo ID.
#define AEF_RFID_TAG_1_UID ""
#define AEF_RFID_TAG_1_ITEM 1
#define AEF_RFID_TAG_2_UID ""
#define AEF_RFID_TAG_2_ITEM 2
#define AEF_RFID_TAG_3_UID ""
#define AEF_RFID_TAG_3_ITEM 3
#define AEF_RFID_TAG_4_UID ""
#define AEF_RFID_TAG_4_ITEM 4
#define AEF_RFID_TAG_5_UID ""
#define AEF_RFID_TAG_5_ITEM 5
#define AEF_RFID_TAG_6_UID ""
#define AEF_RFID_TAG_6_ITEM 6
#define AEF_RFID_TAG_7_UID ""
#define AEF_RFID_TAG_7_ITEM 7
#define AEF_RFID_TAG_8_UID ""
#define AEF_RFID_TAG_8_ITEM 8
#define AEF_RFID_TAG_9_UID ""
#define AEF_RFID_TAG_9_ITEM 9
#define AEF_RFID_TAG_10_UID ""
#define AEF_RFID_TAG_10_ITEM 10
