# Implementación y verificación de RV-W y RV-Y en sail-riscv

Fecha: 18 de noviembre de 2026 (Asia/Dubai).

## Alcance y fuentes

Se han implementado las extensiones base RV-W y RV-Y mediante 15 ficheros Sail por extensión, con la misma distribución funcional de RV-V. Se conserva el modelo RV-V y se integra la selección de su dominio de memoria con los nuevos dominios W e Y.

Fuentes utilizadas:

- Modelo: `/home/user/GitHub/PacoReinaCampo/code/Research/sail-riscv`.
- Compilador: `/home/user/GitHub/PacoReinaCampo/code/Research/sail/bin/sail`.
- Especificaciones: los ocho documentos Markdown de cada directorio `GreenCard/RISC-V/instructions/specific/Algebra/rv-v`, `rv-w` y `rv-y` indicado en la solicitud.
- Versión inicial del modelo: commit `6e2f7a93`; no se ha consultado otro repositorio de modelos ni otra especificación.
- Compilador utilizado: Sail 0.20.3, commit `60695b1ea377048f0adc39c62671cd099b2ed9f6`.

Las dependencias de compilación son las declaradas por el propio proyecto: GMP del sistema y las bibliotecas auxiliares de su construcción CMake. La compilación final utiliza las copias locales disponibles, con FetchContent desconectado. No se descargan suites de pruebas externas.

`specification_sha256.json` identifica el contenido exacto de las 24 fuentes. `specification_comparison.csv` contiene una fila por entrada de las tablas: 2.133 filas en total.

## Análisis de las especificaciones

| Aspecto | RV-V | RV-W | RV-Y |
|---|---|---|---|
| Vista de un elemento | `[p]` | `[i][j]` | `[i][j][k]` |
| Índice lineal | `p` | `i*COLS+j` | `(i*COLS+j)*DEPTH+k` |
| Banco | `v0..v31` | `w0..w31` | `y0..y31` |
| Longitud activa | `vl` | `wl` | `yl` |
| Reinicio de recorrido | `vstart` | `wstart` | `ystart` |
| Tipo | `vtype` | `wtype` | `ytype` |
| Redondeo y saturación entera | `vxrm`, `vxsat` | `wxrm`, `wxsat` | `yxrm`, `yxsat` |
| Opcode aritmético principal | `0x57` | `0x0b` | `0x2b` |
| Opcodes de memoria | `0x07`, `0x27` | `0x07`, `0x27` | `0x07`, `0x27` |
| Entradas de la extensión base | 627 | 627 | 627 |
| Entradas de subextensiones adicionales | 84 | 84 | 84 |

Los cuerpos de las instrucciones W/Y utilizan ahora vistas anidadas nativas de Sail: `[i][j]` y `[i][j][k]`, respectivamente. El índice `p` se reserva al orden de recorrido y a los offsets físicos.

Las 627 entradas base de W e Y corresponden a las de V con cambio de banco y opcode aritmético. Los recorridos, máscaras, agrupaciones de registros, reducciones y transferencias de memoria conservan el orden lineal indicado por el pseudocódigo PL/HDL. Cada modelo agrupa las entradas en 89 familias de instrucciones Sail; los segmentos y anchuras explican que una familia represente varias filas de la tabla.

La representación física es un banco de registros de longitud configurable. En los cuerpos de las instrucciones, los operandos, máscaras y resultados se convierten a vectores anidados con filas calculadas por redondeo hacia arriba. Las celdas de relleno no son elementos arquitectónicos y se descartan al escribir el resultado. Las máscaras utilizan filas `bits(COLS)` en W y `bits(DEPTH)` como última dimensión en Y; los otros ejes son vectores. Esto conserva los índices explícitos y permite la generación correcta de C++ sin especializaciones genéricas de `vector(..., bit)`. Las funciones `w_shape`/`y_shape` y `w_unshape_*`/`y_unshape_*` delimitan la conversión entre el almacenamiento empaquetado y las vistas explícitas. El tamaño de un registro W o Y no se calcula elevando VLEN al cuadrado o al cubo. Las reducciones base operan sobre los elementos activos del recorrido lineal; no se añaden reducciones por ejes que no figuren en la especificación.

Las operaciones de producto de matrices, tiles, formatos reducidos adicionales y dot products que figuran bajo nombres `ZV*`, `ZW*` o `ZY*` son subextensiones distintas. No forman parte de las 627 entradas base implementadas en los 15 ficheros solicitados.

## Decisiones necesarias para integrar las extensiones

### Selección de memoria

Las tres especificaciones asignan los mismos patrones binarios de memoria a bancos diferentes. El binario de una carga no identifica por sí solo si debe escribir V, W o Y. La solución confirmada por el usuario es un parámetro de configuración:

```json
"algebra": { "memory_bank": "AlgebraMemory_W" }
```

Valores admitidos: `AlgebraMemory_V`, `AlgebraMemory_W` y `AlgebraMemory_Y`. V es el valor predeterminado. La selección se comprueba en las guardas de decodificación de las tres extensiones; no depende del orden de los ficheros. La aritmética de los tres bancos puede coexistir y no utiliza este selector.

La infraestructura de memoria conserva la categoría interna `Vector` como acceso multielemento para PMA/MAG y desalineación; esa categoría no comprueba si V está activada. Las políticas de memoria de plataforma son comunes a los tres bancos.

La selección se fija al iniciar el simulador. No se ha inventado una instrucción para cambiarla durante la ejecución. Seleccionar W o Y con el banco desactivado hace inválida la configuración.

### Estado independiente y CSR

W e Y tienen registros, longitudes, tipos, máscaras, reinicios, redondeo entero, saturación y tamaños propios. Sus instrucciones enteras no requieren `misa.V`, `mstatus.VS`, soporte Zve ni registros V. Los módulos W e Y no requieren el módulo de instrucciones V.

El núcleo declara los parámetros numéricos de los tres bancos para mantener visibles las restricciones de tipos dependientes de Sail. Compartir el núcleo, los registros escalares X y la infraestructura de memoria no comparte el estado de los bancos.

Las operaciones de coma flotante usan la infraestructura escalar F/D/Zfh, `frm` y `fflags`, tal como indican los pseudocódigos. No se crea un `fflags` privado por banco.

La especificación suministrada nombra los controles W/Y sin asignar sus direcciones CSR. Se han escogido direcciones del espacio custom, que son decisiones de esta integración y no asignaciones normativas de RISC-V:

| Control | W | Y |
|---|---|---|
| start | `0x800` | `0x804` |
| xsat | `0x801` | `0x805` |
| xrm | `0x802` | `0x806` |
| csr combinado | `0x803` | `0x807` |
| longitud activa, lectura | `0xCC0` | `0xCC4` |
| tipo, lectura | `0xCC1` | `0xCC5` |
| bytes por registro, lectura | `0xCC2` | `0xCC6` |

Los campos ya existentes W/Y de `misa` anuncian el soporte. En esta integración son de sólo lectura y dependen de `extensions.W.supported` y `extensions.Y.supported`. No se reutilizan los bits de contexto VS para W/Y. El seguimiento privilegiado de contexto sucio propio de W/Y no está definido en las fuentes suministradas y no se añade; sus callbacks de escritura de registros son puntos de extensión Sail sin implementación de trazado C++ específica.

### Nombres de operandos de anchura doble

Se conservan las denominaciones `wide` de las tablas W/Y. Por ejemplo, `vwadd.wv` se corresponde con `wwadd.wide.ww`; una sustitución textual indiscriminada confundiría esta variante con `wwadd.ww`. Las conversiones, divisiones y movimientos conservan sus nombres semánticos.

### Actualización de representación y nomenclatura

Se han sustituido los accesos aritméticos, de máscaras, reducción, permutación y memoria por vistas con coordenadas explícitas. Los campos de operaciones segmentadas usan `field`, separado de `i`, `j` y `k`. Las operaciones de serialización de registros y bitfields mantienen sus índices de bits y bytes.

Ejemplo del cuerpo de una suma Y:

```sail
foreach (p from 0 to (num_elem - 1)) {
  let i = p / (y_columns * y_depth);
  let j = (p / y_depth) % y_columns;
  let k = p % y_depth;
  // Tras las comprobaciones de límites y máscara:
  result_view[i][j][k] = ys2_val_view[i][j][k] + ys1_val_view[i][j][k];
}
```

En W, la operación correspondiente utiliza `result_view[i][j]`, `ws2_val_view[i][j]` y `ws1_val_view[i][j]`.

| Familia anterior | W | Y |
|---|---|---|
| VVTYPE | W_WWTYPE | Y_YYTYPE |
| VXTYPE | W_WXTYPE | Y_YXTYPE |
| FVVTYPE | W_FWWTYPE | Y_FYYTYPE |
| MVVTYPE | W_MWWTYPE | Y_MYYTYPE |
| WVVTYPE (anchura doble) | W_WIDE_WWTYPE | Y_WIDE_YYTYPE |
| read_vreg | w_read_wreg | y_read_yreg |
| vd, vs1, vs2, vm | wd, ws1, ws2, wm | yd, ys1, ys2, ym |

`nomenclature_changes.csv` documenta las 178 correspondencias de familias. Los mnemonics, codificaciones binarias, claves de configuración existentes y campos compartidos del núcleo —incluido `mstatus.VS`— se conservan. El banco W/Y y el marcador de anchura doble se distinguen usando `WIDE` en los identificadores internos.

Las extensiones de una vista deben cumplir `W.columns <= WLEN` y `Y.columns * Y.depth <= YLEN`, límites del máximo número de elementos de un grupo. Esto evita reservar planos de relleno mayores que la capacidad máxima del banco. Las vistas parciales para SEW mayor que 8 siguen permitidas.

## Ficheros e integración

En W e Y se han creado los ficheros `*ext_types`, `*reg_type`, `*ext_regs`, `*ext_control`, `*ext_utils_insts`, `*ext_fp_utils_insts`, `*ext_*set_insts`, `*ext_arith_insts`, `*ext_fp_insts`, `*ext_mem_insts`, `*ext_mask_insts`, `*ext_*m_insts`, `*ext_fp_*m_insts`, `*ext_red_insts` y `*ext_fp_red_insts`, con los nombres completos solicitados.

Se mantienen las cabeceras BSD-2-Clause, la sintaxis de cláusulas dispersas de Sail y la organización por tipos, estado, decodificación, ejecución y ensamblado del repositorio. Las implementaciones W/Y se especializan a partir de V y no llaman a sus operaciones de registros.

Ficheros existentes modificados:

- `model/riscv.sail_project`: módulos, dependencias y pruebas.
- `model/core/extensions.sail`: identificación, soporte y cadena ISA de W/Y.
- `model/core/vlen.sail`: parámetros numéricos independientes.
- `model/core/platform_config.sail`: selector de memoria.
- `model/core/sys_regs.sail` y `model/sys/sys_control.sail`: `misa`.
- `model/postlude/model.sail`: reinicio de los controles W/Y.
- `model/postlude/validate_config.sail`: validación del selector y anchuras de índices.
- `model/extensions/V/vext_mem_insts.sail`: guarda del dominio de memoria V.
- `config/config.json.in`: valores predeterminados.
- `test/unit_tests/main_unit_tests.cpp`: selección opcional de un fichero de configuración para ejecutar pruebas.

Los nuevos ficheros fuente, pruebas e informes están únicamente dentro de `model/extensions/W` y `model/extensions/Y`. Los productos de compilación se generan en `build`, como establece el proyecto. No se ha modificado `build_simulator.sh`.

## Configuración y reproducción

W e Y están desactivadas por defecto. Cada banco tiene un tamaño predeterminado de 256 bits por registro y elementos de hasta 64 bits. Las columnas y la profundidad definen la vista; la longitud activa y LMUL siguen limitando el número de elementos accesibles.

Ejemplo de override:

```json
{
  "algebra": { "memory_bank": "AlgebraMemory_W" },
  "extensions": {
    "W": { "supported": true, "wlen_exp": 8, "columns": 4 },
    "Y": { "supported": true, "ylen_exp": 8, "columns": 4, "depth": 2 }
  }
}
```

Desde la raíz de `sail-riscv`:

```sh
export PATH=/home/user/GitHub/PacoReinaCampo/code/Research/sail/bin:$PATH
DOWNLOAD_GMP=FALSE ENABLE_RISCV_TESTS=FALSE sh ./build_simulator.sh
ctest --test-dir build --output-on-failure
python3 model/extensions/W/verify_extensions.py --output /tmp/rvwy-results.json
```

La primera configuración CMake necesita las dependencias declaradas por el proyecto o sus copias locales. En esta ejecución se utilizó `FETCHCONTENT_FULLY_DISCONNECTED=ON` después de poblar la caché local. La compilación final conserva los flags predeterminados `-O2 -g` de `RelWithDebInfo`. Se limitó la afinidad a dos CPU para que el paralelismo calculado por el script no saturase el equipo.

El verificador Python sólo necesita la biblioteca estándar: genera programas ELF RV32 y RV64 directamente a partir de las tablas locales, sin ensamblador ni otro repositorio. Sus ficheros temporales se eliminan al terminar.

## Validación

La compilación definitiva de esta actualización mediante `build_simulator.sh` ha terminado correctamente, en modo `RelWithDebInfo` con GCC 11.4.0 y Sail 0.20.3. Se ha superado la comprobación de tipos con `--strict-var`, `--strict-bitvector` y `--strict-exponentials`. El script también ha validado las 16 configuraciones RV32/RV64 generadas.

| Comprobación | Resultado |
|---|---|
| `build_simulator.sh` | Correcto |
| Suite unitaria predeterminada, 10 pruebas Sail | Correcto |
| Auditoría de opcodes con dominio de memoria V | Correcto |
| Auditoría de opcodes con dominio de memoria W | Correcto |
| Auditoría de opcodes con dominio de memoria Y | Correcto |
| ELF de W en RV32 y RV64 sin V ni Y, 39 comprobaciones por arquitectura | Correcto, `SUCCESS` |
| ELF de Y en RV32 y RV64 sin V ni W, 39 comprobaciones por arquitectura | Correcto, `SUCCESS` |
| Siete configuraciones inválidas de W/Y | Correcto: rechazo esperado en los siete casos |
| Propiedades SMT registradas en CTest | Correcto |

CTest se ha ejecutado de nuevo sobre las fuentes definitivas y ha finalizado con 2/2 pruebas correctas (`smt_properties_rv64d` y `unit_tests`). La prueba SMT verifica las propiedades existentes registradas por el repositorio; no constituye una prueba formal nueva de todas las operaciones W/Y. Tras la compilación definitiva también se repitió correctamente la suite unitaria.

Las 14 agrupaciones de verificación han pasado, con 156 comprobaciones en los cuatro programas ELF. Los resultados reproducibles de las auditorías, los cuatro programas ELF y los siete rechazos de configuración se guardan en `verification_results.json`. La auditoría usa la suite Sail con W/Y activadas explícitamente: las comprobaciones de opcodes de un banco desactivado se omiten en la configuración predeterminada.

La advertencia de Sail sobre `emulator_or_isla` procede de la biblioteca instalada del compilador. GCC informa de que limita el seguimiento de columnas y variables de depuración de algunas funciones grandes del modelo generado; estas notas no impidieron completar la compilación.

Las pruebas incorporadas comprueban:

- Suma modular, saturación y su bandera, máscaras, longitud cero e independencia de los otros bancos.
- Correspondencia entre el índice multidimensional y el almacenamiento lineal en una frontera de fila/plano.
- Decodificación, nombre y vuelta a codificar una instancia de cada una de las 627 entradas base por banco; los tres dominios de memoria se prueban por separado.
- Programas ELF RV32 y RV64 con W activada y V/Y desactivadas, y con Y activada y V/W desactivadas (156 comprobaciones en total): configuración, aritmética de 8 y 64 bits, multiplicación, división por cero, reducción, memoria, las ocho operaciones lógicas de máscara, gather a través de una frontera de fila/plano, saturación, FP32 y `fflags`. Se ejecutan con `COLS=3`, `DEPTH=5` y 16 elementos activos, además de las configuraciones predeterminadas usadas por las pruebas unitarias.

También se comprueba el rechazo de siete configuraciones inválidas: selección de un banco de memoria desactivado, anchura de elementos superior al máximo, elementos mayores que un registro, índices demasiado anchos profundidad cero y plano mayor que la capacidad del banco.

La prueba de opcodes usa una instancia de los campos variables por fila; no enumera los 2^32 binarios. Las pruebas de ejecución son de regresión y no constituyen una demostración formal de toda la semántica.

## Cobertura y límites

W/Y implementan las 627 entradas base de cada una de sus tablas. Las 84 entradas adicionales de cada directorio pertenecen a 26 subextensiones separadas `ZW*` o `ZY*` y no se implementan como parte de este trabajo sobre las extensiones base W/Y.

En el modelo V ya existen fuentes para 32 de las 84 entradas adicionales: Zvabd (8), Zvbb (16), Zvbc (4), Zvfbfmin (2) y Zvfbfwma (2). Su presencia se registra en el CSV; no se presenta como verificación semántica de esas subextensiones. Las otras 52 entradas adicionales no tienen implementación en las fuentes de esas extensiones del modelo inspeccionado.

No se afirma equivalencia formal entre todos los pseudocódigos y las implementaciones. Se conserva la semántica ejecutable de V en las familias correspondientes, se especializa el estado de W/Y y se verifican los casos descritos. Las políticas de colas y máscaras agnósticas conservan las opciones del modelo Sail. Las direcciones CSR y el selector de memoria son decisiones documentadas de integración necesarias ante información no definida o ambigua en las fuentes suministradas.
