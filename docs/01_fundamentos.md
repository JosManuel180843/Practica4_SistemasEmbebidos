# 01 · Fundamentos

[← Volver al README](../README.md)

## Comunicación serial UART

UART (*Universal Asynchronous Receiver Transmitter*) es una comunicación serial **asíncrona**: el transmisor y el receptor no comparten reloj, así que los dos deben usar el mismo *baud rate*.

En reposo, la línea está en alto. Cada byte viaja dentro de una trama:

| Campo | Nivel | Bits |
|---|---|---|
| Inicio | 0 | 1 |
| Datos (primero el LSB) | D0 … D7 | 8 |
| Paridad | — | 0 (no se usa) |
| Paro | 1 | 1 |

Con **8N1**, cada byte ocupa 10 periodos de bit. Esta es la trama del byte `0x04`, que en este sistema corresponde a la base A = 4:

```
        Reposo Inicio D0  D1  D2  D3  D4  D5  D6  D7  Paro Reposo
línea:    1      0     0   0   1   0   0   0   0   0    1     1
        ‾‾‾‾‾‾\_______________/‾‾‾\___________________/‾‾‾‾‾‾‾‾‾‾‾
```

## Comunicación bidireccional y conexión cruzada

TX es una salida y RX una entrada, por eso se conectan **cruzadas**: el TX de un dispositivo va al RX del otro. Además, los dos deben compartir **GND** para tener la misma referencia de voltaje.

Cada sentido tiene su propia línea. Aun así, en este sistema la comunicación es de petición y respuesta: la PC envía 2 bytes y la FPGA contesta con 13.

## ESP32 como puente USB–UART

El ESP32 tiene varios controladores UART en hardware:

- **UART0 (`Serial`)** se comunica con la PC por USB, que la ve como un puerto COM virtual.
- **UART2 (`FPGA_Serial`)** se comunica con la FPGA por GPIO16 (RX) y GPIO17 (TX).

Como reenvía cada byte sin modificarlo, el ESP32 funciona como un **puente transparente**: desde MATLAB parece que la FPGA está conectada directamente a un puerto serial. El ESP32 y la DE10-Lite trabajan a 3.3 V, así que no se necesitan convertidores de nivel.

```
MATLAB ⇄ USB ⇄ ESP32 ⇄ UART ⇄ FPGA
```

## Divisor de baudios

La FPGA usa el reloj de 50 MHz y cuenta ciclos para medir la duración de cada bit:

$$N = \frac{f_{clk}}{\text{baud}} = \frac{50\,000\,000}{9600} \approx 5208 \text{ ciclos}$$

Como la división se trunca, la velocidad real queda un poco por encima de la nominal:

$$\text{baud}_{real} = \frac{50\,000\,000}{5208} \approx 9600.61 \quad\Rightarrow\quad \varepsilon \approx 0.0064\,\%$$

El receptor espera **medio bit (2604 ciclos)** después del flanco de bajada del inicio. Así, todas las muestras siguientes caen cerca del centro de cada bit.

## Formato de punto fijo Q80.20

El resultado ocupa 100 bits: 80 de parte entera y 20 fraccionarios. Para obtener el valor real se divide la palabra almacenada `q` entre $2^{20}$:

$$y = \frac{q}{2^{20}}, \qquad \text{resolución} = 2^{-20} \approx 9.54 \times 10^{-7}$$

| Valor real | Palabra Q80.20 |
|---|---|
| 1 | 1 048 576 (`0x100000`) |
| 8 | 8 388 608 (`0x800000`) |
| √2 | 1 482 910 (`0x16A09E`) |

## Cálculo de $A^{n/2}$

Primero se separa el exponente en su parte par y su bit menos significativo:

$$n = 2k + r, \qquad k = \lfloor n/2 \rfloor, \qquad r \in \{0, 1\}$$

$$A^{n/2} = A^{k} \cdot \left(\sqrt{A}\right)^{r}$$

- $A^k$ se obtiene con $k$ multiplicaciones sucesivas, a lo más 7.
- $\sqrt{A}$ se obtiene con la raíz cuadrada entera de $A \cdot 2^{40}$:

$$\left\lfloor \sqrt{A \cdot 2^{40}} \right\rfloor = \left\lfloor \sqrt{A} \cdot 2^{20} \right\rfloor$$

  El resultado ya es $\sqrt{A}$ con 20 bits fraccionarios. La raíz entera se calcula con el método binario **dígito por dígito**: en cada iteración se bajan dos bits del radicando al residuo y se compara el residuo con `4·raíz + 1`.

El valor máximo es $255^{7.5} \approx 1.12 \times 10^{18} < 2^{60}$, así que cabe de sobra en los 80 bits enteros.
