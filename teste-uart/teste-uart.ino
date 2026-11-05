#include <SoftwareSerial.h>

static constexpr uint8_t FPGA_RX_PIN = 14;  // GPIO14 (D5 no NodeMCU/D1 mini)
static constexpr uint32_t UART_BAUD_RATE = 115200;

SoftwareSerial fpgaSerial(FPGA_RX_PIN, -1, false);

void setup() {
  Serial.begin(UART_BAUD_RATE);
  fpgaSerial.begin(UART_BAUD_RATE, SWSERIAL_8N1, FPGA_RX_PIN, -1, false, 256);
  Serial.println();
  Serial.println("Teste UART FPGA -> ESP8266 iniciado.");
  Serial.println("Aguardando dados da FPGA...");
}

void loop() {
  while (fpgaSerial.available() > 0) {
    Serial.write(static_cast<uint8_t>(fpgaSerial.read()));
  }
}