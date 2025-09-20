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
[string]$SERVER="localhost"
[string]$NAME='postgressvr'
[string]$IMAGE='postgres:13.22-trixie'
[string]$MASTERDB='postgres'
[string]$USERNAME='postgres'
[string]$PASSWORD='password123-'
[string]$VOL="/var/lib/postgresql/data"
[string]$SRC="/var/lib/postgresql/src"
[string]$PGPASS_FILE='/var/lib/postgresql/data/.pgpass'
[string]$CUSTOM_IMAGE='postgres_cron'

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

# Dispose of any old running Postgres
$null = (docker stop "${NAME}") 2> $null
$null = (docker rm "${NAME}") 2> $null

# Set working variables in PS1
$null = (setx POSTGRES_USER "${USERNAME}") 2> $null
$null = (setx POSTGRES_PASSWORD "${PASSWORD}") 2> $null

# Volume mapping path
[string]$dbPath = Join-Path -Path $PSScriptRoot -ChildPath "data"
[string]$srcPath = Join-Path -Path $PSScriptRoot -ChildPath "src"

# Create .pgpass file
$PGPASS_LINES = @(
	"# File: $HOME/.pgpass",
	"#       chmod 600 $HOME/.pgpass",
	"#       export PGPASSFILE=$HOME/.pgpass",
	"#",
	"# Configuration:",
	"#   hostname:port:database:username:password",
	"#",
	"${SERVER}:${PORT}:${MASTERDB}:${USERNAME}:${PASSWORD}"
)

[string]$PGPASS_FILE="./data/.pgpass" 
if (Test-Path $PGPASS_FILE) {
    Remove-Item $PGPASS_FILE -Force
}
foreach($line in $PGPASS_LINES) {
	Write-Output $line >> $PGPASS_FILE
}

# Windows to linux file ending fixs
$FILES_TO_PATCH = @(
	"${PGPASS_FILE}"
)
foreach ($FilePath in $FILES_TO_PATCH) {
	(Get-Content -Raw -Path $FilePath) -replace "`r`n","`n" | Set-Content -Path $FilePath -NoNewline
}

# Force a clean start
$pgDir =  Join-Path -Path $dbPath -ChildPath "pgdata"
$null = (Remove-Item -Path $pgDir -Recurse -Force) 2> $null

# Ensure clean pull of pinned image
#$null = (docker pull $IMAGE) 2> $null
docker build -t "${CUSTOM_IMAGE}" .

# Start the container
docker run -d `
	-e "POSTGRES_USER=${USERNAME}" `
	-e "POSTGRES_PASSWORD=${PASSWORD}" `
	-e "PGPASSFILE=${PGPASS_FILE}" `
	-e PGDATA='/var/lib/postgresql/data/pgdata' `
	--name="${NAME}" `
	--restart always `
	-v "${dbPath}:${VOL}" `
	-v "${srcPath}:${SRC}" `
	-p "${PORT}:${PORT}" "${CUSTOM_IMAGE}"

# Wait for Startup
# Start-Sleep -Seconds 10

# Customize postgres
#$script="configure_pg.sh"
#docker exec --workdir "${SRC}" "${NAME}" "${VOL}/${script}"

Write-Output "PostgreSql running on ${PORT} as ${USERNAME} with ${PASSWORD}"