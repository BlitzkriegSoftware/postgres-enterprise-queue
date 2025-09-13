<#
    .SYNOPSIS
       Start PostgreSQL on Docker

    .DESCRIPTION
        See above
    
    .INPUTS
        none

    .OUTPUTS
        Sucess or failure 
#>

Import-Module Microsoft.PowerShell.Utility

[int]$PORT=5432
[string]$NAME='postgressvr'
[string]$IMAGE='postgres:13.22-trixie'
[string]$USERNAME='postgres'
[string]$PASSWORD='password123-'
[string]$VOL="/var/lib/postgresql/data"
[string]$SRC="/var/lib/postgresql/src"

function Get-DockerRunning {

	[bool]$DockerAlive = $false

	try {
		$null = Get-Process 'com.docker.backend' -ErrorAction Stop
		$DockerAlive = $true;
	} catch {
		$DockerAlive = $false;
	}

	return $DockerAlive
}

#
# Main
#

Set-StrictMode -Version 2.0
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12
Push-Location $PSScriptRoot

[bool]$da = Get-DockerRunning
if(! $da) {
	Write-Error "docker must be running 1st"
	return 1
}

[string]$dbPath = Join-Path -Path $PSScriptRoot -ChildPath "data"
[string]$srcPath = Join-Path -Path $PSScriptRoot -ChildPath "src"

$null = (setx POSTGRES_USER "${USERNAME}") 2> $null
$null = (setx POSTGRES_PASSWORD "${PASSWORD}") 2> $null

# Dispose of any old running ones
$null = (docker stop "${NAME}") 2> $null
$null = (docker rm "${NAME}") 2> $null

# Ensure clean pull of pinned image
$null = (docker pull $IMAGE) 2> $null

# Force a clean start
$pgDir =  Join-Path -Path $dbPath -ChildPath "pgdata"
$null = (Remove-Item -Path $pgDir -Recurse -Force) 2> $null

docker run -d -e "POSTGRES_USER=${USERNAME}" -e POSTGRES_PASSWORD="${PASSWORD}" -e PGDATA='/var/lib/postgresql/data/pgdata' --name="${NAME}" -p "${PORT}:${PORT}" -v "${dbPath}:${VOL}" -v "${srcPath}:${SRC}" postgres

Write-Output "PostgreSql running on ${PORT} as ${USERNAME} with ${PASSWORD}"