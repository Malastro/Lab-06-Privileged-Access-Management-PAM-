# Lab 06 - Validación del catálogo de roles PAM

# Localizar la carpeta raíz del proyecto
$rutaProyecto = Split-Path -Parent $PSScriptRoot

# Construir la ruta del catálogo CSV
$rutaDatos = Join-Path $rutaProyecto "data"
$rutaCatalogo = Join-Path $rutaDatos "catalogo_roles.csv"

# Comprobar que el archivo existe
if (-not (Test-Path -LiteralPath $rutaCatalogo -PathType Leaf)) {
    throw "No se encuentra el catálogo: $rutaCatalogo"
}

# Importar los roles
$roles = @(Import-Csv -LiteralPath $rutaCatalogo)

# Comprobar si hay identificadores de rol duplicados
$rolesDuplicados = @(
    $roles |
        Group-Object -Property RoleId |
        Where-Object { $_.Count -gt 1 }
)

if ($rolesDuplicados.Count -gt 0) {
    $idsDuplicados = $rolesDuplicados.Name -join ", "
    throw "Se encontraron RoleId duplicados: $idsDuplicados"
}

Write-Host "Identificadores de rol duplicados: 0"

# Comprobar que las duraciones sean enteros entre 1 y 24
$duracionesInvalidas = @(
    $roles | Where-Object {
        $_.DuracionMaxHoras -notmatch '^\d+$' -or
        [int]$_.DuracionMaxHoras -lt 1 -or
        [int]$_.DuracionMaxHoras -gt 24
    }
)

if ($duracionesInvalidas.Count -gt 0) {
    throw "Se encontraron roles con duraciones invalidas."
}

Write-Host "Duraciones validas: $($roles.Count)"

# Comprobar que los campos obligatorios no esten vacios
$registrosIncompletos = @(
    $roles | Where-Object {
        [string]::IsNullOrWhiteSpace($_.RoleId) -or
        [string]::IsNullOrWhiteSpace($_.NombreRol) -or
        [string]::IsNullOrWhiteSpace($_.NivelRiesgo) -or
        [string]::IsNullOrWhiteSpace($_.AprobadorRequerido)
    }
)

if ($registrosIncompletos.Count -gt 0) {
    throw "Se encontraron roles con campos obligatorios vacios."
}

Write-Host "Registros incompletos: 0"

# Comprobar que RequiereTicket solo contenga true o false
$valoresTicketInvalidos = @(
    $roles | Where-Object {
        $_.RequiereTicket -notin @("true", "false")
    }
)

if ($valoresTicketInvalidos.Count -gt 0) {
    throw "Se encontraron valores invalidos en RequiereTicket."
}

Write-Host "Valores de RequiereTicket invalidos: 0"

# Mostrar el resultado
Write-Host "Roles cargados: $($roles.Count)"
$roles | Format-Table RoleId, NombreRol, NivelRiesgo, DuracionMaxHoras -AutoSize
