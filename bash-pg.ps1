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
Write-Output "`tsu -- postgres -c {pg_command}"
Write-Output "Postgres Utilities Folder: ${BIN}"
Write-Output "Postgres Logs: ${LOG}"
docker exec -it --workdir "${VOL}" "${NAME}" /bin/bash