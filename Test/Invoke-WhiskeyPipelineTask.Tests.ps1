
#Requires -Version 4
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-WhiskeyTest.ps1' -Resolve)

$clean = $false
$initialize = $false
$pipelines = $null
$threwException = $false

function GivenCleanMode
{
    $script:clean = $true
    Mock -CommandName 'Uninstall-WhiskeyTool' -ModuleName 'Whiskey'
}

function GivenInitializeMode
{
    $script:initialize = $true
    Mock -CommandName 'Install-WhiskeyTool' -ModuleName 'Whiskey'
}

function GivenPipeline
{
    param(
        $Name,
        $Yaml
    )

     $pipelines.Add(@"
$($Name):
$($Yaml)
"@)
}

function Init
{
    $script:clean = $false
    $script:initialize = $false
    $script:pipelines = New-Object 'Collections.Generic.List[string]'
    $script:threwException = $false
}

function ThenPowershellModule
{
    param(
        [Parameter(Position=0)]
        [string]
        $Name,

        [Parameter(ParameterSetName='Cleaned')]
        [switch]
        $Cleaned,

        [Parameter(ParameterSetName='Installed')]
        [switch]
        $Installed
    )

    if ($Cleaned)
    {
        It 'should run Pipeline tasks when in Clean mode' {
            Assert-MockCalled -CommandName 'Uninstall-WhiskeyTool' -ModuleName $Name -ParameterFilter { $ModuleName -eq 'Whiskey' }
        }
    }
    elseif ($Installed)
    {
        It 'should run Pipeline tasks when in Initialize mode' {
            Assert-MockCalled -CommandName 'Install-WhiskeyTool' -ModuleName $Name -ParameterFilter { $ModuleName -eq 'Whiskey' }
        }
    }
}

function ThenPipelineFailed
{
    param(
        $Pattern
    )

    It ('should write a terminating error') {
        $threwException | Should -Be $true
    }


    It ('should fail with message that matches /{0}/' -f $Pattern) {
        $Global:Error | Should -Match $Pattern
    }
}

function ThenPipelineRun
{
    param(
        $Name,
        [string]
        $BecauseFileExists
    )

    It ('should run pipeline ''{0}''' -f $Name) {
        Join-Path -Path $TestDrive.FullName -ChildPath $BecauseFileExists | Should -Exist
    }
}

function WhenRunningTask
{
    [CmdletBinding()]
    param(
    )

    $whiskeyYmlPath = Join-Path -Path $TestDrive.FullName -ChildPath 'whiskey.yml'
    foreach( $pipeline in $pipelines )
    {
        $pipeline | Add-Content -Path $whiskeyYmlPath 
    }

    $context = New-WhiskeyTestContext -ForDeveloper -ConfigurationPath $whiskeyYmlPath
    $Global:Error.Clear()
    try
    {
        if ($clean)
        {
            Invoke-WhiskeyBuild -Context $context -Clean
        }
        elseif ($initialize)
        {
            Invoke-WhiskeyBuild -Context $context -Initialize
        }
        else
        {
            Invoke-WhiskeyBuild -Context $context
        }
    }
    catch
    {
        Write-Error $_
        $script:threwException = $true
    }
}

Describe 'Pipeline.when running another pipeline' {
    Init
    GivenPipeline 'Fubar' @'
- CopyFile:
    Path: whiskey.yml
    DestinationDirectory: $(WHISKEY_PIPELINE_NAME)
'@
    GivenPipeline 'BuildTasks' @'
- Pipeline:
    Name: Fubar
- CopyFile:
    Path: whiskey.yml
    DestinationDirectory: $(WHISKEY_PIPELINE_NAME)
'@
    WhenRunningTask
    ThenPipelineRun 'Fubar' -BecauseFileExists 'Fubar\whiskey.yml'
    ThenPipelineRun 'BuildTasks' -BecauseFileExists 'BuildTasks\whiskey.yml'
}

Describe 'Pipeline.when running multiple pipelines' {
    Init
    GivenPipeline 'Fubar' @'
- CopyFile:
    Path: whiskey.yml
    DestinationDirectory: $(WHISKEY_PIPELINE_NAME)
'@
    GivenPipeline 'Snafu' @'
- CopyFile:
    Path: whiskey.yml
    DestinationDirectory: $(WHISKEY_PIPELINE_NAME)
'@

    GivenPipeline 'BuildTasks' @'
- Pipeline:
    Name: 
    - Fubar
    - Snafu
- CopyFile:
    Path: whiskey.yml
    DestinationDirectory: $(WHISKEY_PIPELINE_NAME)
'@
    WhenRunningTask
    ThenPipelineRun 'Fubar' -BecauseFileExists 'Fubar\whiskey.yml'
    ThenPipelineRun 'Snafu' -BecauseFileExists 'Snafu\whiskey.yml'
    ThenPipelineRun 'BuildTasks' -BecauseFileExists 'BuildTasks\whiskey.yml'
}

Describe 'Pipeline.when Name property is missing' {
    Init
    GivenPipeline 'BuildTasks' @'
- Pipeline
'@
    WhenRunningTask -ErrorAction SilentlyContinue
    ThenPipelineFailed 'mandatory'
}

Describe 'Pipeline.when Name property doesn''t have a value' {
    Init
    GivenPipeline 'BuildTasks' @'
- Pipeline:
    Name: 
'@
    WhenRunningTask -ErrorAction SilentlyContinue
    ThenPipelineFailed 'is missing or doesn''t have a value'
}

Describe 'Pipeline.when running in Clean mode' {
    Init
    GivenCleanMode
    GivenPipeline 'Fubar' @'
- GetPowerShellModule:
    Name: Whiskey
    Version: 0.18.0
'@
    GivenPipeline 'BuildTasks' @'
- Pipeline:
    Name: Fubar
'@
    WhenRunningTask
    ThenPowershellModule 'Whiskey' -Cleaned
}

Describe 'Pipeline.when running in Initialize mode' {
    Init
    GivenInitializeMode
    GivenPipeline 'Fubar' @'
- GetPowerShellModule:
    Name: Whiskey
    Version: 0.18.0
'@
    GivenPipeline 'BuildTasks' @'
- Pipeline:
    Name: Fubar
'@
    WhenRunningTask
    ThenPowershellModule 'Whiskey' -Installed
}