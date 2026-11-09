# Teste do protocolo ESP8266

`telemetry_protocol_test.cpp` exercita o parser `AEF1`, conversão para centavos
e geração JSON usados pelo firmware. Não requer hardware ou broker.

Na raiz do repositório:

```sh
sh esp/testbench/run_tests.sh
```

Esse teste não substitui a validação de SPI/UART e conectividade na placa
ESP8266.
