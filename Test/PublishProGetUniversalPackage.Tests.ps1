
#Requires -Version 4
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-WhiskeyTest.ps1' -Resolve)

$progetUri = $null
$credentialID = $null
$credential = $null
$feedName = $null
$path = $null
$threwException = $false
$noAccessToProGet = $null
$myTimeout = $null
$packageExists = $false
$overwrite = $false
$properties = @{ }

function GivenProperty
{
    param(
        $Name,
        $Is
    )

    $properties[$Name] = $Is
}

function GivenOverwrite
{
    $script:overwrite = $true
}

function GivenNoPath
{
    $script:path = $null
}

function GivenPackageExists
{
    $script:packageExists = $true
}

function GivenPath
{
    param(
        $Path
    )

    $script:path = $Path
}

function GivenProGetIsAt
{
    param(
        $Uri
    )

    $script:progetUri = $Uri
}

function GivenCredential
{
    param(
        [Parameter(Mandatory=$true,Position=0)]
        $Credential,

        [Parameter(Mandatory=$true)]
        $WithID
    )

    $script:noAccessToProGet = $false
    $password = ConvertTo-SecureString -AsPlainText -Force -String $Credential
    $script:credential = New-Object 'Management.Automation.PsCredential' $Credential,$password
    $script:credentialID = $WithID
}

function GivenNoAccessToProGet
{
    $script:noAccessToProGet = $true
}

function GivenNoParameters
{
    $script:credentialID = $null
    $script:feedName = $null
    $script:path = $null
    $script:progetUri = $null
    $script:credential = $null
}

function GivenTimeout
{
    param(
        $Timeout
    )

    $script:myTimeout = $Timeout
}

function GivenUniversalFeed
{
    param(
        $Named
    )

    $script:feedName = $Named
}

function GivenUpackFile
{
    param(
        $Name
    )

    New-Item -Path (Join-Path -Path $TestDrive.FullName -ChildPath ('.output\{0}' -f $Name)) -Force -ItemType 'File'
}

function Init
{
    $script:myTimeout = $null
    $script:packageExists = $false
    $script:properties = @{ }
    Remove-Module -Name 'ProGetAutomation' -Force -ErrorAction Ignore
}

function ThenPackageOverwritten
{
    It ('should overwrite existing package') {
        Assert-MockCalled -CommandName 'Publish-ProGetUniversalPackage' `
                          -ModuleName 'Whiskey' `
                          -ParameterFilter { 
                                #$DebugPreference = 'continue'
                                Write-Debug -Message ('Force  expected  true')
                                Write-Debug -Message ('       actual    false' -f $Force)
                                $Force.ToBool()
                            }
    }
}

function ThenPackageNotPublished
{
    param(
        $FileName
    )

    It ('should not publish file ''.output\{0}''' -f $FileName) {
        Assert-MockCalled -CommandName 'Publish-ProGetUniversalPackage' -ModuleName 'Whiskey' -ParameterFilter { $PackagePath -eq (Join-Path -Path $TestDrive.FullName -ChildPath ('.output\{0}' -f $FileName)) } -Times 0
    }
}

function ThenPackagePublished
{
    param(
        $FileName
    )

    It ('should publish file ''.output\{0}''' -f $FileName) {
        Assert-MockCalled -CommandName 'Publish-ProGetUniversalPackage' -ModuleName 'Whiskey' -ParameterFilter { $PackagePath -eq (Join-Path -Path $TestDrive.FullName -ChildPath ('.output\{0}' -f $FileName)) }
    }

    It ('should not throw any errors') {
        $Global:Error | Should -BeNullOrEmpty
    }
}

function ThenPackagePublishedAs
{
    param(
        $Credential
    )

    It ('should publish as ''{0}''' -f $Credential) {
        Assert-MockCalled -CommandName 'Publish-ProGetUniversalPackage' -ModuleName 'Whiskey' -ParameterFilter { $Session.Credential.UserName -eq $Credential }
        Assert-MockCalled -CommandName 'Publish-ProGetUniversalPackage' -ModuleName 'Whiskey' -ParameterFilter { $Session.Credential.GetNetworkCredential().Password -eq $Credential }
    }
}

function ThenPackagePublishedAt
{
    param(
        $Uri
    )

    It ('should publish to ''{0}''' -f $Uri) {
        Assert-MockCalled -CommandName 'Publish-ProGetUniversalPackage' -ModuleName 'Whiskey' -ParameterFilter {
            #$DebugPreference = 'Continue'
            Write-Debug -Message ('Uri  expected  {0}' -f $Uri)
            Write-Debug -Message ('     actual    {0}' -f $Session.Uri)
            $session | Format-List | Out-String | Write-Debug
            $Session.Uri -eq $Uri
        }
    }
}

function ThenPackagePublishedToFeed
{
    param(
        $Named
    )

    It ('should publish to feed ''{0}''' -f $Named) {
        Assert-MockCalled -CommandName 'Publish-ProGetUniversalPackage' -ModuleName 'Whiskey' -ParameterFilter { $FeedName -eq $Named }
    }
}

function ThenPackagePublishedWithTimeout
{
    param(
        $ExpectedTimeout
    )

    It ('should publish with timeout ''{0}'' seconds' -f $ExpectedTimeout) {
        Assert-MockCalled -CommandName 'Publish-ProGetUniversalPackage' -ModuleName 'Whiskey' -ParameterFilter {
            #$DebugPreference = 'Continue'
            Write-Debug -Message ('Timeout  expected  {0}' -f $Timeout)
            Write-Debug -Message ('         actual    {0}' -f $ExpectedTimeout)
            $Timeout -eq $ExpectedTimeout 
        }
    }
}

function ThenPackagePublishedWithDefaultTimeout
{
    param(
    )

    It ('should publish to feed with default timeout') {
        Assert-MockCalled -CommandName 'Publish-ProGetUniversalPackage' -ModuleName 'Whiskey' -ParameterFilter { $Timeout -eq $null }
    }
}

function ThenTaskCompleted
{
    param(
    )

    It ('the task should not throw an exception') {
        $threwException | Should -Be $false
    }

    It ('the task should not write an error') {
        $Global:Error | Should -BeNullOrEmpty
    }
}

function ThenTaskFailed
{
    param(
        $Pattern
    )

    It ('the task should throw an exception') {
        $threwException | Should -Be $true
    }

    It ('the exception should match /{0}/' -f $Pattern) {
        $Global:Error | Should -Match $Pattern
    }
}

function WhenPublishingPackage
{
    [CmdletBinding()]
    param(
        $Excluding
    )

    $context = New-WhiskeyTestContext -ForTaskName 'PublishProGetUniversalPackage' -ForBuildServer -IgnoreExistingOutputDirectory -IncludePSModules

    if( $credentialID )
    {
        $properties['CredentialID'] = $credentialID
        if( $credential )
        {
            Add-WhiskeyCredential -Context $context -ID $credentialID -Credential $credential
        }
    }

    if( $progetUri )
    {
        $properties['Uri'] = $progetUri
    }

    if( $feedName )
    {
        $properties['FeedName'] = $feedName
    }

    if( $path )
    {
        $properties['Path'] = $path
    }

    if( $myTimeout )
    {
        $properties['Timeout'] = $myTimeout
    }

    if( $overwrite )
    {
        # String to ensure parsed to a boolean.
        $properties['Overwrite'] = 'true'
    }

    if( $Excluding )
    {
        $properties['Exclude'] = $Excluding
    }

    $mock = { }
    if( $noAccessToProGet )
    {
        $mock = { Write-Error -Message 'Failed to upload package to some uri.' }
    }
    elseif( $packageExists )
    {
        $mock = { if( -not $Force ) { Write-Error -Message ('Package already exists!') } }
    }

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\PSModules\ProGetAutomation' -Resolve)
    Mock -CommandName 'Publish-ProGetUniversalPackage' -ModuleName 'Whiskey' -MockWith $mock

    $script:threwException = $false
    try
    {
        $Global:Error.Clear()
        Invoke-WhiskeyTask -TaskContext $context -Parameter $properties -Name 'PublishProGetUniversalPackage'
    }
    catch
    {
        $script:threwException = $true
        Write-Error -ErrorRecord $_
    }
}

Describe 'PublishProGetUniversalPackage.when user publishes default files' {
    Init
    GivenUpackFile 'myfile1.upack'
    GivenUpackFile 'myfile2.upack'
    GivenProGetIsAt 'my uri'
    GivenCredential 'fubar' -WithID 'progetid'
    GivenUniversalFeed 'universalfeed'
    WhenPublishingPackage
    ThenPackagePublished 'myfile1.upack'
    ThenPackagePublished 'myfile2.upack'
    ThenPackagePublishedAt 'my uri'
    ThenPackagePublishedToFeed 'universalfeed'
    ThenPackagePublishedAs 'fubar'
    ThenPackagePublishedWithDefaultTimeout
}

Describe 'PublishProGetUniversalPackage.when user excludes files' {
    Init
    GivenUpackFile 'myfile1.upack'
    GivenUpackFile 'myfile2.upack'
    GivenProGetIsAt 'my uri'
    GivenCredential 'fubar' -WithID 'progetid'
    GivenUniversalFeed 'universalfeed'
    WhenPublishingPackage -Excluding '*2.upack'
    ThenPackagePublished 'myfile1.upack'
    ThenPackageNotPublished 'myfile2.upack'
}

Describe 'PublishProGetUniversalPackage.when user specifies files to publish' {
    Init
    GivenUpackFile 'myfile1.upack'
    GivenUpackFile 'myfile2.upack'
    GivenProGetIsAt 'my uri'
    GivenCredential 'fubar' -WithID 'progetid'
    GivenUniversalFeed 'universalfeed'
    GivenPath '.output\myfile1.upack'
    WhenPublishingPackage
    ThenPackagePublished 'myfile1.upack'
    ThenPackageNotPublished 'myfile2.upack'
}

Describe 'PublishProGetUniversalPackage.when user specifies files to publish and excluding some' {
    Init
    GivenUpackFile 'myfile1.upack'
    GivenUpackFile 'myfile2.upack'
    GivenProGetIsAt 'my uri'
    GivenCredential 'fubar' -WithID 'progetid'
    GivenUniversalFeed 'universalfeed'
    GivenPath '.output\*.upack'
    WhenPublishingPackage -Excluding '*1.upack'
    ThenPackageNotPublished 'myfile1.upack'
    ThenPackagePublished 'myfile2.upack'
}

Describe 'PublishProGetUniversalPackage.when CredentialID property is missing' {
    Init
    GivenNoParameters
    WhenPublishingPackage -ErrorAction SilentlyContinue
    ThenTaskFailed '\bCredentialID\b.*\bis\ a\ mandatory\b'
}

Describe 'PublishProGetUniversalPackage.when Uri property is missing' {
    Init
    GivenNoParameters
    GivenCredential 'somecredential' -WithID 'fubar'
    WhenPublishingPackage -ErrorAction SilentlyContinue
    ThenTaskFailed '\bUri\b.*\bis\ a\ mandatory\b'
}

Describe 'PublishProGetUniversalPackage.when FeedName property is missing' {
    Init
    GivenNoParameters
    GivenCredential 'somecredential' -WithID 'fubar'
    GivenProGetIsAt 'some uri'
    WhenPublishingPackage -ErrorAction SilentlyContinue
    ThenTaskFailed '\bFeedName\b.*\bis\ a\ mandatory\b'
}

Describe 'PublishProGetUniversalPackage.when there are no upack files' {
    Init
    GivenProGetIsAt 'my uri'
    GivenCredential 'fubatr' -WithID 'id'
    GivenUniversalFeed 'universal'
    WhenPublishingPackage -ErrorAction SilentlyContinue
    ThenTaskFailed ([regex]::Escape('.output\*.upack" does not exist'))
}

Describe 'PublishProGetUniversalPackage.when there are no upack files in the output directory and the user says that''s OK' {
    Init
    GivenProGetIsAt 'my uri'
    GivenCredential 'fubatr' -WithID 'id'
    GivenUniversalFeed 'universal'
    GivenProperty 'AllowMissingPackage' -Is 'true'
    WhenPublishingPackage
    ThenTaskCompleted
    ThenPackageNotPublished
}

Describe 'PublishProGetUniversalPackage.when Path doesn''t resolve to any upack files and the user says that''s OK' {
    Init
    GivenProGetIsAt 'my uri'
    GivenCredential 'fubatr' -WithID 'id'
    GivenUniversalFeed 'universal'
    GivenProperty 'AllowMissingPackage' -Is 'true'
    GivenProperty 'Path' -Is '*.fubar'
    WhenPublishingPackage
    ThenTaskCompleted
    ThenPackageNotPublished
}

Describe 'PublishProGetUniversalPackage.when user does not have permission' {
    Init
    GivenProGetIsAt 'my uri'
    GivenUpackFile 'my.upack'
    GivenCredential 'fubatr' -WithID 'id'
    GivenNoAccessToProGet
    WhenPublishingPackage -ErrorAction SilentlyContinue
    ThenTaskFAiled 'Failed to upload'
}

Describe 'PublishProGetUniversalPackage.when uploading a large package' {
    Init
    GivenUpackFile 'myfile1.upack'
    GivenUpackFile 'myfile2.upack'
    GivenProGetIsAt 'my uri'
    GivenCredential 'fubar' -WithID 'progetid'
    GivenUniversalFeed 'universalfeed'
    GivenTimeout 600
    WhenPublishingPackage
    ThenPackagePublishedWithTimeout 600
}

Describe 'PublishProGetUniversalPackage.when package already exists' {
    Init
    GivenUpackFile 'my.upack'
    GivenProGetIsAt 'proget.example.com'
    GivenCredential 'fubar' -WithID 'progetid'
    GivenUniversalFeed 'universalfeed'
    GivenPackageExists
    WhenPublishingPackage -ErrorAction SilentlyContinue
    ThenTaskFailed
}

Describe 'PublishProGetUniversalPackage.when replacing existing package' {
    Init
    GivenUpackFile 'my.upack'
    GivenProGetIsAt 'proget.example.com'
    GivenCredential 'fubar' -WithID 'progetid'
    GivenUniversalFeed 'universalfeed'
    GivenPackageExists
    GivenOverwrite
    WhenPublishingPackage
    ThenPackagePublished 'my.upack'
    ThenPackageOverwritten
}