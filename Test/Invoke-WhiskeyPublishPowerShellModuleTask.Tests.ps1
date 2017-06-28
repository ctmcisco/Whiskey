Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-WhiskeyTest.ps1' -Resolve)

function Initialize-Test
{
    param(
    )
    $gitBranch = 'origin/develop'
    $filter = { $Path -eq 'env:GIT_BRANCH' }
    $mock = { [pscustomobject]@{ Value = $gitBranch } }.GetNewClosure()
    Mock -CommandName 'Get-Item' -ModuleName 'Whiskey' -ParameterFilter $filter -MockWith $mock
    Mock -CommandName 'Get-Item' -ParameterFilter $filter -MockWith $mock
    Mock -CommandName 'ConvertTo-WhiskeySemanticVersion' -ModuleName 'Whiskey' -MockWith { return [SemVersion.SemanticVersion]'1.2.3' }
}

function Invoke-Publish
{
    param(
        [Parameter(Mandatory=$true)]
        [object]
        $TaskContext,
    
        [Switch]
        $withoutRegisteredRepo,

        [Switch]
        $withoutPublish,

        [String]
        $ForRepositoryName,

        [String]
        $ForFeedName,

        [String]
        $ForManifestPath,

        [Switch]
        $WithDefaultRepo,

        [String]
        $ThatFailsWith,

        [Switch]
        $withNoProgetURI,

        [Switch]
        $WithInvalidPath,

        [Switch]
        $WithNonExistentPath,

        [Switch]
        $WithoutPathParameter,

        [Switch]
        $WithCleanSwitch
    )
    
    

    if( -not $ForRepositoryName )
    {
        $ForRepositoryName = 'thisRepo'
    }
    if ( -not $ForFeedName )
    {
        $ForFeedName = 'thisFeed'
    }
    if( $WithDefaultRepo )
    {
        $TaskParameter = @{ }
    }
    else
    {
        $TaskParameter = @{
                            RepositoryName = $ForRepositoryName;
                            FeedName = $ForFeedName;
        }
    }
    if( $WithInvalidPath )
    {
        $TaskParameter.Add( 'Path', 'MyModule.ps1' )
        New-Item -Path $TestDrive.FullName -ItemType 'file' -Name 'MyModule.ps1'
    }
    elseif( $WithNonExistentPath )
    {
        $TaskParameter.Add( 'Path', 'MyModule.ps1' )
    }
    elseif( -not $WithoutPathParameter )
    {
        $TaskParameter.Add( 'Path', 'MyModule' )
        New-Item -Path $TestDrive.FullName -ItemType 'directory' -Name 'MyModule' 
        $module = Join-Path -Path $TestDrive.FullName -ChildPath 'MyModule'
        if( -not $ForManifestPath )
        {            
            New-Item -Path $module -ItemType 'file' -Name 'MyModule.psd1' -Value @"
@{
    # Version number of this module.
    ModuleVersion = '0.2.0'
}
"@
        }
        else
        {
            $TaskParameter.Add( 'ModuleManifestPath', $ForManifestPath )
        }
    }

    if( -not $withNoProgetURI )
    {
        $publishLocation = $TaskContext.ProgetSession.PowerShellFeedUri
    }
    if( $withoutRegisteredRepo )
    {
        Mock -CommandName 'Get-PSRepository' -ModuleName 'Whiskey' -MockWith { return $false }
    }
    else
    {
        Mock -CommandName 'Get-PSRepository' -ModuleName 'Whiskey' -MockWith { return $true }
    }

    Add-Type -AssemblyName System.Net.Http
    Mock -CommandName 'Register-PSRepository' -ModuleName 'Whiskey' -MockWith { return }
    Mock -CommandName 'Set-Item' -ModuleName 'Whiskey' -ParameterFilter { $Path -eq 'env:PATH' }
    Mock -CommandName 'Publish-Module' -ModuleName 'Whiskey' -MockWith { return }
    $optionalParams = @{ }
    if( $WithCleanSwitch )
    {
        $optionalParams['Clean'] = $True
    }
    
    $Global:Error.Clear()
    $failed = $False
    
    try
    {
        Invoke-WhiskeyPublishPowerShellModuleTask -TaskContext $TaskContext -TaskParameter $TaskParameter @optionalParams
    }
    catch
    {
        $failed = $True
    }
    if( $ThatFailsWith )
    {
        It 'should throw an exception' {
            $failed | Should Be $True
        }
        It 'should exit with error' {
            $Global:Error | Should Match $ThatFailsWith
        }
    }
    else
    {
        It 'should not throw an exception'{
            $failed | Should Be $False
        }
        It 'should exit without error'{
            $Global:Error | Should BeNullOrEmpty
        }
    }
}

function Assert-ModuleNotPublished
{    
    It 'should not attempt to register the module'{
        Assert-MockCalled -CommandName 'Get-PSRepository' -ModuleName 'Whiskey' -Times 0
        Assert-MockCalled -CommandName 'Register-PSRepository' -ModuleName 'Whiskey' -Times 0
    }    
    It 'should not add NuGet.exe to path' {
        Assert-MockCalled -CommandName 'Set-Item' -ModuleName 'Whiskey' -Times 0
    }
    It 'should not attempt to publish the module'{
        Assert-MockCalled -CommandName 'Publish-Module' -ModuleName 'Whiskey' -Times 0
    }
}

function Assert-ModuleRegistered
{
    param(
        [Parameter(Mandatory=$true)]
        [object]
        $TaskContext,
    
        [String]
        $ExpectedRepositoryName,

        [String]
        $ExpectedFeedName,

        [switch]
        $WithDefaultRepo
    )
    if ( $WithDefaultRepo )
    {
        $ExpectedRepositoryName = 'WhsPowerShell'
        $ExpectedFeedName = 'nuget/PowerShell'
    }
    else
    {
        if( -not $ExpectedRepositoryName )
        {
            $ExpectedRepositoryName = 'thisRepo'
        }
        if ( -not $ExpectedFeedName )
        {
            $ExpectedFeedName = 'thisFeed'
        }
    }
    
    $expectedPublishLocation = $TaskContext.ProgetSession.PowerShellFeedUri
    It ('should register the Module')  {
        Assert-MockCalled -CommandName 'Register-PSRepository' -ModuleName 'Whiskey' -Times 1 -ParameterFilter {
            #$DebugPreference = 'Continue'
            Write-Debug -Message ('Repository Name                 expected {0}' -f $ExpectedRepositoryName)
            Write-Debug -Message ('                                actual   {0}' -f $Name)

            Write-Debug -Message ('Source Location                 expected {0}' -f $expectedPublishLocation)
            Write-Debug -Message ('                                actual   {0}' -f $SourceLocation)

            Write-Debug -Message ('Publish Location                expected {0}' -f $expectedPublishLocation)
            Write-Debug -Message ('                                actual   {0}' -f $PublishLocation)

            $Name -eq $ExpectedRepositoryName -and
            $SourceLocation -eq $expectedPublishLocation -and
            $PublishLocation -eq $expectedPublishLocation

        }
    }
    
}

function Assert-ModulePublished
{
    param(
        [Parameter(Mandatory=$true)]
        [object]
        $TaskContext,

        [String]
        $ExpectedRepositoryName = 'thisRepo',

        [String]
        $ExpectedPathName = $TestDrive.FullName+'\MyModule',

        [switch]
        $WithDefaultRepo
    )
    
    if( $WithDefaultRepo )
    {
        $ExpectedRepositoryName = 'WhsPowerShell'
    }

    $WhiskeyBinPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Whiskey\bin' -Resolve
    It ('should add nuget.exe to path so Publish-Module works') {
        Assert-MockCalled -CommandName 'Set-Item' -ModuleName 'Whiskey' -Times 1 -ParameterFilter {
            $Value -eq ('{0};{1}' -f $WhiskeyBinPath,$env:Path)
        }
    }
    
    It ('should publish the Module')  {
        $expectedApiKey = ('{0}:{1}' -f $TaskContext.ProGetSession.Credential.UserName, $TaskContext.ProGetSession.Credential.GetNetworkCredential().Password)
        Assert-MockCalled -CommandName 'Publish-Module' -ModuleName 'Whiskey' -Times 1 -ParameterFilter {
            #$DebugPreference = 'Continue'
            Write-Debug -Message ('Path Name                       expected {0}' -f $ExpectedPathName)
            Write-Debug -Message ('                                actual   {0}' -f $Path)

            Write-Debug -Message ('Repository Name                 expected {0}' -f $ExpectedRepositoryName)
            Write-Debug -Message ('                                actual   {0}' -f $Repository)

            Write-Debug -Message ('ApiKey                          expected {0}' -f $expectedApiKey)
            Write-Debug -Message ('                                actual   {0}' -f $NuGetApiKey)
            
            $Path -eq $ExpectedPathName -and
            $Repository -eq $ExpectedRepositoryName -and
            $NuGetApiKey -eq $expectedApiKey
        }
    }

    It ('should put the PATH environment variable back the way it was') {
        Assert-MockCalled -CommandName 'Set-Item' -ModuleName 'Whiskey' -Times 1 -ParameterFilter {
            $Value -eq $env:PATH
        }
    }
}

function Assert-ManifestVersion
{
    param(
        [Parameter(Mandatory=$true)]
        [object]
        $TaskContext,

        [String]
        $manifestPath = (Join-Path -Path $TestDrive.FullName -ChildPath 'MyModule\MyModule.psd1')
    )
    $versionString = "'{0}.{1}.{2}'" -f ( $TaskContext.Version.SemVer2.Major, $TaskContext.Version.SemVer2.Minor, $TaskContext.Version.SemVer2.Patch )

    $matches = Select-String $versionString $manifestPath

    It ('should have a matching Manifest Version with the Context'){
        $matches | Should Not BeNullOrEmpty
    }
}

Describe 'Invoke-WhiskeyPublishPowerShellModuleTask. when publishing new module.'{
    Initialize-Test
    $context = New-WhiskeyTestContext -ForBuildServer
    Invoke-Publish -WithoutRegisteredRepo -TaskContext $context
    Assert-ModuleRegistered -TaskContext $context
    Assert-ModulePublished -TaskContext $context
}

Describe 'Invoke-WhiskeyPublishPowerShellModuleTask. when publishing new module with default repository.'{
    Initialize-Test
    $context = New-WhiskeyTestContext -ForBuildServer
    Invoke-Publish -WithoutRegisteredRepo -WithDefaultRepo -TaskContext $context
    Assert-ModuleRegistered -TaskContext $context -WithDefaultRepo
    Assert-ModulePublished -TaskContext $context -WithDefaultRepo
}

Describe 'Invoke-WhiskeyPublishPowerShellModuleTask. when publishing previously published module.'{
    Initialize-Test
    $context = New-WhiskeyTestContext -ForBuildServer
    Invoke-Publish -TaskContext $context
    Assert-ModulePublished -TaskContext $context
}

Describe 'Invoke-WhiskeyPublishPowerShellModuleTask. when run by developer, not publishing.' {
    $context = New-WhiskeyTestContext -ForDeveloper
    Invoke-Publish -TaskContext $context
    Assert-ModuleNotPublished
}

Describe 'Invoke-WhiskeyPublishPowerShellModuleTask. when publishing new module with custom repository name.'{
    Initialize-Test
    $context = New-WhiskeyTestContext -ForBuildServer
    $repository = 'fubarepo'
    Invoke-Publish -WithoutRegisteredRepo -ForRepositoryName $repository -TaskContext $context
    Assert-ModuleRegistered -TaskContext $context -ExpectedRepositoryName $repository
    Assert-ModulePublished -TaskContext $context -ExpectedRepositoryName $repository
}

Describe 'Invoke-WhiskeyPublishPowerShellModuleTask. when publishing new module with custom feed name.'{
    Initialize-Test
    $context = New-WhiskeyTestContext -ForBuildServer
    $feed = 'snafeed'
    Invoke-Publish -WithoutRegisteredRepo -ForFeedName $feed -TaskContext $context
    Assert-ModuleRegistered -TaskContext $context -ExpectedFeedName $feed 
    Assert-ModulePublished -TaskContext $context 
}

Describe 'Invoke-WhiskeyPublishPowerShellModuleTask. with no ProGet URI.'{
    Initialize-Test
    $context = New-WhiskeyTestContext -ForBuildServer
    $context.ProGetSession = 'foo'
    $errorMatch = 'The property ''PowerShellFeedUri'' cannot be found on this object. Verify that the property exists.'
    
    Invoke-Publish -withoutRegisteredRepo -withNoProgetURI -TaskContext $context -ThatFailsWith $errorMatch
    Assert-ModuleNotPublished
}

Describe 'Invoke-WhiskeyPublishPowerShellModuleTask. when Path Parameter is not included' {
    Initialize-Test
    $context = New-WhiskeyTestContext -ForBuildServer
    $errorMatch = 'Element ''Path'' is mandatory'

    Invoke-Publish -WithoutPathParameter -TaskContext $context -ThatFailsWith $errorMatch
    Assert-ModuleNotPublished
}

Describe 'Invoke-WhiskeyPublishPowerShellModuleTask. with non-existent path parameter' {
    Initialize-Test
    $context = New-WhiskeyTestContext -ForBuildServer
    $errorMatch = 'does not exist'

    Invoke-Publish -WithNonExistentPath -TaskContext $context -ThatFailsWith $errorMatch
    Assert-ModuleNotPublished
}

Describe 'Invoke-WhiskeyPublishPowerShellModuleTask. with non-directory path parameter' {
    Initialize-Test
    $context = New-WhiskeyTestContext -ForBuildServer
    $errorMatch = 'must point to a directory'

    Invoke-Publish -WithInvalidPath -TaskContext $context -ThatFailsWith $errorMatch
    Assert-ModuleNotPublished
}

Describe 'Invoke-WhiskeyPublishPowerShellModuleTask. reversion manifest with custom manifestPath and authentic manifest file' {
    Initialize-Test
    $context = New-WhiskeyTestContext -ForBuildServer
    $existingManifestPath = (Join-Path -path (Split-Path $PSScriptRoot -Parent ) -ChildPath 'Whiskey\Whiskey.psd1')
    New-Item -Name 'Manifest' -Path $TestDrive.FullName -ItemType 'Directory'
    $manifestPath = (Join-Path -Path $TestDrive.FullName -ChildPath 'Manifest\manifest.psd1')
    Copy-Item $existingManifestPath $manifestPath
    
    Invoke-Publish -withoutRegisteredRepo -TaskContext $context -ForManifestPath $manifestPath
    Assert-ModuleRegistered -TaskContext $context
    Assert-ModulePublished -TaskContext $context
    Assert-ManifestVersion -TaskContext $context -manifestPath $manifestPath
}

Describe 'Invoke-WhiskeyPublishPowerShellModuleTask. reversion manifest without custom manifestPath' {
    Initialize-Test
    $context = New-WhiskeyTestContext -ForBuildServer
    Invoke-Publish -withoutRegisteredRepo -TaskContext $context
    Assert-ModuleRegistered -TaskContext $context
    Assert-ModulePublished -TaskContext $context
    Assert-ManifestVersion -TaskContext $context
}

Describe 'Invoke-WhiskeyPublishPowerShellModuleTask. with invalid manifestPath' {
    Initialize-Test
    $context = New-WhiskeyTestContext -ForBuildServer
    $manifestPath = 'fubar'
    $errorMatch = 'Module Manifest Path'

    Invoke-Publish -withoutRegisteredRepo -TaskContext $context -ForManifestPath $manifestPath -ThatFailsWith $errorMatch
    Assert-ModuleNotPublished
}

Describe 'Invoke-WhiskeyPublishPowerShellModuleTask. when publishing new module.'{
    Initialize-Test
    $context = New-WhiskeyTestContext -ForBuildServer
    Invoke-Publish -WithoutRegisteredRepo -TaskContext $context -WithCleanSwitch
    Assert-ModuleNotPublished 
}

