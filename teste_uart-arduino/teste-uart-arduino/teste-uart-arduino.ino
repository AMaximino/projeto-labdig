#include <SoftwareSerial.h>

const uint32_t BAUD_RATE = 115200;

// RX do Arduino no D10; TX no D11 não é usado.
SoftwareSerial fpgaSerial(10, 11);

void setup() {
  Serial.begin(BAUD_RATE);
  fpgaSerial.begin(BAUD_RATE);

  Serial.println("Teste UART FPGA -> Arduino Uno");
  Serial.println("Aguardando dados (115200, 8-N-1)...");
}

void loop() {
  while (fpgaSerial.available() > 0) {
    Serial.write(fpgaSerial.read());
  }
}