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
[string]$HOST="localhost"
[string]$NAME='postgressvr'
[string]$IMAGE='postgres:13.22-trixie'
[string]$MASTERDB='postgres'
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

# Dispose of any old running Postgres
$null = (docker stop "${NAME}") 2> $null
$null = (docker rm "${NAME}") 2> $null
SScriptRoot -ChildPath "src"

# Set working variables in PS1
$null = (setx POSTGRES_USER "${USERNAME}") 2> $null
$null = (setx POSTGRES_PASSWORD "${PASSWORD}") 2> $null

# Volume mapping path
[string]$dbPath = Join-Path -Path $PSScriptRoot -ChildPath "data"
[string]$srcPath = Join-Path -Path $P

# Create .pgpass file
$PGPASS_LINES = @(
	"# File: $HOME/.pgpass",
	"#       chmod 600 /home/myusername/.pgpass",
	"#       export PGPASSFILE=$HOME/.pgpass",
	"#",
	"# Configuration:",
	"#   hostname:port:database:username:password",
	"#",
	"${HOST}:${PORT}:${MASTERDB}:${USERNAME}:${PASSWORD}"
)

[string]$PGPASS_FILE="./data/.pgpass" 
if (Test-Path $PGPASS_FILE) {
    Remove-Item $PGPASS_FILE -Force
}
foreach($line in $PGPASS_LINES) {
	Write-Output $line >> $PGPASS_FILE
}

# Windows to linux file endings
$FILES_TO_PATCH = @(
	"./data/postgres_conf_adds.txt",
	"./data/.pgpass"
)

foreach ($FilePath in $FILES_TO_PATCH) {
	(Get-Content -Raw -Path $FilePath) -replace "`r`n","`n" | Set-Content -Path $FilePath -NoNewline
}

# Force a clean start
$pgDir =  Join-Path -Path $dbPath -ChildPath "pgdata"
$null = (Remove-Item -Path $pgDir -Recurse -Force) 2> $null

# Ensure clean pull of pinned image
$null = (docker pull $IMAGE) 2> $null

# Start the container
docker run -d `
	-e "POSTGRES_USER=${USERNAME}" `
	-e "POSTGRES_PASSWORD=${PASSWORD}" `
	-e "PGPASSFILE=/var/lib/postgresql/data/.pgpass" `
	-e "PGDATA='/var/lib/postgresql/data/pgdata'" `
	--name="${NAME}" `
	-v "${dbPath}:${VOL}" -v "${srcPath}:${SRC}" `
	-p "${PORT}:${PORT}" postgres

# Command stack to customize Postgres
$CMDS = @(
	"# Upgrade",
	"apt update -y",
	"apt upgrade -y",
	"apt install curl ca-certificates",
	"# Register plug-in source",
	"/usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y",
	"# Cron Plug-In",
	"apt install postgresql-16-cron -y",
	"cp ./pgdata/postgresql.conf  ./pgdata/postgresql.conf.backup",
	"sed -i /#shared_preload_libraries/s/#shared_preload_libraries/shared_preload_libraries/g ./pgdata/postgresql.conf",
	"sed -i /shared_preload_libraries/s/\'\'/\'pg_cron\'/g ./pgdata/postgresql.conf",
	"cat ./postgres_conf_adds.txt >> ./pgdata/postgresql.conf",
	"# Restart DB",
	"systemctl restart postgresql"
)

# Execute command sequence to set up plug-ins
foreach ($cl in $CMDS) {
	docker exec --workdir "${SRC}" "${NAME}" "${cl}"
}

Write-Output "PostgreSql running on ${PORT} as ${USERNAME} with ${PASSWORD}"