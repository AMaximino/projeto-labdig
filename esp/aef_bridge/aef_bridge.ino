#include <Arduino.h>
#include <PubSubClient.h>
#include <SPI.h>
#include <MFRC522.h>
#include <strings.h>
#include <ESP8266WiFi.h>
#include <time.h>

#include "config.h"
#include "telemetry_protocol.h"

#ifndef AEF_RFID_TAG_1_UID
#define AEF_RFID_TAG_1_ITEM 1
#define AEF_RFID_TAG_1_UID ""
#define AEF_RFID_TAG_2_ITEM 2
#define AEF_RFID_TAG_2_UID ""
#define AEF_RFID_TAG_3_ITEM 3
#define AEF_RFID_TAG_3_UID ""
#define AEF_RFID_TAG_4_ITEM 4
#define AEF_RFID_TAG_4_UID ""
#define AEF_RFID_TAG_5_ITEM 5
#define AEF_RFID_TAG_5_UID ""
#define AEF_RFID_TAG_6_ITEM 6
#define AEF_RFID_TAG_6_UID ""
#define AEF_RFID_TAG_7_ITEM 7
#define AEF_RFID_TAG_7_UID ""
#define AEF_RFID_TAG_8_ITEM 8
#define AEF_RFID_TAG_8_UID ""
#define AEF_RFID_TAG_9_ITEM 9
#define AEF_RFID_TAG_9_UID ""
#define AEF_RFID_TAG_10_ITEM 10
#define AEF_RFID_TAG_10_UID ""
#endif

static constexpr size_t LINE_CAPACITY = 160;
static constexpr size_t MQTT_QUEUE_CAPACITY = 4;
static constexpr size_t JSON_CAPACITY = 512;
static constexpr char MQTT_TOPIC[] = "aventura_financeira/telemetria";
static constexpr uint8_t RFID_SS_PIN = D2;
static constexpr uint8_t RFID_RST_PIN = D1;
static constexpr uint32_t RFID_POLL_MS = 120;
static constexpr uint32_t RFID_REMOVE_MS = 300;

struct QueuedMessage {
  char payload[JSON_CAPACITY];
};

MFRC522 rfid(RFID_SS_PIN, RFID_RST_PIN);
WiFiClient networkClient;
PubSubClient mqttClient(networkClient);
char inputLine[LINE_CAPACITY];
size_t inputLength = 0;
bool droppingLongLine = false;
QueuedMessage messageQueue[MQTT_QUEUE_CAPACITY];
size_t queueHead = 0;
size_t queueTail = 0;
size_t queueCount = 0;
char sessionId[48] = {};
bool hasPreviousBalance = false;
int32_t previousBalanceRaw = 0;
uint32_t lastWiFiAttempt = 0;
uint32_t lastMqttAttempt = 0;
uint32_t clientNumber = 0;
uint32_t lastRfidPoll = 0;
uint32_t noCardSince = 0;
bool cardLatched = false;
char latchedUid[21] = {};

struct RfidTag { const char *uid; uint8_t item; };
const RfidTag rfidTags[] = {
  {AEF_RFID_TAG_1_UID, AEF_RFID_TAG_1_ITEM}, {AEF_RFID_TAG_2_UID, AEF_RFID_TAG_2_ITEM},
  {AEF_RFID_TAG_3_UID, AEF_RFID_TAG_3_ITEM}, {AEF_RFID_TAG_4_UID, AEF_RFID_TAG_4_ITEM},
  {AEF_RFID_TAG_5_UID, AEF_RFID_TAG_5_ITEM}, {AEF_RFID_TAG_6_UID, AEF_RFID_TAG_6_ITEM},
  {AEF_RFID_TAG_7_UID, AEF_RFID_TAG_7_ITEM}, {AEF_RFID_TAG_8_UID, AEF_RFID_TAG_8_ITEM},
  {AEF_RFID_TAG_9_UID, AEF_RFID_TAG_9_ITEM}, {AEF_RFID_TAG_10_UID, AEF_RFID_TAG_10_ITEM}
};

void uidToHex(const MFRC522::Uid &uid, char *output, size_t capacity) {
  size_t offset = 0;
  for (byte index = 0; index < uid.size && offset + 2 < capacity; ++index) {
    offset += snprintf(output + offset, capacity - offset, "%02X", uid.uidByte[index]);
  }
  output[offset] = '\0';
}

uint8_t itemForUid(const char *uid) {
  for (const auto &tag : rfidTags) {
    if (tag.uid[0] != '\0' && strcasecmp(uid, tag.uid) == 0) return tag.item;
  }
  return 0;
}

void sendRfidPurchase(uint8_t item) {
  if (item < 1 || item > 10) return;
  char command[5];
  snprintf(command, sizeof(command), "R%02u\n", item);
  Serial.write(reinterpret_cast<const uint8_t *>(command), 4);
  Serial.flush();
}

void serviceRfid() {
  const uint32_t now = millis();
  if (now - lastRfidPoll < RFID_POLL_MS) return;
  lastRfidPoll = now;

  if (!cardLatched) {
    if (!rfid.PICC_IsNewCardPresent() || !rfid.PICC_ReadCardSerial()) return;
    uidToHex(rfid.uid, latchedUid, sizeof(latchedUid));
    cardLatched = true;
    noCardSince = 0;
    const uint8_t item = itemForUid(latchedUid);
    if (item != 0) sendRfidPurchase(item);
    rfid.PICC_HaltA();
    rfid.PCD_StopCrypto1();
    return;
  }

  byte atqa[2];
  byte atqaSize = sizeof(atqa);
  const MFRC522::StatusCode status = rfid.PICC_WakeupA(atqa, &atqaSize);
  if (status == MFRC522::STATUS_OK || status == MFRC522::STATUS_COLLISION) {
    noCardSince = 0;
    rfid.PICC_HaltA();
    return;
  }
  if (status == MFRC522::STATUS_TIMEOUT) {
    if (noCardSince == 0) noCardSince = now;
    if (now - noCardSince >= RFID_REMOVE_MS) {
      cardLatched = false;
      latchedUid[0] = '\0';
      noCardSince = 0;
    }
  }
}

void makeSessionId() {
  uint32_t randomPart = ESP.random();
  snprintf(sessionId, sizeof(sessionId), "%06lx-%08lx",
           static_cast<unsigned long>(ESP.getChipId()),
           static_cast<unsigned long>(randomPart));
}

void formatTimestamp(char *output, size_t capacity) {
  time_t now = time(nullptr);
  if (now < 1577836800) {
    snprintf(output, capacity, "null");
    return;
  }
  struct tm utc;
  gmtime_r(&now, &utc);
  snprintf(output, capacity, "\"%04d-%02d-%02dT%02d:%02d:%02d.000Z\"",
           utc.tm_year + 1900, utc.tm_mon + 1, utc.tm_mday,
           utc.tm_hour, utc.tm_min, utc.tm_sec);
}

bool enqueueMessage(const TelemetryFrame &frame) {
  if (frame.eventCode == 1 || sessionId[0] == '\0') {
    makeSessionId();
    hasPreviousBalance = false;
  }
  if (queueCount == MQTT_QUEUE_CAPACITY) {
    return false;
  }

  const int64_t balanceCents = rtlToCents(frame.balanceRaw);
  const int64_t deltaCents = hasPreviousBalance
      ? balanceCents - rtlToCents(previousBalanceRaw)
      : 0;
  previousBalanceRaw = frame.balanceRaw;
  hasPreviousBalance = true;

  QueuedMessage &message = messageQueue[queueTail];
  char timestamp[32];
  formatTimestamp(timestamp, sizeof(timestamp));
  if (!formatTelemetryJson(
          message.payload, sizeof(message.payload), frame, AEF_DEVICE_ID,
          sessionId, timestamp, deltaCents)) {
    return false;
  }
  queueTail = (queueTail + 1) % MQTT_QUEUE_CAPACITY;
  ++queueCount;
  return true;
}

void processLine(char *line) {
  if (line[0] == '\0') return;
  char parseBuffer[LINE_CAPACITY];
  strlcpy(parseBuffer, line, sizeof(parseBuffer));
  TelemetryFrame frame = {};
  if (!parseFrame(parseBuffer, frame)) {
    return;
  }
  if (!enqueueMessage(frame)) return;
}

void readUart() {
  while (Serial.available() > 0) {
    char character = static_cast<char>(Serial.read());
    if (character == '\n') {
      if (!droppingLongLine) {
        inputLine[inputLength] = '\0';
        if (inputLength > 0 && inputLine[inputLength - 1] == '\r') {
          inputLine[inputLength - 1] = '\0';
        }
        processLine(inputLine);
      } else {
      }
      inputLength = 0;
      droppingLongLine = false;
    } else if (!droppingLongLine) {
      if (inputLength + 1 < sizeof(inputLine)) {
        inputLine[inputLength++] = character;
      } else {
        droppingLongLine = true;
      }
    }
  }
}

void maintainWiFi() {
  if (WiFi.status() == WL_CONNECTED) return;
  uint32_t now = millis();
  if (now - lastWiFiAttempt < 10000) return;
  lastWiFiAttempt = now;
  WiFi.begin(AEF_WIFI_SSID, AEF_WIFI_PASSWORD);
}

void maintainMqtt() {
  if (WiFi.status() != WL_CONNECTED || mqttClient.connected()) return;
  uint32_t now = millis();
  if (now - lastMqttAttempt < 5000) return;
  lastMqttAttempt = now;
  char clientId[40];
  snprintf(clientId, sizeof(clientId), "aef-esp8266-%06lx-%lu",
           static_cast<unsigned long>(ESP.getChipId()), static_cast<unsigned long>(clientNumber++));
  bool connected = AEF_MQTT_USERNAME[0] == '\0'
      ? mqttClient.connect(clientId)
      : mqttClient.connect(clientId, AEF_MQTT_USERNAME, AEF_MQTT_PASSWORD);
  if (connected) {
  }
}

void publishQueuedMessage() {
  if (!mqttClient.connected() || queueCount == 0) return;
  QueuedMessage &message = messageQueue[queueHead];
  if (mqttClient.publish(MQTT_TOPIC, message.payload, false)) {
    queueHead = (queueHead + 1) % MQTT_QUEUE_CAPACITY;
    --queueCount;
  } else {
    mqttClient.disconnect();
  }
}

void setup() {
  Serial.begin(115200);
  SPI.begin();
  rfid.PCD_Init();
  const char *deviceId = AEF_DEVICE_ID;
  bool validDeviceId = strlen(deviceId) > 0 && strlen(deviceId) <= 48;
  for (size_t i = 0; validDeviceId && deviceId[i] != '\0'; ++i) {
    char character = deviceId[i];
    validDeviceId = (character >= 'A' && character <= 'Z') ||
                    (character >= 'a' && character <= 'z') ||
                    (character >= '0' && character <= '9') ||
                    character == '.' || character == '_' || character == '-';
  }
  if (!validDeviceId) {
    ESP.restart();
  }

  WiFi.mode(WIFI_STA);
  mqttClient.setServer(AEF_MQTT_HOST, AEF_MQTT_PORT);
  if (!mqttClient.setBufferSize(JSON_CAPACITY)) {
    ESP.restart();
  }
  configTime(0, 0, "pool.ntp.org", "time.nist.gov");
  WiFi.begin(AEF_WIFI_SSID, AEF_WIFI_PASSWORD);
}

void loop() {
  readUart();
  serviceRfid();
  maintainWiFi();
  maintainMqtt();
  if (mqttClient.connected()) mqttClient.loop();
  publishQueuedMessage();
  delay(1);
}
