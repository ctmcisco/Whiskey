#Requires -Version 4
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-WhiskeyTest.ps1' -Resolve)

[Whiskey.Context]$context = $null
$runByDeveloper = $false
$runByBuildServer = $false
$publish = $false
$publishingTasks = $null
$buildPipelineFails = $false
$buildPipelineName = 'Build'
$publishPipelineFails = $false
$publishPipelineName = 'Publish'

function Init
{
    [Whiskey.Context]$script:context = $null
    $script:runByDeveloper = $false
    $script:runByBuildServer = $false
    $script:publish = $false
    $script:publishingTasks = $null
    $script:buildPipelineFails = $false
    $script:buildPipelineName = 'Build'
    $script:publishPipelineFails = $false
    $script:publishPipelineName = 'Publish'
}

function Assert-ContextPassedTo
{
    param(
        $FunctionName,
        $Times = 1
    )

    $expectedContext = $context
    Assert-MockCalled -CommandName $FunctionName -ModuleName 'Whiskey' -Times $Times -ParameterFilter {
        if( $TaskContext )
        {
            $Context = $TaskContext
        }

        #$DebugPreference = 'Continue'
        Write-Debug ('-' * 80)
        Write-Debug 'TaskContext:'
        $TaskContext | Out-String | Write-Debug
        Write-Debug 'Context:'
        $Context | Out-String | Write-Debug
        Write-Debug 'Expected Context:'
        $expectedContext | Out-String | Write-Debug
        Write-Debug ('-' * 80)
        [Object]::ReferenceEquals($Context,$expectedContext) }
}

function GivenBuildPipelineFails
{
    $script:buildPipelineFails = $true
}

function GivenBuildPipelinePasses
{
    $script:buildPipelineFails = $false
}

function GivenBuildPipelineName
{
    param(
        $Name
    )

    $script:buildPipelineName = $Name
}

function GivenPreviousBuildOutput
{
    New-Item -Path (Join-Path -Path $TestDrive.FullName -ChildPath '.output\file.txt') -ItemType 'File' -Force
}

function GivenNotPublishing
{
    $script:publish = $false
}

function GivenPublishing
{
    $script:publish = $true
}

function GivenPublishingPipelineFails
{
    $script:publishPipelineFails = $true
}

function GivenPublishPipelineName
{
    param(
        $Name
    )

    $script:publishPipelineName = $Name
}

function GivenPublishingPipelineSucceeds
{
    $script:publishPipelineFails = $false
}

function GivenRunByBuildServer
{
    $script:runByDeveloper = $false
    $script:runByBuildServer = $true
}

function GivenRunByDeveloper
{
    $script:runByDeveloper = $true
    $script:runByBuildServer = $false
}

function GivenThereAreNoPublishingTasks
{
    $script:publishingTasks = $null
}

function GivenThereArePublishingTasks
{
    $script:publishing = $true
    $script:publishingTasks = @( @{ 'TaskOne' = @{ } } )
}

function ThenBuildOutputRemoved
{
    It ('should remove .output directory') {
        Join-Path -Path ($whiskeyYmlPath | Split-Path) -ChildPath '.output' | Should -Not -Exist
    }
}

function ThenPipelineRan
{
    param(
        $Name,
        $Times = 1
    )

    $qualifier = ''
    if( $Times -lt 1 )
    {
        $qualifier = 'not '
    }

    It ('should {0}run the {1} pipeline' -f $qualifier,$Name) {
        $expectedPipelineName = $Name
        Assert-MockCalled -CommandName 'Invoke-WhiskeyPipeline' -ModuleName 'Whiskey' -Times $Times -ParameterFilter { $Name -eq $expectedPipelineName }
        if( $Times )
        {
            Assert-ContextPassedTo 'Invoke-WhiskeyPipeline' -Times $Times
        }
    }
}

function ThenBuildPipelineRan
{
    param(
        $Times = 1
    )

    ThenPipelineRan $buildPipelineName -Times $Times
}

function ThenBuildOutputNotRemoved
{
    It ('should not remove .output directory') {
        Join-Path -Path $TestDrive.FullName -ChildPath '.output\file.txt' | Should -Exist
    }
}

function ThenBuildOutputRemoved
{
    It ('should remove .output directory') {
        Join-Path -Path $TestDrive.FullName -ChildPath '.output' | Should -Not -Exist
    }
}

function ThenBuildRunInMode
{
    param(
        $ExpectedRunMode
    )

    It ('should run in ''{0}'' mode' -f $ExpectedRunMode) {
        $context.RunMode | Should -Be $ExpectedRunMode
    }
}

function ThenBuildStatusSetTo
{
    param(
        [string]
        $ExpectedStatus
    )

    It ('should set commmit build status to ''{0}''' -f $ExpectedStatus) {
        Assert-MockCalled -CommandName 'Set-WhiskeyBuildStatus' -ModuleName 'Whiskey' -Times 1 -ParameterFilter { $Status -eq $ExpectedStatus }
        Assert-ContextPassedTo 'Set-WhiskeyBuildStatus'
    }
}

function ThenBuildStatusMarkedAsCompleted
{
    ThenBuildStatusSetTo 'Started'
    ThenBuildStatusSetTo 'Completed'
}

function ThenBuildStatusMarkedAsFailed
{
    ThenBuildStatusSetTo 'Started'
    ThenBuildStatusSetTo 'Failed'
}

function ThenContextPassedWhenSettingBuildStatus
{
    ThenMockCalled 'Set-WhiskeyBuildStatus' -Times 2
}

function ThenPublishPipelineRan
{
    ThenPipelineRan -Name $publishPipelineName -Times 1
}

function ThenPublishPipelineNotRun
{
    ThenPipelineRan -Name $publishPipelineName -Times 0
}

function WhenRunningBuild
{
    [CmdletBinding()]
    param(
        [string[]]
        $PipelineName,

        [Switch]
        $WithCleanSwitch,

        [Switch]
        $WithInitializeSwitch
    )

    Mock -CommandName 'Set-WhiskeyBuildStatus' -ModuleName 'Whiskey'

    Mock -CommandName 'Invoke-WhiskeyPipeline' -ModuleName 'Whiskey' -MockWith ([scriptblock]::Create(@"
        #`$DebugPreference = 'Continue'

        `$buildPipelineFails = `$$($buildPipelineFails)
        `$publishPipelineFails = `$$($publishPipelineFails)

        Write-Debug ('Name  {0}' -f `$Name)
        Write-Debug `$buildPipelineFails
        Write-Debug `$publishPipelineFails

        if( `$Name -eq "$buildPipelineName" -and `$buildPipelineFails )
        {
            throw ('Build pipeline fails!')
        }

        if( `$Name -eq "$publishPipelineName" -and `$publishPipelineFails )
        {
            throw ('Publish pipeline fails!')
        }
"@))

    $config = @{
        $buildPipelineName = @();
    }

    if( $publishingTasks )
    {
        $config[$publishPipelineName] = $publishingTasks
    }

    $script:context = New-WhiskeyContextObject
    $context.BuildRoot = $TestDrive.FullName;
    $context.Configuration = $config;
    $context.OutputDirectory = (Join-Path -Path $TestDrive.FullName -ChildPath '.output');
    if( $runByDeveloper )
    {
        $context.RunBy = [Whiskey.RunBy]::Developer
    }
    if( $runByBuildServer )
    {
        $context.RunBy = [Whiskey.RunBy]::BuildServer
    }
    $context.Publish = $publish;
    $context.RunMode = [Whiskey.RunMode]::build

    $Global:Error.Clear()
    $script:threwException = $false
    try
    {
        $optionalParams = @{}
        if( $WithCleanSwitch )
        {
            $optionalParams['Clean'] = $true
        }
        elseif( $WithInitializeSwitch )
        {
            $optionalParams['Initialize'] = $true
        }

        $pipelineNameParam = @{ }
        if( $PipelineName )
        {
            $optionalParams['PipelineName'] = $PipelineName
        }
        $startedAt = Get-Date
        Start-Sleep -Milliseconds 1
        $context.StartedAt = [DateTime]::MinValue
        Invoke-WhiskeyBuild -Context $context @optionalParams
        It ('should set build start time') {
            $context.StartedAt | Should -BeGreaterThan $startedAt
        }
    }
    catch
    {
        $script:threwException = $true
        Write-Error $_
    }
}

Describe 'Invoke-WhiskeyBuild.when build passes' {
    Context 'By Developer' {
        Init
        GivenRunByDeveloper
        GivenBuildPipelinePasses
        GivenThereArePublishingTasks
        GivenPublishing
        GivenPublishingPipelineSucceeds
        WhenRunningBuild
        ThenBuildPipelineRan
        ThenPublishPipelineRan
        ThenBuildStatusMarkedAsCompleted
    }
    Context 'By Build Server' {
        Init
        GivenRunByBuildServer
        GivenBuildPipelinePasses
        GivenPublishing
        GivenThereArePublishingTasks
        WhenRunningBuild
        ThenBuildPipelineRan
        ThenPublishPipelineRan
        ThenBuildStatusMarkedAsCompleted
    }
}

Describe 'Invoke-WhiskeyBuild.when build pipeline fails' {
    Context 'By Developer' {
        Init
        GivenRunByDeveloper
        GivenBuildPipelineFails
        GivenPublishingPipelineSucceeds
        WhenRunningBuild -ErrorAction SilentlyContinue
        ThenBuildPipelineRan
        ThenPublishPipelineNotRun
        ThenBuildStatusMarkedAsFailed
    }
    Context 'By Build Server' {
        Init
        GivenRunByBuildServer
        GivenBuildPipelineFails
        GivenPublishingPipelineSucceeds
        WhenRunningBuild -ErrorAction SilentlyContinue
        ThenBuildPipelineRan
        ThenPublishPipelineNotRun
        ThenBuildStatusMarkedAsFailed
    }
}

Describe 'Invoke-WhiskeyBuild.when publishing pipeline fails' {
    Context 'By Developer' {
        Init
        GivenRunByDeveloper
        GivenPublishing
        GivenBuildPipelinePasses
        GivenThereArePublishingTasks
        GivenPublishingPipelineFails
        WhenRunningBuild -ErrorAction SilentlyContinue
        ThenBuildPipelineRan
        ThenPublishPipelineRan
        ThenBuildStatusMarkedAsFailed
    }
    Context 'By Build Server' {
        Init
        GivenRunByBuildServer
        GivenPublishing
        GivenBuildPipelinePasses
        GivenThereArePublishingTasks
        GivenPublishingPipelineFails
        WhenRunningBuild -ErrorAction SilentlyContinue
        ThenBuildPipelineRan
        ThenPublishPipelineRan
        ThenBuildStatusMarkedAsFailed
    }
}

Describe 'Invoke-WhiskeyBuild.when cleaning' {
    Init
    GivenRunByDeveloper
    GivenBuildPipelinePasses
    GivenNotPublishing
    GivenPreviousBuildOutput
    WhenRunningBuild -WithCleanSwitch
    ThenBuildOutputRemoved
    ThenBuildRunInMode 'Clean'
}

Describe 'Invoke-WhiskeyBuild.when initializaing' {
    Init
    GivenRunByDeveloper
    GivenBuildPipelinePasses
    GivenNotPublishing
    GivenPreviousBuildOutput
    WhenRunningBuild -WithInitializeSwitch
    ThenBuildRunInMode 'Initialize'
}

Describe 'Invoke-WhiskeyBuild.when in default run mode' {
    Init
    GivenRunByDeveloper
    GivenBuildPipelinePasses
    GivenNotPublishing
    GivenPreviousBuildOutput
    WhenRunningBuild
    ThenBuildOutputNotRemoved
    ThenBuildRunInMode 'Build'
}

Describe 'Invoke-WhiskeyBuild.when not publishing' {
    Init
    GivenRunByBuildServer
    GivenNotPublishing
    GivenThereArePublishingTasks
    GivenPublishingPipelineSucceeds
    WhenRunningBuild
    ThenPublishPipelineNotRun
}


Describe 'Invoke-WhiskeyBuild.when publishing but no tasks' {
    Init
    GivenRunByBuildServer
    GivenPublishing
    GivenThereAreNoPublishingTasks
    GivenPublishingPipelineSucceeds
    WhenRunningBuild
    ThenPublishPipelineNotRun
}

Describe 'Invoke-WhiskeyBuild.when running specific pipelines' {
    Init
    GivenRunByBuildServer
    GivenPublishing
    WhenRunningBuild -PipelineName 'Fubar','snafu'
    ThenPublishPipelineNotRun
    ThenPipelineRan 'Fubar'
    ThenPipelineRan 'Snafu'
    ThenBuildPipelineRan -Times 0
}

Describe 'Invoke-WhiskeyBuild.when running legacy pipelines' {
    Init
    GivenRunByBuildServer
    GivenBuildPipelineName 'BuildTasks'
    GivenPublishing
    GivenThereArePublishingTasks
    WhenRunningBuild
    ThenBuildPipelineRan
    ThenPublishPipelineRan
    ThenBuildStatusMarkedAsCompleted
}
