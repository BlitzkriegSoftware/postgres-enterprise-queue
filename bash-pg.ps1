<#
	
    .SYNOPSIS
       Start PostgreSQL Bash Session on Docker Image

    .DESCRIPTION
        See above
    
    .INPUTS
        none

    .OUTPUTS
        Sucess or failure 
#>
[string]$NAME = 'postgressvr'
[string]$VOL = '/var/lib/postgresql/data'
[string]$BIN = '/usr/lib/postgresql/16/bin'
[string]$LOG = '/var/log/postgresql'
Write-Output "SQL Scripts Folder: ${VOL}"
Write-Output "Postgres Logs: ${LOG}"
Write-Output "Postgres Utilities Folder: ${BIN}"
Write-Output "In general to run postgres commands you will have to run as the 'postgres' user"
Write-Host   "su -- postgres -c {pg_command}" -ForegroundColor DarkGray

docker exec -it --workdir "${VOL}" "${NAME}" /bin/bash