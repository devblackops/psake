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

$testResults = Invoke-Pester -Path ./tests -PassThru -OutputFile ./testResults.xml

# Upload test artifacts to AppVeyor
if ($env:APPVEYOR_JOB_ID) {
    $wc = New-Object 'System.Net.WebClient'
    $wc.UploadFile("https://ci.appveyor.com/api/testresults/xunit/$($env:APPVEYOR_JOB_ID)", (Resolve-Path ./testResults.xml))
}

if ($testResults.FailedCount -gt 0) {
    throw "$FailedCount tests failed!"
}
