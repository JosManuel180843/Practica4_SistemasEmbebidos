# 04 · Pruebas y resultados

[← Volver al README](../README.md)

## 1. Simulación de `potencia_q8020`

El banco de pruebas [`sim/tb_potencia_q8020.v`](../sim/tb_potencia_q8020.v) usa un reloj de 20 ns (50 MHz) y mantiene el reset durante 3 ciclos. Después aplica 5 casos: en cada uno activa `start` durante un ciclo, espera `done` y compara `result_q` con el valor esperado.

| A | n | $A^{n/2}$ | Q80.20 esperado | Ciclos | Resultado |
|---:|---:|---:|---:|---:|:---:|
| 4 | 3 | 8 | 8 388 608 | 3 | OK |
| 9 | 3 | 27 | 28 311 552 | 3 | OK |
| 16 | 3 | 64 | 67 108 864 | 3 | OK |
| 4 | 7 | 128 | 134 217 728 | 5 | OK |
| 2 | 0 | 1 | 1 048 576 | 2 | OK |

La simulación termina a los 580 ns.

![Simulación en Active-HDL](img/sim1.png)

> Los casos con n impar usan cuadrados perfectos (4, 9, 16), así que su resultado es exacto. Las raíces irracionales y el exponente máximo se probaron en la tarjeta.

## 2. Montaje físico

![Conexión ESP32 – DE10-Lite](img/conexion_fisica.jpg)

## 3. Pruebas desde MATLAB

Bytes esperados en el orden de llegada; los que no aparecen son `00`:

| A | n | Q80.20 | Decimal | Bytes B0, B1, … | Obtenido |
|---:|---:|---:|---:|---|---|
| 2 | 0 | 1 048 576 | 1 | `00 00 10` | _completar_ |
| 2 | 1 | 1 482 910 | 1.4142131805 | `9E A0 16` | _completar_ |
| 4 | 3 | 8 388 608 | 8 | `00 00 80` | _completar_ |
| 25 | 2 | 26 214 400 | 25 | `00 00 90 01` | _completar_ |
| 10 | 5 | 331 588 800 | 316.2277221680 | `C0 A4 C3 13` | _completar_ |
| 100 | 4 | 10 485 760 000 | 10 000 | `00 00 00 71 02` | _completar_ |
| 0 | 5 | 0 | 0 | `00` | _completar_ |
| 255 | 15 | 1.17395 × 10²⁴ | 1 119 570 196 819 935 155.29 | `21 99 34 FB 0F A9 98 32 98 F8` | _completar_ |

![Consola de MATLAB con casos adicionales](img/matlab_consola2.png)

## 4. Análisis

### Precisión del formato Q80.20

- **n par:** el resultado es $A^k \cdot 2^{20}$, así que es exacto.
- **n impar:** $\sqrt{A}$ se trunca a 20 bits antes de multiplicarse por $A^k$:

$$e_r = \frac{\delta}{\sqrt{A}\cdot 2^{20}} < \frac{1}{\sqrt{2}\cdot 2^{20}} \approx 6.7\times10^{-7}, \qquad 0 \le \delta < 1$$

Al revisar todas las bases de 2 a 255, el mayor error relativo es **5.0 × 10⁻⁷** (A = 3). El resultado nunca supera el valor exacto.

| A | n | Exacto | FPGA | Error relativo |
|---:|---:|---:|---:|---:|
| 2 | 1 | 1.414213562 | 1.414213181 | 2.7 × 10⁻⁷ |
| 3 | 5 | 15.58845727 | 15.58845448 | 5.0 × 10⁻⁷ |
| 10 | 5 | 316.2277660 | 316.2277222 | 1.4 × 10⁻⁷ |
| 255 | 15 | 1.119570259 × 10¹⁸ | 1.119570197 × 10¹⁸ | 5.6 × 10⁻⁸ |

> El **error absoluto** crece con $A^k$. Para 255^7.5 es de unos 6 × 10¹⁰, aunque en términos relativos sea muy pequeño. Además, para resultados mayores que 2⁵³, la referencia en `double` de MATLAB puede perder las últimas cifras, mientras que el valor de la FPGA para n par es exacto.

### Tiempos

| Etapa | Bits | Tiempo |
|---|---:|---:|
| Envío de A y n (2 bytes) | 20 | 2.08 ms |
| Cálculo (peor caso) | — | 180 ns |
| Envío del resultado (13 bytes) | 130 | 13.54 ms |
| **Total** | **150** | **≈ 15.6 ms** |

Casi todo el tiempo se va en la UART. Es muy poco comparado con el `Timeout` de 5 s del script.

### Alcance y limitaciones

- `uart_rx` y `uart_tx` no se simularon por separado; se verificaron con la comunicación completa.
- La FSM principal no tiene tiempo límite. Si solo llega A, se queda en `WAIT_N` hasta recibir otro byte o un reset.
- `potencia_q8020` usa solo `n[3:0]`, así que la validación de MATLAB (n ≤ 15) es necesaria.
- `isqrt64` es combinacional. Conviene revisar en el *Timing Analyzer* de Quartus que cumpla a 50 MHz.

## 5. Video

_(agregar enlace)_
