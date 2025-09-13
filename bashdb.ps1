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
[string]$NAME='postgressvr'
[string]$VOL='/var/lib/postgresql/data/salesdb'
[string]$BIN='/usr/lib/postgresql/17/bin'
Write-Output "SQL Scripts Folder: ${VOL}"
Write-Output "Postgres Utilities Folder: ${BIN}"
docker exec -it --workdir "${VOL}"  "${NAME}" /bin/bash