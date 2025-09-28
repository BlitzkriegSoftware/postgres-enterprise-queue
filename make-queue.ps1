<#
    .SYNOPSIS
       Create an Enterprise Queue for the Specified Connection String and Schema
       With Optional Role

    .OUTPUTS
        Postgres Objects
        Sucess or failure 
#>

Param (
    # Connection String for Postgres
    [Parameter(Mandatory)]
    [string]$ConnectionString,
    # Schema name to create queue in
    [Parameter(Mandatory)]
    [string]$SchemaName,
    # (optional) Role Name
    [string]$RoleName = ''
)

Import-Module Microsoft.PowerShell.Utility

# Constantts
[int]$ORDER_INDEX_MIN = 110;

# Variables
[int]$exitCode = 0;
[string]$pbin = 'C:\Program Files\PostgreSQL\16\bin\psql.exe';

#
# Functions

function Get-OrderIndex {
    param (
        [string]$ScriptName
    )
    [int]$orderIndex = -1;
    [int]$index = $ScriptName.IndexOf('_');
    if ($index -ge 0) {
        [string]$v = $ScriptName.Substring(0, $index);
        [int]$tv = 0;
        if ([int]::TryParse($v, [ref]$tv)) {
            $orderIndex = $tv;
        }
    }
    return $orderIndex;
}

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
$null = New-Item -Path $tempFolder -ItemType Directory
Copy-Item -Path "$sqlFolder\*.sql" -Destination $tempFolder
# replace schema in all files
$SQL_FILES = Get-ChildItem -Path "${tempFolder}\*.sql" -File -Recurse
$SQL_FILES = $SQL_FILES | Sort-Object 
foreach ($FilePath in $SQL_FILES) {
    (Get-Content -Raw -Path $FilePath) -replace "{schema}", "${SchemaName}" | Set-Content -Path $FilePath -NoNewline
    if (-not [string]::IsNullOrWhiteSpace($RoleName)) {
        (Get-Content -Raw -Path $FilePath) -replace "{rolename}", "${RoleName}" | Set-Content -Path $FilePath -NoNewline
    }
}5
# Make linux file endings
foreach ($FilePath in $SQL_FILES) {
    (Get-Content -Raw -Path $FilePath) -replace "`r`n", "`n" | Set-Content -Path $FilePath -NoNewline
}

# Play the SQL Scripts (in order) at Postgres Instance
foreach ($FilePath in $SQL_FILES) {
    [string]$filename = [System.IO.Path]::GetFileName($FilePath)
    [int]$oi = Get-OrderIndex -ScriptName $filename;
    if ($oi -ge $ORDER_INDEX_MIN) {
        try {
            Write-Output "Executing: ${filename}"
            # Set-PSDebug -Trace 2   
            . $pbin -f $FilePath $ConnectionString
        }
        catch {
            Write-Output "Error: $_"
        } 
        finally {
            # Set-PSDebug -Off
        }
    }
}

#
# Exit()
Pop-Location
return $exitCode;
