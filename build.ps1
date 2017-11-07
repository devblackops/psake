[cmdletbinding()]
param()

Get-PackageProvider -Name Nuget -ForceBootstrap -Verbose:$false | Out-Null
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -Verbose:$false

'BuildHelpers', 'Pester' | Foreach-Object {
    if (-not (Get-Module -Name $_ -ErrorAction SilentlyContinue)) {
        Install-Module -Name $_ -AllowClobber
        Import-Module -Name $_
    }
}

Set-BuildEnvironment -Force

# Setup dotnet
. "$PSScriptRoot/build/tools.ps1"
$dotnetArguments = @{
    Channel = 'Current'
    Version = 'latest'
    NoSudo = $false
}
Install-Dotnet @dotnetArguments
$Env:PATH += "$([IO.Path]::PathSeparator)$Env:HOME/.dotnet"
dotnet build -version -nologo

$testResults = Invoke-Pester -Path $PSScriptRoot/tests

exit $testResults.FailedCount
