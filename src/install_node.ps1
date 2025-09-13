<#
    Install nodejs + npm
#>
[string]$NAME='postgressvr'
[string]$SRC="/var/lib/postgresql/src"

# Fix to unix and Run Script - Install Node/Npm
[string]$script='install_node.sh'
[string]$FilePath = Join-Path -Path $PSScriptRoot -ChildPath ".\${script}"
(Get-Content -Raw -Path $FilePath) -replace "`r`n","`n" | Set-Content -Path $FilePath -NoNewline
docker exec --workdir "${SRC}" "${NAME}" "${SRC}/${script}"

# Fix to unix and Run Script - Generate Data
[string]$script='generate_data.sh'
[string]$FilePath = Join-Path -Path $PSScriptRoot -ChildPath ".\${script}"
(Get-Content -Raw -Path $FilePath) -replace "`r`n","`n" | Set-Content -Path $FilePath -NoNewline
docker exec --workdir "${SRC}" "${NAME}" "${SRC}/${script}"