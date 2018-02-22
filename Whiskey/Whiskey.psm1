$numRobocopyThreads = Get-CimInstance -ClassName 'Win32_Processor' | Select-Object -ExpandProperty 'NumberOfLogicalProcessors' | Measure-Object -Sum | Select-Object -ExpandProperty 'Sum'
$numRobocopyThreads *= 2

$events = @{ }

$7z = Join-Path -Path $PSScriptRoot -ChildPath 'bin\7-Zip\7z.exe' -Resolve

$buildStartedAt = [DateTime]::MinValue

$supportsWriteInformation = Get-Command -Name 'Write-Information' -ErrorAction Ignore

$attr = New-Object -TypeName 'Whiskey.TaskAttribute' -ArgumentList 'Whiskey' -ErrorAction Ignore
if( -not ($attr | Get-Member 'SupportsClean') )
{
    Write-Error -Message ('You''ve got an old version of Whiskey loaded. Please open a new PowerShell session.') -ErrorAction Stop
}

Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Functions'),(Join-Path -Path $PSScriptRoot -ChildPath 'Tasks') -Filter '*.ps1' |
    ForEach-Object { . $_.FullName }

if( (Get-Module -Name 'PackageManagement') )
{
    Remove-Module -Name 'PackageManagement' -Force
}

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '.\PackageManagement\PackageManagement.psd1')

if( (Get-Module -Name 'PowerShellGet') )
{
    Remove-Module -Name 'PowerShellGet' -Force
}

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '.\PowerShellGet\PowerShellGet.psd1')
