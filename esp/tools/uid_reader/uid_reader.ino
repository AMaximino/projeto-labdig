#include <Arduino.h>
#include <SPI.h>
#include <MFRC522.h>

static constexpr uint8_t RFID_SS_PIN = D2;
static constexpr uint8_t RFID_RST_PIN = D1;
MFRC522 reader(RFID_SS_PIN, RFID_RST_PIN);

void setup() {
  Serial.begin(115200);
  SPI.begin();
  reader.PCD_Init();
  Serial.println("Aproxime um cartão para ler o UID hexadecimal.");
}

void loop() {
  if (!reader.PICC_IsNewCardPresent() || !reader.PICC_ReadCardSerial()) return;
  for (byte index = 0; index < reader.uid.size; ++index) {
    if (reader.uid.uidByte[index] < 0x10) Serial.print('0');
    Serial.print(reader.uid.uidByte[index], HEX);
  }
  Serial.println();
  reader.PICC_HaltA();
  reader.PCD_StopCrypto1();
  delay(500);
}
