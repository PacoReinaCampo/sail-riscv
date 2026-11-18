# RV-Y

Extensión tensorial independiente, con 32 registros y vista en orden por filas:
`p = (i * columns + j) * depth + k`.

Los cuerpos de las instrucciones usan vistas nativas `[i][j][k]` para datos,
máscaras y resultados; el almacenamiento empaquetado se convierte al entrar y
al salir de esas vistas. Las familias usan nombres YY, YX, FYY y MYY.

Activación: `extensions.Y.supported = true`. Tamaño: `extensions.Y.ylen_exp`.
Para dirigir las cargas y los almacenamientos a Y, utilizar
`algebra.memory_bank = "AlgebraMemory_Y"`.

Los opcodes de memoria son compartidos por las tablas V/W/Y; el selector es fijo
durante una ejecución del simulador. La aritmética utiliza el opcode `0x2b`.

El [informe completo](../W/INFORME_RV_V_W_Y.md) documenta las decisiones de CSR,
la integración, la comparación con las especificaciones y los resultados.

Desde la raíz del repositorio:

```sh
python3 model/extensions/W/verify_extensions.py
```
