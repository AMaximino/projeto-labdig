# Testbench do firmware ESP8266

`telemetry_protocol_test.cpp` testa o mesmo parser, conversor de centavos e
formatador JSON incluídos pelo firmware em `aef_bridge/telemetry_protocol.h`.
Os testes cobrem linhas aceitas/recusadas, saldo negativo, sequencia, máscara
de inventário e campos do payload MQTT. Nao exige placa ESP8266 nem broker.

Na raiz do repositorio:

```sh
./esp8266/testbench/run_tests.sh
```

Este teste de host nao simula temporizacao de SoftwareSerial, Wi-Fi ou
reconexao MQTT; valide essas partes na placa alvo com um broker de teste.
