<#
    .SYNOPSIS
       Create an Enterprise Queue for the Specified Connection String and Schema
       With Optional Role

    .OUTPUTS
        Postgres Objects
        Sucess or failure 
#>

Import-Module Microsoft.PowerShell.Utility

param (
    [Parameter(Mandatory)][string]$ConnectionString,
    [Parameter(Mandatory)][string]$SchemaName,
    [string]$RoleName = ''
)

# Variables
[int]$exitCode = 0;

#
# Main
#
Set-StrictMode -Version 2.0
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12
Push-Location $PSScriptRoot

if ([string]::IsNullOrWhiteSpace($ConnectionString)) {
    Write-Error "`-ConnectionString` is a required parameter";
    $exitCode = 1;
}

if ([string]::IsNullOrWhiteSpace($SchemaName)) {
    Write-Error "`-SchemaName` is a required parameter";
    $exitCode = 2;
}

# Copy SQL Files to temp
[string]$sqlFolder = Join-Path -Path $PSScriptRoot -ChildPath "data/sql";
[string]$tempFolder = Join-Path -Path $PSScriptRoot -ChildPath "data/temp";
if (Test-Path $tempFolder) {
    Remove-Item $tempFolder -Force -Recurse 
}
New-Item -Path $tempFolder -ItemType Directory
Copy-Item -Path "$sqlFolder\*.sql" -Destination $tempFolder
# replace schema in all files
$SQL_FILES = Get-ChildItem -Path "${tempFolder}\*.sql" -File -Recurse
$SQL_FILES = $SQL_FILES | Sort-Object 
foreach ($FilePath in $SQL_FILES) {
    (Get-Content -Raw -Path $FilePath) -replace "{schema}", "${SchemaName}" | Set-Content -Path $FilePath -NoNewline
    if (-not [string]::IsNullOrWhiteSpace($RoleName)) {
        (Get-Content -Raw -Path $FilePath) -replace "{rolename}", "${RoleName}" | Set-Content -Path $FilePath -NoNewline
    }
}
# Make linux file endings
foreach ($FilePath in $SQL_FILES) {
    (Get-Content -Raw -Path $FilePath) -replace "`r`n", "`n" | Set-Content -Path $FilePath -NoNewline
}

# Play the SQL Scripts (in order) at Postgres Instance
foreach ($FilePath in $SQL_FILES) {
    [string]$filename = [System.IO.Path]::GetFileName($FilePath)
    $filename = "/var/lib/postgresql/data/temp/${filename}";

}

#
# Exit()
Pop-Location
return $exitCode;
