# Lab-06-Privileged-Access-Management-PAM-


### 1. Descripción del proyecto

Después de varios incidentes en Mirador de Montepinar S.L., Antonio Recio ha llegado a una conclusión: no se puede confiar en nadie, y mucho menos si tiene permisos de Administrador global. 

Entre los líos de Amador Rivas, las decisiones de Enrique Pastor y los movimientos de los vecinos, Antonio está harto de que cualquiera pueda acabar teniendo acceso a más cosas de las que le corresponden. Una cosa es bajar a pedir sal, y otra muy distinta es tener las llaves de toda la infraestructura.

Así que decide imponer orden en la comunidad: a partir de ahora, quien necesite privilegios elevados tendrá que presentar una solicitud, justificar para qué los quiere, aportar un ticket cuando corresponda y conseguir la aprobación del responsable adecuado. Y nada de quedarse con los permisos para toda la vida: las elevaciones estarán limitadas en el tiempo y deberán caducar cuando corresponda.

Para evitar que la gestión de accesos termine como otra junta de vecinos imposible de controlar, se ha desarrollado una simulación local de Privileged Access Management (PAM) con PowerShell y ficheros CSV.

### 2. Objetivos técnicos

El objetivo principal es demostrar, mediante un escenario inspirado en La que se avecina, cómo se puede diseñar un flujo básico de gestión de privilegios que separe la solicitud, la validación, la aprobación y la activación temporal. Además:

- Modelar un catálogo de roles privilegiados y sus restricciones.
- Validar solicitudes mediante PowerShell.
- Comprobar la existencia y el estado de las identidades.
- Aplicar límites de duración, justificaciones obligatorias y requisitos de ticket.
- Validar el responsable exigido para cada rol.
- Gestionar decisiones de aprobación y rechazo.
- Simular elevaciones temporales con fechas de inicio y expiración.
- Detectar activaciones caducadas y revocaciones simuladas.
- Prevenir registros duplicados de aprobaciones y activaciones.
- Generar informes CSV y mantener un historial de eventos.
- Probar escenarios válidos y errores controlados.

### 3. Arquitectura del proyecto

Antonio Recio quiere saber dónde está cada cosa, quién tiene acceso y quién ha autorizado semejante despropósito. Para evitar que los datos terminen desperdigados como los acuerdos de una junta de vecinos, el laboratorio se organiza en tres bloques: datos, scripts y resultados.

¿Qué hace cada carpeta?

#### data/ — Los expedientes de Montepinar

Aquí se almacenan los datos ficticios que utiliza el laboratorio. El catálogo define los roles disponibles y sus restricciones; las solicitudes recogen quién quiere elevar sus privilegios; las aprobaciones representan las decisiones de los responsables; y las activaciones almacenan las fechas y los estados de las elevaciones simuladas.

#### scripts/ — La administración de Antonio Recio

Contiene los scripts PowerShell que realizan las comprobaciones y procesan las solicitudes.

Validar-CatalogoRoles.ps1: comprueba la integridad del catálogo de roles, sus identificadores, las duraciones y los campos obligatorios.

Validar-SolicitudesPAM.ps1: valida las solicitudes, comprueba las aprobaciones, calcula los estados del proceso, gestiona las activaciones simuladas y genera los informes.

#### reports/ — Las actas de la junta

Guarda los resultados de las comprobaciones y el historial de eventos. Los informes permiten revisar qué solicitudes superan las validaciones, cuáles se rechazan y qué estado tiene cada activación registrada.

El archivo auditoria_activaciones.csv conserva las observaciones y los cambios de estado que registra el script. Es un historial local de la simulación, no un registro inmutable ni una solución de auditoría de producción.

Flujo de trabajo

1. El proceso sigue esta secuencia:
2. Se cargan los catálogos y se validan sus datos.
3. Se comprueba cada solicitud y se identifican las que incumplen las reglas.
4. Se verifica la decisión del responsable y su correspondencia con el rol solicitado.
5. Se determina el estado de autorización.
6. Se registra la activación temporal cuando corresponde y se comprueba su expiración.
7. Se generan los informes y se conservan los eventos de auditoría.

Así, si alguien de la comunidad de Mirador de Montepinar solicita las llaves del edificio, no basta con que diga que las necesita: hay que comprobar su identidad, justificar el acceso, revisar quién lo autoriza y limitar el tiempo durante el que puede utilizarlo.

## 4. Catálogo de roles privilegiados

Antonio Recio ha decidido que los privilegios administrativos no se van a repartir como las invitaciones a una barbacoa comunitaria en casa de Enrique. Cada rol tiene un nivel de riesgo, una duración máxima y un responsable que debe autorizar su utilización.

Para representar estas restricciones, el laboratorio utiliza `data/catalogo_roles.csv`, un catálogo que define las condiciones que deben cumplir las solicitudes de elevación temporal.

### Los cuatro niveles de privilegio de Montepinar

| Identificador | Rol | Riesgo | Duración máxima | Aprobador requerido | Ticket obligatorio |
|---|---|---|---:|---|---|
| `HELPDESK_ADMIN` | Helpdesk Administrator | Medio | 4 horas | Responsable de soporte | No |
| `USER_ADMIN` | User Administrator | Medio-Alto | 2 horas | Responsable de IAM | No |
| `CA_ADMIN` | Conditional Access Administrator | Alto | 1 hora | Responsable de seguridad | Sí |
| `GLOBAL_ADMIN` | Global Administrator | Crítico | 1 hora | Responsable de seguridad | Sí |

### ¿Qué significa cada rol en la comunidad?

**`HELPDESK_ADMIN`**

Pensado para tareas de soporte que requieren privilegios administrativos limitados. En el laboratorio, se permite una elevación de hasta cuatro horas, siempre que la solicitud supere las validaciones.

**`USER_ADMIN`**

Representa un rol destinado a determinadas tareas de administración de usuarios. Su duración máxima es de dos horas y requiere la aprobación del responsable de IAM.

**`CA_ADMIN`**

Este rol representa la administración de las políticas de Acceso Condicional. Como puede afectar a los controles de acceso, el laboratorio lo clasifica como de riesgo alto, limita su duración a una hora y exige un ticket y la aprobación del responsable de seguridad.

**`GLOBAL_ADMIN`**

Es el rol de mayor riesgo de nuestro escenario. Permite representar tareas administrativas con un alcance muy amplio, por lo que se limita a una hora y requiere un ticket y la aprobación del responsable de seguridad.

Antonio podrá desconfiar de todos los vecinos, pero incluso él tendrá que pasar por el procedimiento definido si solicita este privilegio en el laboratorio.

### ¿Por qué limitamos la duración?

El principio es sencillo: los privilegios elevados deben utilizarse durante el tiempo necesario para realizar la tarea, en lugar de mantenerse disponibles indefinidamente.

En este escenario, las duraciones máximas son reglas de diseño del laboratorio. No deben confundirse con los valores predeterminados de Microsoft Entra ID ni con las políticas que aplicaría un producto PAM real.

### Validación del catálogo

El script `Validar-CatalogoRoles.ps1` comprueba la integridad de este catálogo antes de utilizarlo. Entre otras cuestiones, verifica que no existan identificadores de rol duplicados, que las duraciones sean válidas y que los campos obligatorios estén completos.

Estas comprobaciones ayudan a evitar que una solicitud se evalúe a partir de un catálogo inconsistente.

## 5. Flujo de validación y autorización

Antonio Recio ha establecido un procedimiento para evitar que los privilegios administrativos se conviertan en otro motivo de conflicto vecinal. Cada solicitud debe superar una serie de comprobaciones antes de poder pasar a la fase de aprobación.

El script `Validar-SolicitudesPAM.ps1` automatiza estas comprobaciones y registra los resultados para que ninguna decisión dependa únicamente de la palabra de un vecino.

### Fase 1.

Lo primero es verificar que el usuario y el rol solicitados existen en los catálogos.

El proceso también comprueba la integridad de las referencias y detecta aprobaciones o activaciones duplicadas. Si encuentra registros de aprobación o activación ambiguos, detiene la ejecución para evitar que el proceso continúe con datos inconsistentes.

Porque en Montepinar se pueden perder muchas cosas, pero no vamos a perder de vista quién solicita los privilegios.

### Fase 2.

Antes de que nadie autorice una elevación, se comprueban las reglas de seguridad definidas para el laboratorio:

- La cuenta debe existir y estar activa.
- El rol debe figurar en el catálogo.
- La duración solicitada debe ser numérica y respetar el máximo permitido.
- La justificación no puede estar vacía.
- Los roles que lo requieran deben incluir un ticket asociado.

Si una solicitud incumple alguno de estos controles, se marca como no autorizable y se registra el motivo.

Por ejemplo, si Antonio solicita dos horas como `GLOBAL_ADMIN`, el sistema detecta que supera el límite de una hora. Por mucho que insista en que es el presidente de la comunidad, la regla sigue siendo la misma.

### Fase 3.

Una solicitud que supera las comprobaciones técnicas todavía necesita una decisión del responsable correspondiente.

El laboratorio contrasta el aprobador registrado con el definido en el catálogo del rol y diferencia entre tres decisiones:

- **Aprobada:** el responsable autoriza la petición.
- **Pendiente:** todavía no existe una decisión definitiva.
- **Rechazada:** el responsable decide que la solicitud no debe continuar.

También se detectan las aprobaciones duplicadas para impedir que una misma solicitud tenga varias decisiones registradas sin resolver la ambigüedad.

Esta fase separa la validación técnica de la autorización: cumplir los requisitos no obliga al responsable a aprobar la petición.

### Fase 4.

Una vez combinadas las comprobaciones y la decisión del responsable, el sistema calcula el estado final de cada solicitud.

| Situación | Resultado del laboratorio |
|---|---|
| Incumple algún control técnico | `No autorizable` |
| Supera los controles y espera una decisión | `Pendiente de aprobación` |
| Supera los controles y el responsable la rechaza | `Rechazada por responsable` |
| Supera los controles y recibe aprobación | `Aprobada, pendiente de activación` |

La última situación es importante: tener autorización no significa que la elevación ya esté activa. Son dos fases diferentes y el laboratorio mantiene esa separación.

### Fase 5.

Cuando una solicitud cumple las condiciones establecidas y está aprobada, el script puede registrar una activación con su fecha de inicio, duración máxima permitida y fecha de expiración.

A partir de ese registro, el proceso simula la evolución del estado de la elevación:

- `Activa`: la activación está dentro de su periodo permitido y sigue cumpliendo las condiciones de autorización.
- `Caducada`: se ha alcanzado la fecha de expiración.
- `Revocada`: la solicitud deja de cumplir la condición de autorización representada en el laboratorio.

El registro persistente evita crear otra activación para una solicitud ya registrada. Además, el script comprueba que no existan activaciones duplicadas antes de continuar.

### Fase 6.

Los informes CSV permiten consultar el resultado de la validación, el estado final de autorización y el estado operativo de las activaciones.

El historial de auditoría conserva los eventos que registra el script, como la observación de un estado inicial, una activación o un cambio a caducado o revocado.

Así, si un vecino asegura que tenía permiso para entrar en una zona restringida, podemos revisar los registros del laboratorio en lugar de resolverlo a gritos durante otra junta.

### Resumen del flujo

**Solicitud → Validación técnica → Decisión del responsable → Autorización → Activación temporal → Expiración o revocación → Auditoría**

Este flujo representa el proceso diseñado para la simulación local. No concede permisos reales ni sustituye a un sistema PAM productivo.

## 6. Informes generados y resultados

Antonio Recio no se fía de la palabra de ningún vecino. Por eso, además de comprobar las solicitudes, el laboratorio genera informes que permiten revisar qué ha ocurrido durante el proceso.

Los resultados se exportan a ficheros CSV para poder consultarlos desde herramientas como Visual Studio Code, Excel o PowerShell.

### 6.1. Informes disponibles

| Archivo | Contenido |
|---|---|
| `evaluacion_solicitudes.csv` | Resultado de las validaciones técnicas y motivos por los que una solicitud no supera los controles. |
| `estado_final_pam.csv` | Resultado final del proceso de autorización: pendiente, aprobado o rechazado según las reglas del laboratorio. |
| `estado_operativo_pam.csv` | Vista conjunta del estado de autorización y del estado de la activación temporal. |
| `auditoria_activaciones.csv` | Historial local de las observaciones y los cambios de estado registrados por el script. |

Cada informe cumple una función distinta. De este modo, no confundimos una petición que ha superado los controles con una elevación que ya está activada.

### 6.2. Resultados de las solicitudes de prueba

La ejecución de referencia utiliza siete solicitudes ficticias para comprobar tanto los casos correctos como los errores introducidos deliberadamente.

| Solicitud | Usuario | Rol solicitado | Resultado observado |
|---|---|---|---|
| `SOL-001` | Antonio Recio (`arecio`) | `HELPDESK_ADMIN` | Aprobada por el responsable y registrada para activación temporal. |
| `SOL-002` | Enrique Pastor (`epastor`) | `USER_ADMIN` | Pendiente de aprobación. |
| `SOL-003` | Amador Rivas (`arivas`) | `CA_ADMIN` | Rechazada por el responsable. |
| `SOL-004` | Maxi Angulo (`mangulo`) | `GLOBAL_ADMIN` | Pendiente de aprobación. |
| `SOL-005` | Antonio Recio (`arecio`) | `GLOBAL_ADMIN` | No autorizable: duración superior al máximo. |
| `SOL-006` | Amador Rivas (`arivas`) | `CA_ADMIN` | No autorizable: falta la justificación. |
| `SOL-007` | Vicente Maroto (`vmaroto`) | `HELPDESK_ADMIN` | No autorizable: cuenta inactiva. |

Los resultados muestran que el proceso distingue entre las solicitudes que cumplen los controles técnicos, las que necesitan una decisión y las que no pueden continuar.

### 6.3. Pruebas negativas y tratamiento de errores

No basta con que el script funcione cuando los datos están bien. También es necesario comprobar cómo se comporta cuando encuentra una anomalía.

Durante el desarrollo se realizaron las siguientes pruebas controladas:

- **Duración no numérica:** se sustituyó temporalmente una duración válida por el texto `dos`. El script detectó el error y continuó evaluando las demás solicitudes.
- **Duración fuera de límites:** la solicitud `SOL-005` fue detectada por superar la duración máxima de `GLOBAL_ADMIN`.
- **Justificación vacía:** se identificó la ausencia de una justificación en `SOL-006`.
- **Cuenta inactiva:** se detectó que Vicente Maroto conservaba una solicitud pese a figurar como inactivo.
- **Aprobaciones duplicadas:** se duplicó temporalmente la fila de `SOL-001`. El script identificó la anomalía y detuvo el procesamiento.
- **Activaciones duplicadas:** se repitió la prueba con el registro de activaciones y el proceso se detuvo al detectar dos registros para la misma solicitud.
- **Caducidad:** se modificó temporalmente la fecha de expiración para simular que una elevación había vencido.
- **Revocación:** se retiró temporalmente la aprobación de `SOL-001` y se comprobó que el registro de la activación cambiaba a `Revocada`.
- **Restauración:** tras las pruebas destructivas, se recuperaron los archivos originales desde sus copias de seguridad.

Estas pruebas permiten comprobar el comportamiento del script ante distintos escenarios. No equivalen a una batería automatizada de pruebas ni demuestran que todas las condiciones posibles estén cubiertas.

### 6.4. Auditoría de las activaciones

El archivo `auditoria_activaciones.csv` incluye los campos necesarios para identificar cuándo se registró un evento, a qué solicitud corresponde, qué tipo de evento se produjo y qué cambio de estado se observó.

Entre los eventos probados se encuentran:

| Evento | Significado |
|---|---|
| `EstadoInicialObservado` | El sistema encontró una activación ya existente cuando comenzó a registrar la auditoría. |
| `Activacion` | Se registró una nueva activación simulada. |
| `Caducidad` | Una activación pasó a estado `Caducada`. |
| `Revocacion` | Una activación pasó a estado `Revocada`. |

El script evita añadir un evento nuevo cuando no se detecta un cambio de estado. También se comprobó que una segunda ejecución normal no duplicara la activación existente.

El historial es local y editable. No dispone de las garantías de integridad, protección contra manipulación, retención centralizada ni supervisión que requeriría un sistema de auditoría de producción.

### 6.5. Interpretación de los resultados

El laboratorio demuestra que es posible modelar con PowerShell un flujo básico de solicitud, validación, aprobación y elevación temporal de privilegios usando datos estructurados.

Las pruebas permiten observar por qué una solicitud no debe avanzar, quién figura como responsable de aprobarla, cuándo una activación debe caducar y cómo registrar los cambios de estado.

En Montepinar, por fin, hay un procedimiento para decidir quién se queda con las llaves. Eso sí: los informes ayudan a revisar las decisiones; no sustituyen la supervisión de un responsable ni conceden permisos reales.

## 7. Cómo ejecutar el laboratorio

### Manual de instrucciones para sobrevivir a la administración de Montepinar

Antonio Recio ha dejado claro que aquí no se toca nada sin seguir el procedimiento. Para evitar que la infraestructura termine como otra reunión caótica de la comunidad, el laboratorio se ejecuta localmente mediante PowerShell.

No hace falta conectarse a un tenant de Microsoft Entra ID ni disponer de una infraestructura de Active Directory. Todo funciona con los datos ficticios almacenados en CSV.

### 7.1. Requisitos previos

Para ejecutar el proyecto se necesita:

- Windows con PowerShell.
- Los archivos del repositorio `06-PAM`.
- Permisos de lectura y escritura en la carpeta del proyecto.
- Visual Studio Code, recomendado para revisar los scripts y los ficheros CSV.

### 7.2. Preparar el entorno

Clona o descarga el repositorio y abre la carpeta `06-PAM` en Visual Studio Code.

La estructura debe incluir las carpetas `data`, `scripts` y `reports`, además de este `README.md`.

Abre una terminal de PowerShell integrada en VS Code y sitúate en la raíz del proyecto.

Si PowerShell bloquea la ejecución de los scripts, puedes permitir temporalmente la ejecución de scripts locales en la sesión actual:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned
```

Esta configuración afecta únicamente al proceso de PowerShell actual. No es necesario cambiar permanentemente la política de ejecución del equipo.

### 7.3. Validar el catálogo de roles

Antes de procesar solicitudes, ejecuta el validador del catálogo:

```powershell
.\scripts\Validar-CatalogoRoles.ps1
```

El script comprueba que el catálogo no contenga identificadores de rol duplicados, duraciones inválidas, campos obligatorios vacíos ni valores incorrectos en `RequiereTicket`.

Con los datos de referencia del laboratorio, se esperan cuatro roles cargados y ninguna anomalía en estas comprobaciones.

### 7.4. Ejecutar el flujo de solicitudes PAM

Una vez validado el catálogo, ejecuta:

```powershell
.\scripts\Validar-SolicitudesPAM.ps1
```

El script carga los usuarios, las solicitudes, las aprobaciones y las activaciones. A continuación, realiza las comprobaciones configuradas, determina los estados de autorización y actualiza el registro de activaciones y el historial de auditoría cuando corresponde.

Los resultados se muestran en la terminal y se guardan en la carpeta `reports`.

### 7.5. Revisar los informes

Después de ejecutar el script, abre la carpeta `reports` y consulta los resultados:

- `evaluacion_solicitudes.csv`: permite revisar los controles técnicos y los motivos de rechazo.
- `estado_final_pam.csv`: muestra el resultado de la autorización.
- `estado_operativo_pam.csv`: combina el estado de autorización y el estado de la activación.
- `auditoria_activaciones.csv`: contiene los eventos registrados durante la simulación.

Los informes pueden abrirse directamente en Visual Studio Code o importarse en Excel para facilitar su lectura.

### 7.6. Repetir las pruebas

Para comprobar el comportamiento del laboratorio, se pueden modificar temporalmente los CSV de entrada y ejecutar de nuevo el script.

Algunos escenarios que se pueden reproducir son:

- Introducir una duración no numérica.
- Solicitar más horas de las permitidas para un rol.
- Dejar una justificación vacía.
- Utilizar una cuenta marcada como inactiva.
- Duplicar una aprobación o una activación.
- Simular una fecha de expiración pasada.
- Cambiar una decisión de aprobación para comprobar la revocación simulada.

**Precaución:** antes de modificar los datos, conserva una copia de los archivos originales. Tras cada prueba, restáuralos y comprueba que las modificaciones temporales no permanezcan en los ficheros funcionales.

### 7.7. Consideraciones sobre las fechas

Las activaciones se evalúan según las fechas de inicio y expiración almacenadas en `activaciones.csv`.

Por tanto, los resultados pueden cambiar con el paso del tiempo. Si la fecha de expiración de una activación ya ha pasado, el script debe identificarla como `Caducada`; no es necesario modificar el reloj del equipo ni mantener una activación artificialmente vigente.

En caso de realizar pruebas con fechas modificadas, se deben restaurar tanto el registro de activaciones como el historial de auditoría cuando se quiera recuperar el estado anterior a la prueba.

### 7.8. Alcance de la ejecución

El proyecto es una simulación local. Las etiquetas `Activa`, `Caducada` y `Revocada` representan estados registrados por el script, no el estado de privilegios de una cuenta real.

Antonio Recio puede estar tranquilo: ninguna de estas operaciones concede permisos sobre Microsoft Entra ID, Active Directory ni otro sistema externo.

## 8. Seguridad, limitaciones y alcance

El laboratorio reproduce parte de la lógica de un proceso PAM para practicar controles de acceso privilegiado con PowerShell. Su propósito es educativo: probar validaciones, estados, aprobaciones y eventos de auditoría utilizando datos ficticios.

### 8.1. Qué demuestra el proyecto

Durante el desarrollo se han implementado y probado controles para:

- Comprobar que los usuarios y roles referenciados existen en los catálogos.
- Identificar cuentas inactivas que solicitan privilegios.
- Validar duraciones numéricas y límites máximos por rol.
- Exigir justificaciones y tickets cuando corresponda.
- Contrastar el aprobador registrado con el responsable definido en el catálogo.
- Detectar aprobaciones y activaciones duplicadas.
- Diferenciar el resultado de autorización del estado de una activación.
- Simular activaciones temporales, expiraciones y revocaciones.
- Generar informes CSV y registrar cambios de estado en un historial local.

Estas capacidades permiten estudiar el flujo de trabajo de una gestión básica de privilegios y comprobar cómo responde el script ante datos correctos e incorrectos.

### 8.2. Qué no implementa

El laboratorio presenta limitaciones importantes que deben tenerse en cuenta:

- **No se conecta a un sistema de identidad real.** No utiliza Microsoft Entra ID, Active Directory ni una plataforma PAM comercial.
- **No concede ni retira privilegios reales.** Los estados de activación y revocación son registros ficticios.
- **No autentica a los aprobadores.** Comprueba que el nombre registrado coincida con el responsable del catálogo, pero no verifica su identidad ni sus permisos reales.
- **No protege los CSV contra manipulaciones.** Un usuario con permisos de escritura puede modificar solicitudes, decisiones, activaciones e informes.
- **No dispone de un registro de auditoría inmutable.** El historial es local y puede editarse o eliminarse.
- **No implementa una gestión centralizada de secretos ni credenciales privilegiadas.**
- **No incluye una batería automatizada completa de pruebas.** Las comprobaciones realizadas son pruebas funcionales manuales mediante modificaciones temporales de los datos.

Estas limitaciones son relevantes porque un proceso PAM productivo necesita controles de identidad, autorización, integridad, supervisión y recuperación que van mucho más allá de almacenar estados en CSV.

### 8.3. Consideraciones sobre las activaciones temporales

En el laboratorio, la fecha de expiración se utiliza para determinar si una activación simulada debe seguir figurando como activa o pasar a `Caducada`.

La revocación también se representa mediante un cambio de estado cuando el proceso detecta que ya no se cumplen las condiciones de autorización definidas en el escenario.

Sin embargo, **cambiar el estado de un CSV no deshabilita una sesión real ni elimina un privilegio de una cuenta**. En un sistema real sería necesario ejecutar y verificar la operación correspondiente en la plataforma de identidad o de gestión de privilegios.

### 8.4. Recomendaciones para una futura versión productiva

Si el laboratorio evolucionara hacia una implementación conectada a una infraestructura real, sería necesario incorporar controles adicionales:

- Autenticación y autorización verificables de los responsables.
- Registro de auditoría centralizado, protegido y con políticas de retención.
- Validación estricta de los datos de entrada y tratamiento de errores.
- Controles de integridad y concurrencia para evitar decisiones contradictorias.
- Integración segura con el sistema que concede y retira los privilegios.
- Supervisión de las activaciones y verificación efectiva de su expiración.
- Pruebas automatizadas, procedimientos de recuperación y revisión de seguridad.

La futura integración con una plataforma como Microsoft Entra ID Privileged Identity Management (PIM) permitiría explorar controles nativos de activación y aprobación en un entorno debidamente autorizado.

### 8.5. La moraleja de Montepinar

Este proyecto no pretende reemplazar una solución PAM empresarial. Busca demostrar que se comprenden los fundamentos de un proceso de acceso privilegiado: solicitar el mínimo acceso necesario, justificarlo, someterlo a una decisión autorizada, limitar su duración y conservar evidencia de lo sucedido.

Porque una cosa es que Antonio Recio tenga sospechas sobre todos los vecinos y otra muy distinta es que el sistema pueda demostrar quién solicitó un privilegio, quién lo autorizó y cuándo dejó de estar vigente.

## 9. Tecnologías y competencias practicadas

Detrás de las sospechas de Antonio Recio hay un laboratorio práctico desarrollado para trabajar conceptos fundamentales de gestión de identidades y accesos privilegiados.

Las tecnologías y competencias utilizadas son las siguientes.

### Tecnologías

| Tecnología | Aplicación en el laboratorio |
|---|---|
| **PowerShell** | Automatización de comprobaciones, validación de datos, procesamiento de solicitudes y generación de informes. |
| **CSV** | Almacenamiento estructurado de usuarios, roles, solicitudes, aprobaciones y activaciones. |
| **Visual Studio Code** | Edición de scripts, revisión de datos y ejecución de las pruebas. |
| **Git y GitHub** | Control de versiones y publicación del proyecto como parte del portfolio técnico. |

### Competencias IAM/PAM

**Gestión de identidades y accesos (IAM)**

- Validación de identidades y comprobación del estado de las cuentas.
- Uso de catálogos de roles y restricciones de acceso.
- Separación entre solicitud, validación técnica y autorización.
- Aplicación de reglas de aprobación según el rol solicitado.

**Gestión de accesos privilegiados (PAM)**

- Modelado de solicitudes de elevación temporal.
- Definición de duraciones máximas por rol.
- Simulación de activaciones, expiraciones y revocaciones.
- Detección de registros de aprobación y activación duplicados.

**Automatización y auditoría**

- Importación, filtrado, agrupación y comparación de datos mediante PowerShell.
- Validación de entradas y tratamiento controlado de errores.
- Exportación de resultados a CSV.
- Registro de eventos y revisión de cambios de estado.
- Ejecución de pruebas positivas y negativas con datos ficticios.

Estas competencias se han practicado en un entorno local y no implican experiencia de administración de una plataforma PAM empresarial en producción.

## 10. Próximas mejoras

### Porque en Montepinar siempre queda algo por arreglar

El laboratorio ya permite representar un flujo básico de acceso privilegiado, pero todavía hay margen para mejorar su calidad, mantenibilidad y cobertura de pruebas.

Las siguientes mejoras podrían incorporarse en futuras versiones:

### 10.1. Automatización de pruebas

Crear pruebas automatizadas para verificar de forma repetible cada regla de validación, incluidas las solicitudes válidas, los errores de datos, las aprobaciones incorrectas y los intentos de duplicar registros.

El objetivo sería comprobar los resultados esperados sin tener que modificar manualmente los CSV en cada ejecución.

### 10.2. Refactorización del código PowerShell

Separar las funciones de validación, aprobación, gestión de activaciones y auditoría en funciones reutilizables. Esto permitiría reducir la repetición de código y facilitar el mantenimiento del proyecto.

También sería conveniente centralizar los errores detectados para que una solicitud pueda mostrar todos sus motivos de rechazo en un único resultado.

### 10.3. Mejoras en la integridad de los datos

Incorporar validaciones adicionales para:

- Identificadores de solicitud duplicados.
- Decisiones de aprobación con valores no permitidos.
- Fechas inválidas o inconsistentes.
- Activaciones cuya duración no coincide con la solicitada.
- Solicitudes que no cumplen los requisitos de activación.
- Errores al escribir los informes y el historial.

También se debería mejorar la gestión de ejecuciones simultáneas para evitar que dos procesos modifiquen los mismos ficheros a la vez.

### 10.4. Trazabilidad de las decisiones

Ampliar el registro de auditoría para incluir el origen de cada decisión, el responsable registrado, la justificación, el instante del cambio y el identificador de la solicitud relacionada.

En una implementación real, estos registros necesitarían protección contra manipulaciones, controles de acceso y políticas de retención adecuadas.

### 10.5. Integración con una plataforma de identidad

Como evolución técnica, se podría explorar la integración con Microsoft Entra ID Privileged Identity Management (PIM) en un entorno autorizado.

Esto permitiría estudiar las diferencias entre una simulación desarrollada con PowerShell y un servicio que proporciona funciones nativas de activación de roles, aprobación y gestión temporal de privilegios.

Antes de realizar esta integración sería necesario diseñar las operaciones, los permisos y las medidas de seguridad apropiadas para el entorno.

### 10.6. Documentación y evidencias

Completar el proyecto con capturas de las ejecuciones, ejemplos de los informes y una matriz que relacione cada control con su prueba correspondiente.

Las evidencias deberían mostrar tanto los casos correctos como los errores detectados, evitando publicar credenciales, secretos o datos personales reales.

Estas mejoras constituyen una hoja de ruta para evolucionar el laboratorio de forma gradual, sin confundir las funcionalidades implementadas con las que todavía están pendientes.
