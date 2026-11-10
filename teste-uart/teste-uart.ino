#include <SoftwareSerial.h>

static constexpr uint8_t FPGA_RX_PIN = 14;  // GPIO14 (D5 on NodeMCU/D1 mini)
static constexpr uint32_t UART_BAUD_RATE = 115200;

// RX habilitado; TX desabilitado; sinal não invertido
SoftwareSerial fpgaSerial(FPGA_RX_PIN, -1, false);

void setup() {
  Serial.begin(UART_BAUD_RATE);
  fpgaSerial.begin(UART_BAUD_RATE, SWSERIAL_8N1);

  Serial.println();
  Serial.println("Teste da telemetria UART FPGA -> ESP8266");
  Serial.println("Aguardando quadros; UART 115200, 8-N-1.");
}

void loop() {
  while (fpgaSerial.available() > 0) {
    Serial.write(static_cast<uint8_t>(fpgaSerial.read()));
  }
}