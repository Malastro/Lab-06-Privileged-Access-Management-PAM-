$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$dataPath = Join-Path $projectRoot "data"

$rolesPath = Join-Path $dataPath "catalogo_roles.csv"
$solicitudesPath = Join-Path $dataPath "solicitudes.csv"
$usuariosPath = Join-Path $dataPath "usuarios_pam.csv"
$aprobacionesPath = Join-Path $dataPath "aprobaciones.csv"

$roles = Import-Csv -Path $rolesPath
$solicitudes = Import-Csv -Path $solicitudesPath
$usuarios = Import-Csv -Path $usuariosPath
$aprobaciones = Import-Csv -Path $aprobacionesPath

$aprobacionesDuplicadas = $aprobaciones |
    Group-Object -Property SolicitudId |
    Where-Object { $_.Count -gt 1 }

if ($aprobacionesDuplicadas) {

    foreach ($grupo in $aprobacionesDuplicadas) {
        Write-Host "Error: hay $($grupo.Count) aprobaciones para $($grupo.Name)"
    }

    throw "No se puede continuar: hay solicitudes con aprobaciones duplicadas."
}

Write-Host "Solicitudes con aprobaciones duplicadas: 0"

$erroresReferencias = @()

foreach ($solicitud in $solicitudes) {

    $rolEncontrado = $roles |
        Where-Object { $_.RoleId -eq $solicitud.RoleId }

    $usuarioEncontrado = $usuarios |
        Where-Object { $_.UserId -eq $solicitud.UserId }

    if (-not $rolEncontrado) {
        $erroresReferencias += "$($solicitud.SolicitudId): rol inexistente"
    }

    if (-not $usuarioEncontrado) {
        $erroresReferencias += "$($solicitud.SolicitudId): usuario inexistente"
    }
}

Write-Host "Errores de referencias: $($erroresReferencias.Count)"

foreach ($errorReferencia in $erroresReferencias) {
    Write-Host $errorReferencia
}


Write-Host "Catalogo de roles: $($roles.Count)"
Write-Host "Solicitudes cargadas: $($solicitudes.Count)"
Write-Host "Usuarios cargados: $($usuarios.Count)"
Write-Host "Aprobaciones cargadas: $($aprobaciones.Count)"

$erroresUsuariosInactivos = @()

foreach ($solicitud in $solicitudes) {

    $usuario = $usuarios |
        Where-Object { $_.UserId -eq $solicitud.UserId }

    if ($usuario -and $usuario.Estado -ne "Activo") {
        $erroresUsuariosInactivos += "$($solicitud.SolicitudId): usuario inactivo ($($solicitud.UserId))"
    }
}

Write-Host "Solicitudes de usuarios inactivos: $($erroresUsuariosInactivos.Count)"

foreach ($errorUsuario in $erroresUsuariosInactivos) {
    Write-Host $errorUsuario
}

$erroresDuracion = @()

foreach ($solicitud in $solicitudes) {

    $duracionSolicitada = 0

    $esNumerica = [int]::TryParse(
        [string]$solicitud.DuracionSolicitadaHoras,
        [ref]$duracionSolicitada
    )

    if (-not $esNumerica) {
        $erroresDuracion += "$($solicitud.SolicitudId): duracion no numerica"
        continue
    }

    $rol = $roles |
        Where-Object { $_.RoleId -eq $solicitud.RoleId } |
        Select-Object -First 1

    if ($rol) {

        $duracionMaxima = 0

        $maximaNumerica = [int]::TryParse(
            [string]$rol.DuracionMaxHoras,
            [ref]$duracionMaxima
        )

        if (-not $maximaNumerica) {
            $erroresDuracion += "$($solicitud.SolicitudId): limite del rol no numerico"
            continue
        }

        if ($duracionSolicitada -lt 1 -or
            $duracionSolicitada -gt $duracionMaxima) {

            $erroresDuracion += "$($solicitud.SolicitudId): duracion no permitida. Solicitada: $duracionSolicitada h; Maxima: $duracionMaxima h"
        }
    }
}

Write-Host "Solicitudes con duracion invalida: $($erroresDuracion.Count)"

foreach ($errorDuracion in $erroresDuracion) {
    Write-Host $errorDuracion
}

$erroresJustificacion = @()

foreach ($solicitud in $solicitudes) {

    if ([string]::IsNullOrWhiteSpace($solicitud.Justificacion)) {
        $erroresJustificacion += "$($solicitud.SolicitudId): falta la justificacion"
    }
}

Write-Host "Solicitudes sin justificacion: $($erroresJustificacion.Count)"

foreach ($errorJustificacion in $erroresJustificacion) {
    Write-Host $errorJustificacion
}

$erroresTicket = @()

foreach ($solicitud in $solicitudes) {

    $rol = $roles |
        Where-Object { $_.RoleId -eq $solicitud.RoleId }

    if ($rol -and $rol.RequiereTicket -eq "true") {

        if ([string]::IsNullOrWhiteSpace($solicitud.Ticket)) {
            $erroresTicket += "$($solicitud.SolicitudId): falta el ticket obligatorio"
        }
    }
}

Write-Host "Solicitudes sin ticket obligatorio: $($erroresTicket.Count)"

foreach ($errorTicket in $erroresTicket) {
    Write-Host $errorTicket
}

$evaluacionSolicitudes = foreach ($solicitud in $solicitudes) {

    $motivos = @()

    $rol = $roles |
        Where-Object { $_.RoleId -eq $solicitud.RoleId } |
        Select-Object -First 1

    $usuario = $usuarios |
        Where-Object { $_.UserId -eq $solicitud.UserId } |
        Select-Object -First 1

    if (-not $rol) {
        $motivos += "Rol inexistente"
    }

    if (-not $usuario) {
        $motivos += "Usuario inexistente"
    }
    elseif ($usuario.Estado -ne "Activo") {
        $motivos += "Usuario inactivo"
    }

    if ([string]::IsNullOrWhiteSpace($solicitud.Justificacion)) {
        $motivos += "Falta la justificacion"
    }

    $duracionSolicitada = 0
    $duracionNumerica = [int]::TryParse(
        [string]$solicitud.DuracionSolicitadaHoras,
        [ref]$duracionSolicitada
    )

    if (-not $duracionNumerica) {
        $motivos += "Duracion no numerica"
    }
    elseif ($rol) {
        $duracionMaxima = [int]$rol.DuracionMaxHoras

        if ($duracionSolicitada -lt 1 -or
            $duracionSolicitada -gt $duracionMaxima) {
            $motivos += "Duracion fuera de limites"
        }
    }

    if ($rol -and $rol.RequiereTicket -eq "true") {
        if ([string]::IsNullOrWhiteSpace($solicitud.Ticket)) {
            $motivos += "Falta el ticket obligatorio"
        }
    }

    if ($motivos.Count -eq 0) {
        $resultado = "Lista para aprobacion"
    }
    else {
        $resultado = "Rechazada"
    }

    [PSCustomObject]@{
        SolicitudId = $solicitud.SolicitudId
        UserId      = $solicitud.UserId
        RoleId      = $solicitud.RoleId
        Resultado   = $resultado
        Motivos     = $motivos -join "; "
    }
}

Write-Host "`n=== EVALUACION FINAL DE SOLICITUDES PAM ==="

$evaluacionSolicitudes |
    Format-Table SolicitudId, UserId, RoleId, Resultado, Motivos -Wrap -AutoSize

$reportsPath = Join-Path $projectRoot "reports"

if (-not (Test-Path $reportsPath)) {
    New-Item -ItemType Directory -Path $reportsPath | Out-Null
}

$reportPath = Join-Path $reportsPath "evaluacion_solicitudes.csv"

$evaluacionSolicitudes |
    Export-Csv -Path $reportPath -NoTypeInformation -Encoding utf8

Write-Host "`nInforme guardado en: $reportPath"

$erroresAprobador = @()

foreach ($aprobacion in $aprobaciones) {

    $solicitud = $solicitudes |
        Where-Object { $_.SolicitudId -eq $aprobacion.SolicitudId } |
        Select-Object -First 1

    if (-not $solicitud) {
        $erroresAprobador += "$($aprobacion.SolicitudId): solicitud inexistente"
        continue
    }

    $rol = $roles |
        Where-Object { $_.RoleId -eq $solicitud.RoleId } |
        Select-Object -First 1

    if (-not $rol) {
        $erroresAprobador += "$($aprobacion.SolicitudId): rol inexistente"
        continue
    }

    if ($aprobacion.Aprobador.Trim() -ne $rol.AprobadorRequerido.Trim()) {
        $erroresAprobador += "$($aprobacion.SolicitudId): aprobador no autorizado"
    }
}

Write-Host "`nErrores de aprobador: $($erroresAprobador.Count)"

foreach ($errorAprobador in $erroresAprobador) {
    Write-Host $errorAprobador
}


$estadoFinalSolicitudes = foreach ($evaluacion in $evaluacionSolicitudes) {

    $aprobacion = $aprobaciones |
        Where-Object { $_.SolicitudId -eq $evaluacion.SolicitudId } |
        Select-Object -First 1

    $rol = $roles |
        Where-Object { $_.RoleId -eq $evaluacion.RoleId } |
        Select-Object -First 1

    $estadoFinal = ""
    $motivoFinal = ""

    if ($evaluacion.Resultado -eq "Rechazada") {

        $estadoFinal = "No autorizable"
        $motivoFinal = $evaluacion.Motivos

    }
    elseif (-not $aprobacion) {

        $estadoFinal = "Pendiente de aprobacion"
        $motivoFinal = "Sin registro de aprobacion"

    }
    elseif (-not $rol -or
        $aprobacion.Aprobador.Trim() -ne $rol.AprobadorRequerido.Trim()) {

        $estadoFinal = "Aprobacion no valida"
        $motivoFinal = "El aprobador no coincide con el catalogo"

    }
    else {

        switch ($aprobacion.Decision.Trim()) {

            "Aprobada" {
                $estadoFinal = "Aprobada, pendiente de activacion"
            }

            "Rechazada" {
                $estadoFinal = "Rechazada por responsable"
                $motivoFinal = $aprobacion.Comentario
            }

            "Pendiente" {
                $estadoFinal = "Pendiente de aprobacion"
            }

            default {
                $estadoFinal = "Decision no valida"
                $motivoFinal = "Valor de Decision no reconocido"
            }
        }
    }

    if ($aprobacion) {
        $decisionResponsable = $aprobacion.Decision
    }
    else {
        $decisionResponsable = "Sin registro"
    }

    [PSCustomObject]@{
        SolicitudId          = $evaluacion.SolicitudId
        UserId               = $evaluacion.UserId
        RoleId               = $evaluacion.RoleId
        Validacion           = $evaluacion.Resultado
        DecisionResponsable  = $decisionResponsable
        EstadoFinal          = $estadoFinal
        Motivo               = $motivoFinal
    }
}

Write-Host "`n=== ESTADO FINAL DEL PROCESO PAM ==="

$estadoFinalSolicitudes |
    Format-Table SolicitudId, EstadoFinal, Motivo -Wrap -AutoSize

$estadoFinalPath = Join-Path $reportsPath "estado_final_pam.csv"

$estadoFinalSolicitudes |
    Export-Csv -Path $estadoFinalPath -NoTypeInformation -Encoding utf8

Write-Host "`nInforme final guardado en: $estadoFinalPath"


# === ACTIVACIONES TEMPORALES PAM ===

$activacionesPath = Join-Path $dataPath "activaciones.csv"
$activaciones = @(Import-Csv -Path $activacionesPath)

$activacionesDuplicadas = $activaciones |
    Group-Object -Property SolicitudId |
    Where-Object { $_.Count -gt 1 }

if ($activacionesDuplicadas) {

    foreach ($grupo in $activacionesDuplicadas) {
        Write-Host "Error: hay $($grupo.Count) activaciones para $($grupo.Name)"
    }

    throw "No se puede continuar: hay solicitudes con activaciones duplicadas."
}

Write-Host "Solicitudes con activaciones duplicadas: 0"

$auditoriaPath = Join-Path $reportsPath "auditoria_activaciones.csv"
$auditoriaActual = @(Import-Csv -Path $auditoriaPath)

$eventosAuditoria = @()
$ahora = Get-Date

# 1. Registrar el estado inicial si la auditoria esta vacia
if ($auditoriaActual.Count -eq 0) {

    foreach ($activacion in $activaciones) {

        $eventosAuditoria += [PSCustomObject]@{
            FechaEvento    = $ahora.ToString("o")
            SolicitudId    = $activacion.SolicitudId
            Evento         = "EstadoInicialObservado"
            EstadoAnterior = ""
            EstadoNuevo    = $activacion.Estado
            Detalle        = "Estado existente al iniciar la auditoria; creacion original no registrada."
        }
    }
}

# 2. Revisar las activaciones existentes
foreach ($activacion in $activaciones) {

    $estadoAnterior = $activacion.Estado
    $fechaInicio = [datetime]::Parse($activacion.FechaActivacion)
    $fechaFin = [datetime]::Parse($activacion.FechaExpiracion)

    $estadoSolicitud = $estadoFinalSolicitudes |
        Where-Object { $_.SolicitudId -eq $activacion.SolicitudId } |
        Select-Object -First 1

   if ($estadoAnterior -in @("Revocada", "Caducada")) {

    $estadoNuevo = $estadoAnterior
    $detalle = "Estado terminal conservado. Se requiere una nueva solicitud para otra activacion."

}
elseif ($ahora -ge $fechaFin) {

    $estadoNuevo = "Caducada"
    $detalle = "Se alcanzo la fecha de expiracion."

}
elseif (-not $estadoSolicitud -or
    $estadoSolicitud.EstadoFinal -ne "Aprobada, pendiente de activacion") {

    $estadoNuevo = "Revocada"
    $detalle = "La solicitud ya no figura como aprobada para activacion."

}
elseif ($ahora -lt $fechaInicio) {

    $estadoNuevo = "Programada"
    $detalle = "La fecha de inicio todavia no se ha alcanzado."

}
else {

    $estadoNuevo = "Activa"
    $detalle = "La activacion sigue dentro de su periodo permitido."

}

    $activacion.Estado = $estadoNuevo

    # Registrar solamente cambios de estado
    if ($estadoAnterior -ne $estadoNuevo) {

        if ($estadoNuevo -eq "Caducada") {
            $tipoEvento = "Caducidad"
        }
        elseif ($estadoNuevo -eq "Revocada") {
            $tipoEvento = "Revocacion"
        }
        else {
            $tipoEvento = "CambioEstado"
        }

        $eventosAuditoria += [PSCustomObject]@{
            FechaEvento    = (Get-Date).ToString("o")
            SolicitudId    = $activacion.SolicitudId
            Evento         = $tipoEvento
            EstadoAnterior = $estadoAnterior
            EstadoNuevo    = $estadoNuevo
            Detalle        = $detalle
        }
    }
}

# 3. Registrar nuevas activaciones autorizadas
foreach ($estadoSolicitud in $estadoFinalSolicitudes) {

    if ($estadoSolicitud.EstadoFinal -ne "Aprobada, pendiente de activacion") {
        continue
    }

    $existente = $activaciones |
        Where-Object { $_.SolicitudId -eq $estadoSolicitud.SolicitudId } |
        Select-Object -First 1

    if ($existente) {
        continue
    }

    $solicitudOriginal = $solicitudes |
        Where-Object { $_.SolicitudId -eq $estadoSolicitud.SolicitudId } |
        Select-Object -First 1

    $duracion = [int]$solicitudOriginal.DuracionSolicitadaHoras
    $fechaInicio = Get-Date
    $fechaFin = $fechaInicio.AddHours($duracion)

    $nuevaActivacion = [PSCustomObject]@{
        SolicitudId     = $estadoSolicitud.SolicitudId
        FechaActivacion = $fechaInicio.ToString("o")
        FechaExpiracion = $fechaFin.ToString("o")
        DuracionHoras   = $duracion
        Estado          = "Activa"
    }

    $activaciones += $nuevaActivacion

    $eventosAuditoria += [PSCustomObject]@{
        FechaEvento    = (Get-Date).ToString("o")
        SolicitudId    = $estadoSolicitud.SolicitudId
        Evento         = "Activacion"
        EstadoAnterior = ""
        EstadoNuevo    = "Activa"
        Detalle        = "Nueva activacion temporal registrada."
    }
}

# 4. Guardar las activaciones
$activaciones |
    Export-Csv -Path $activacionesPath -NoTypeInformation -Encoding utf8

# 5. Anadir los eventos al historial sin sobrescribir los anteriores
if ($eventosAuditoria.Count -gt 0) {

    $eventosAuditoria |
        Export-Csv -Path $auditoriaPath -NoTypeInformation -Encoding utf8 -Append
}

Write-Host "`n=== REGISTRO DE ACTIVACIONES PAM ==="

$activaciones |
    Format-Table SolicitudId, DuracionHoras, Estado, FechaExpiracion -AutoSize

Write-Host "`nActivaciones registradas: $($activaciones.Count)"
Write-Host "Eventos de auditoria anadidos: $($eventosAuditoria.Count)"
Write-Host "Historial de auditoria: $auditoriaPath"

# === INFORME OPERATIVO CONSOLIDADO ===

$estadoOperativo = foreach ($estadoSolicitud in $estadoFinalSolicitudes) {

    $activacion = $activaciones |
        Where-Object {
            $_.SolicitudId -eq $estadoSolicitud.SolicitudId
        } |
        Select-Object -First 1

    switch ($estadoSolicitud.EstadoFinal) {
        "Aprobada, pendiente de activacion" {
            $estadoAutorizacion = "Aprobada"
        }
        "Pendiente de aprobacion" {
            $estadoAutorizacion = "Pendiente"
        }
        "Rechazada por responsable" {
            $estadoAutorizacion = "Rechazada"
        }
        default {
            $estadoAutorizacion = $estadoSolicitud.EstadoFinal
        }
    }

    if ($activacion) {
        $estadoActivacion = $activacion.Estado
        $fechaInicio = $activacion.FechaActivacion
        $fechaFin = $activacion.FechaExpiracion
    }
    else {
        $estadoActivacion = "No activada"
        $fechaInicio = ""
        $fechaFin = ""
    }

    [PSCustomObject]@{
        SolicitudId        = $estadoSolicitud.SolicitudId
        UserId             = $estadoSolicitud.UserId
        RoleId             = $estadoSolicitud.RoleId
        EstadoAutorizacion = $estadoAutorizacion
        EstadoActivacion   = $estadoActivacion
        FechaActivacion    = $fechaInicio
        FechaExpiracion    = $fechaFin
    }
}

$informeOperativoPath = Join-Path $reportsPath "estado_operativo_pam.csv"

$estadoOperativo |
    Export-Csv -Path $informeOperativoPath -NoTypeInformation -Encoding utf8

Write-Host "`n=== ESTADO OPERATIVO CONSOLIDADO ==="

$estadoOperativo |
    Format-Table SolicitudId, EstadoAutorizacion, EstadoActivacion -AutoSize

Write-Host "`nInforme operativo guardado en: $informeOperativoPath"
