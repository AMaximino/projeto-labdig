#include <WiFi.h>

const char* ssid = "iPhone de Sophia";
const char* password = "sophiasophia";

void setup(){
    Serial.begin(115200);
    delay(1000);

    WiFi.mode(WIFI_STA); //Optional
    WiFi.begin(ssid, password);
    Serial.println("\nConnecting");

    while(WiFi.status() != WL_CONNECTED){
        Serial.print(".");
        delay(1000);
    }

    Serial.println("\nConnected to the WiFi network");
    Serial.print("Local ESP32 IP: ");
    Serial.println(WiFi.localIP());
    delay(1000);
}

void loop(){
    Serial.println("ola");
    delay(1000);
}