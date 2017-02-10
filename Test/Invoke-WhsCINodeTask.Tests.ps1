
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-WhsCITest.ps1' -Resolve)

$originalNodeEnv = $env:NODE_ENV
$startedWithNodeEnv = (Test-Path -Path 'env:NODE_ENV')

$defaultPackageName = 'fubarsnafu'

function Assert-SuccessfulBuild
{
    param(
        $ThatRanIn,
        [string[]]
        $ThatRan = @( 'build', 'test' ),
        [string]
        $ForVersion = '4.4.7',
        [Switch]
        $ByDeveloper,
        [Switch]
        $ByBuildServer
    )

    if( -not $ByDeveloper -and -not $ByBuildServer )
    {
        throw ('You must provide either the ByDeveloper or ByBuildServer switch when calling Assert-SuccessfulBuild.')
    }

    foreach( $taskName in $ThatRan )
    {
        It ('should run the {0} task' -f $taskName) {
            (Join-Path -Path $ThatRanIn -ChildPath $taskName) | Should Exist
        }
    }

    $versionRoot = Join-Path -Path $env:APPDATA -ChildPath ('nvm\v{0}' -f $ForVersion)
    It ('should prepend path to Node version to path environment variable') {
        Assert-MockCalled -CommandName 'Set-Item' -ModuleName 'WhsCI' -Times 1 -ParameterFilter {
            $Path -eq 'env:Path' -and $Value -like ('{0};*' -f $versionRoot)
        }
    }

    It ('should remove Node version path from path environment variable') {
        Assert-MockCalled -CommandName 'Set-Item' -ModuleName 'WhsCI' -Times 1 -ParameterFilter {
            $Path -eq 'env:Path' -and $Value -notlike ('*{0}*' -f $versionRoot)
        }
    }

    $outputRoot = Get-WhsCIOutputDirectory -WorkingDirectory $ThatRanIn
    $licensePath = Join-Path -Path $outputRoot -ChildPath ('node-license-checker-report.json' -f $defaultPackageName)

    Context 'the licenses report' {
        It 'should exist' {
            $licensePath | Should Exist
        }

        $json = Get-Content -Raw -Path $licensePath | ConvertFrom-Json
        It 'should be parsable JSON' {
            $json | Should Not BeNullOrEmpty
        }

        It 'should be transformed from license-checker''s format' {
            $json | Select-Object -ExpandProperty 'name' | Should Not BeNullOrEmpty
            $json | Select-Object -ExpandProperty 'licenses' | Should Not BeNullOrEmpty
        }
    }

    $devDependencyPaths = Join-Path -Path $ThatRanIn -ChildPath 'package.json' | 
                            ForEach-Object { Get-Content -Raw -Path $_ } | 
                            ConvertFrom-Json |
                            Select-Object -ExpandProperty 'devDependencies' |
                            Get-Member -MemberType NoteProperty |
                            Select-Object -ExpandProperty 'Name' |
                            ForEach-Object { Join-Path -Path $ThatRanIn -ChildPath ('node_modules\{0}' -f $_)  }
    if( $ByBuildServer )
    {
        It 'should prune dev dependencies' {
            $devDependencyPaths | Should Not Exist
        }
    }
    
    if( $ByDeveloper )
    {
        It 'should not prune dev dependencies' {
            $devDependencyPaths | Should Exist
        }
    }
}

function Initialize-NodeProject
{
    param(
        [string[]]
        $DevDependency,

        [string[]]
        $Dependency,

        [switch]
        $WithNoNodeEngine,

        [string]
        $UsingNodeVersion = '^4.4.7',

        [Switch]
        $WithNoName,

        [Switch]
        $ByDeveloper,

        [Switch]
        $ByBuildServer
    )

    if( $ByDeveloper )
    {
        Mock -CommandName 'Test-Path' -ModuleName 'WhsCI' -MockWith { return $true } -ParameterFilter { $Path -eq 'env:NVM_HOME' }
        Mock -CommandName 'Get-Item' -ModuleName 'WhsCI' -MockWith { [pscustomobject]@{ Value = (Join-Path -Path $env:APPDATA -ChildPath 'nvm') } } -ParameterFilter { $Path -eq 'env:NVM_HOME' }
        $mock = { return $false }
        Set-Item -Path 'env:NODE_ENV' -Value 'developer'
    }
    else
    {
        $mock = { return $true }
        Mock -CommandName 'Test-Path' -ModuleName 'WhsCI' -MockWith { return $false } -ParameterFilter { $Path -eq 'env:HOME' }
        Set-Item -Path 'env:NODE_ENV' -Value 'production'
    }

    Mock -CommandName 'Test-WhsCIRunByBuildServer' -ModuleName 'WhsCI' -MockWith $mock

    $empty = Join-Path -Path $env:Temp -ChildPath ([IO.Path]::GetRandomFileName())
    New-Item -Path $empty -ItemType 'Directory' | Out-Null
    $workingDir = Join-Path -Path $env:Temp -ChildPath 'z'
    try
    {
        while( (Test-Path -Path $workingDir -PathType Container) )
        {
            Write-Verbose -Message 'Removing working directory...'
            Start-Sleep -Milliseconds 100
            robocopy $empty $workingDir /MIR | Write-Verbose
            Remove-Item -Path $workingDir -Recurse -Force
        }
    }
    finally
    {
        Remove-Item -Path $empty -Recurse
    }
    New-Item -Path $workingDir -ItemType 'Directory' | Out-Null

    Mock -CommandName 'Set-Item' -ModuleName 'WhsCI' -Verifiable

    if( -not $DevDependency )
    {
        $DevDependency = @(
                            '"jit-grunt": "^0.10.0"',
                            '"grunt": "^1.0.1"',
                            '"grunt-cli": "^1.2.0"'
                          )
    }

    $nodeEngine = @"
    "engines": {
        "node": "$($UsingNodeVersion)"
    },
"@
    if( $WithNoNodeEngine )
    {
        $nodeEngine = ''
    }
    $packageJsonPath = Join-Path -Path $workingDir -ChildPath 'package.json'
    $name = '"name": "{0}",' -f $defaultPackageName
    if( $WithNoName )
    {
        $name = ''
    }

    @"
{
    $($name)
    $($nodeEngine)
    "private": true,
    "scripts": {
        "build": "grunt build",
        "test": "grunt test",
        "fail": "grunt fail"
    },

    "dependencies": {
        $( $Dependency -join ',' )
    },

    "devDependencies": {
        $( $DevDependency -join "," )
    }
}
"@ | Set-Content -Path $packageJsonPath

    $gruntfilePath = Join-Path -Path $workingDir -ChildPath 'Gruntfile.js'
    @'
'use strict';
module.exports = function(grunt) {
    require('jit-grunt')(grunt);

    grunt.registerTask('build', '', function(){
        grunt.file.write('build', '');
    });

    grunt.registerTask('test', '', function(){
        grunt.file.write('test', '');
    });

    grunt.registerTask('fail', '', function(){
        grunt.fail.fatal('I failed!');
    });
}
'@ | Set-Content -Path $gruntfilePath

    return $workingDir
}

function Invoke-FailingBuild
{
    [CmdletBinding()]
    param(
        [string]
        $InDirectory,

        [string]
        $ThatFailsWithMessage,

        [string[]]
        $NpmScript = @( 'fail', 'build', 'test' ),

        [Switch]
        $WhoseScriptsPass
    )

    $failed = $false
    $failure = $null
    try
    {
        Invoke-WhsCINodeTask -WorkingDirectory $InDirectory -NpmScript $NpmScript
    }
    catch
    {
        $failed = $true
        $failure = $_
        Write-Error -ErrorRecord $_
    }

    It 'should throw an exception' {
        $failed | Should Be $True
        $failure | Should Not BeNullOrEmpty
        $failure | Should Match $ThatFailsWithMessage
    }

    foreach( $script in $NpmScript )
    {
        if( $WhoseScriptsPass )
        {
            It ('should run ''{0}'' NPM script' -f $script) {
                Join-Path -Path $InDirectory -ChildPath $script | Should Exist
            }
        }
        else
        {
            It ('should not run ''{0}'' NPM script' -f $script) {
                Join-Path -Path $InDirectory -ChildPath $script | Should Not Exist
            }
        }
    }
}

Describe 'Invoke-WhsCINodeTask.when run by a developer' {
    $workingDir = Initialize-NodeProject -ByDeveloper
    Invoke-WhsCINodeTask -WorkingDirectory $workingDir -NpmScript 'build','test'
    Assert-SuccessfulBuild -ThatRanIn $workingDir -ByDeveloper
}

Describe 'Invoke-WhsCINodeTask.when run by build server' {
    $workingDir = Initialize-NodeProject -ByBuildServer
    Invoke-WhsCINodeTask -WorkingDirectory $workingDir -NpmScript 'build','test'
    Assert-SuccessfulBuild -ThatRanIn $workingDir -ByBuildServer
}

Describe 'Invoke-WhsCINodeTask.when a build task fails' {
    $workingDir = Initialize-NodeProject
    Invoke-FailingBuild -InDirectory $workingDir -ThatFailsWithMessage 'npm\ run\b.*\bfailed' -ErrorAction SilentlyContinue
}

Describe 'Invoke-WhsCINodeTask.when a install fails' {
    $workingDir = Initialize-NodeProject -DevDependency '"whs-idonotexist": "^1.0.0"'
    Invoke-FailingBuild -InDirectory $workingDir -ThatFailsWithMessage 'npm\ install\b.*failed' -ErrorAction SilentlyContinue
}

Describe 'Invoke-WhsCINodeTask.when NODE_ENV is set to production' {
    $env:NODE_ENV = 'production'
    $workingDir = Initialize-NodeProject -ByBuildServer
    Invoke-WhsCINodeTask -WorkingDirectory $workingDir -NpmScript 'build','test'
    Assert-SuccessfulBuild -ThatRanIn $workingDir -ByBuildServer
}

Describe 'Invoke-WhsCINodeTask.when node engine is missing' {
    $workingDir = Initialize-NodeProject -WithNoNodeEngine
    Invoke-FailingBuild -InDirectory $workingDir -ThatFailsWithMessage 'Node version is not defined or is missing' -NpmScript @( 'build' ) -ErrorAction SilentlyContinue
}

Describe 'Invoke-WhsCINodeTask.when node version is invalid' {
    $workingDir = Initialize-NodeProject -UsingNodeVersion "fubarsnafu"
    Invoke-FailingBuild -InDirectory $workingDir -ThatFailsWithMessage 'Node version ''fubarsnafu'' is invalid' -NpmScript @( 'build' ) -ErrorAction SilentlyContinue
}

Describe 'Invoke-WhsCINodeTask.when node version does not exist' {
    $workingDir = Initialize-NodeProject -UsingNodeVersion "438.4393.329"
    Invoke-FailingBuild -InDirectory $workingDir -ThatFailsWithMessage 'version ''.*'' failed to install' -NpmScript @( 'build' ) -ErrorAction SilentlyContinue
}

Describe 'Invoke-WhsCINodeTask.when module has security vulnerability' {
    $workingDir = Initialize-NodeProject -Dependency @( '"minimatch": "3.0.0"' )
    Invoke-FailingBuild -InDirectory $workingDir -ThatFailsWithMessage 'found the following security vulnerabilities' -NpmScript @( 'build' ) -WhoseScriptsPass -ErrorAction SilentlyContinue
}

Describe 'Invoke-WhsCINodeTask.when package.json has no name' {
    $workingDir = Initialize-NodeProject -WithNoName
    Invoke-FailingBuild -InDirectory $workingDir -ThatFailsWithMessage 'name is missing or doesn''t have a value' -NpmScript @( 'build' )  -ErrorAction SilentlyContinue
}

if( $startedWithNodeEnv )
{
    $env:NODE_ENV = $originalNodeEnv
}
elseif( (Test-Path -Path 'env:NODE_ENV') )
{
    Remove-Item -Path 'env:NODE_ENV'
}