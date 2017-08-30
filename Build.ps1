# Taken from psake https://github.com/psake/psake

<#
.SYNOPSIS
  This is a helper function that runs a scriptblock and checks the PS variable $lastexitcode
  to see if an error occcured. If an error is detected then an exception is thrown.
  This function allows you to run command-line programs without having to
  explicitly check the $lastexitcode variable.
.EXAMPLE
  exec { svn info $repository_trunk } "Error executing SVN. Please verify SVN command-line client is installed"
#>
function Exec
{
    [CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=1)][scriptblock]$cmd,
        [Parameter(Position=1,Mandatory=0)][string]$errorMessage = ($msgs.error_bad_command -f $cmd)
    )
    & $cmd
    if ($lastexitcode -ne 0) {
        throw ("Exec: " + $errorMessage)
    }
}

if(Test-Path .\src\Hangfire.LiteDB\artifacts) { Remove-Item .\src\Hangfire.LiteDB\artifacts -Force -Recurse }

exec { & dotnet restore }

$tag = $(git tag -l --points-at HEAD)
$revision = @{ $true = "{0:00000}" -f [convert]::ToInt32("0" + $env:APPVEYOR_BUILD_NUMBER, 10); $false = "local" }[$env:APPVEYOR_BUILD_NUMBER -ne $NULL];
$suffix = @{ $true = ""; $false = "ci-$revision"}[$tag -ne $NULL -and $revision -ne "local"]
$commitHash = $(git rev-parse --short HEAD)
$buildSuffix = @{ $true = "$($suffix)-$($commitHash)"; $false = "$($branch)-$($commitHash)" }[$suffix -ne ""]

exec { & dotnet build Hangfire.LiteDB.sln -c Release --version-suffix=$buildSuffix -v q /nologo }

Push-Location -Path .\test\Hangfire.LiteDB.Test

exec { & dotnet test -c Release }

Pop-Location
<#
$samples = Get-ChildItem .\samples\*

foreach ($sample in $samples) {
    Push-Location -Path $sample

    exec { & dotnet run -c Release --no-build }

    Pop-Location
}
#>

exec { & dotnet pack .\src\Hangfire.LiteDB\Hangfire.LiteDB.csproj -c Release -o .\artifacts --include-symbols --no-build --version-suffix=$suffix }
