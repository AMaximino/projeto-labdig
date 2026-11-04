#pragma once

// Copie este arquivo para config.h e preencha os valores da sua rede.
// Nao coloque config.h no Git: ele contem credenciais locais.
#define AEF_WIFI_SSID "NOME_DA_REDE_WIFI"
#define AEF_WIFI_PASSWORD "SENHA_DA_REDE_WIFI"

// IPv4 do computador que executa/encaminha o broker MQTT, na rede Wi-Fi.
// Nao use localhost: esse nome apontaria para a propria ESP8266.
#define AEF_MQTT_HOST "192.168.1.100"
#define AEF_MQTT_PORT 1883
#define AEF_MQTT_USERNAME ""
#define AEF_MQTT_PASSWORD ""

#define AEF_DEVICE_ID "aef-fpga-01"

// NodeMCU / Wemos D1 mini: GPIO14 corresponde normalmente ao pino D5.
// Este e o RX de SoftwareSerial para uart_tx da FPGA. Nao e o RX USB (GPIO3).
#define AEF_FPGA_RX_PIN 14
