# Lab-06-Privileged-Access-Management-PAM-

Proyecto práctico de IAM | Mirador de Montepinar S.L.

### 1. Descripción del proyecto

Este laboratorio implementa una simulación local de un flujo de gestión de accesos privilegiados (Privileged Access Management, PAM) utilizando PowerShell y ficheros CSV.

El objetivo es representar el ciclo de vida de una solicitud de elevación temporal de privilegios: desde la solicitud inicial y sus validaciones hasta la aprobación, la activación temporal, el control de expiración y el registro de eventos de auditoría.

El escenario utiliza identidades y roles ficticios inspirados en La que se avecina, adaptados a una organización empresarial simulada.

Importante: el proyecto no se conecta a Active Directory ni a Microsoft Entra ID y no concede, modifica ni revoca permisos reales. Los estados de activación y revocación representan exclusivamente el comportamiento del laboratorio.

### 2. Objetivos técnicos

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
