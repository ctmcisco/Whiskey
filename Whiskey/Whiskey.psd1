#
# Module manifest for module 'Whiskey'
#
# Generated by: ajensen
#
# Generated on: 12/8/2016
#

@{

    # Script module or binary module file associated with this manifest.
    RootModule = 'Whiskey.psm1'

    # Version number of this module.
    ModuleVersion = '0.35.0'

    # ID used to uniquely identify this module
    GUID = '93bd40f1-dee5-45f7-ba98-cb38b7f5b897'

    # Author of this module
    Author = 'WebMD Health Services'

    # Company or vendor of this module
    CompanyName = 'WebMD Health Services'

    # Copyright statement for this module
    Copyright = '(c) 2016 WebMD Health Services. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'Continuous Integration/Continuous Delivery module.'

    # Minimum version of the Windows PowerShell engine required by this module
    # PowerShellVersion = ''

    # Name of the Windows PowerShell host required by this module
    # PowerShellHostName = ''

    # Minimum version of the Windows PowerShell host required by this module
    # PowerShellHostVersion = ''

    # Minimum version of Microsoft .NET Framework required by this module
    # DotNetFrameworkVersion = ''

    # Minimum version of the common language runtime (CLR) required by this module
    # CLRVersion = ''

    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''

    # Modules that must be imported into the global environment prior to importing this module
    # RequiredModules = @()

    # Assemblies that must be loaded prior to importing this module
    RequiredAssemblies = @( 'bin\SemanticVersion.dll', 'bin\Whiskey.dll', 'bin\YamlDotNet.dll' )

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    #ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    FormatsToProcess = @(
                            'Formats\System.Exception.format.ps1xml',
                            'Formats\Whiskey.BuildInfo.format.ps1xml',
                            'Formats\Whiskey.BuildVersion.format.ps1xml',
                            'Formats\Whiskey.Context.format.ps1xml'
                        )

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    NestedModules = @(
                        'BitbucketServerAutomation',
                        'BuildMasterAutomation',
                        'ProGetAutomation',
                        'VSSetup'
                     )

    # Functions to export from this module
    FunctionsToExport = @(
                            'Add-WhiskeyApiKey',
                            'Add-WhiskeyCredential',
                            'Add-WhiskeyTaskDefault',
                            'Add-WhiskeyVariable',
                            'Assert-WhiskeyNodePath',
                            'Assert-WhiskeyNodeModulePath',
                            'ConvertFrom-WhiskeyYamlScalar',
                            'ConvertTo-WhiskeySemanticVersion',
                            'Get-WhiskeyApiKey',
                            'Get-WhiskeyTask',
                            'Get-WhiskeyCredential',
                            'Install-WhiskeyTool',
                            'Invoke-WhiskeyNodeTask',
                            'Invoke-WhiskeyNpmCommand',
                            'Invoke-WhiskeyPipeline',
                            'Invoke-WhiskeyBuild',
                            'Invoke-WhiskeyTask',
                            'New-WhiskeyContext',
                            'Publish-WhiskeyBuildMasterPackage',
                            'Publish-WhiskeyNuGetPackage',
                            'Publish-WhiskeyProGetUniversalPackage',
                            'Publish-WhiskeyBBServerTag',
                            'Register-WhiskeyEvent',
                            'Resolve-WhiskeyNuGetPackageVersion',
                            'Resolve-WhiskeyPowerShellModule',
                            'Resolve-WhiskeyTaskPath',
                            'Resolve-WhiskeyVariable',
                            'Set-WhiskeyBuildStatus',
                            'Stop-WhiskeyTask',
                            'Uninstall-WhiskeyTool',
                            'Unregister-WhiskeyEvent'
                         );

    # Cmdlets to export from this module
    CmdletsToExport = @( )

    # Variables to export from this module
    #VariablesToExport = '*'

    # Aliases to export from this module
    AliasesToExport = '*'

    # DSC resources to export from this module
    # DscResourcesToExport = @()

    # List of all modules packaged with this module
    # ModuleList = @()

    # List of all files packaged with this module
    # FileList = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @( 'build', 'pipeline', 'devops', 'ci', 'cd', 'continuous-integration', 'continuous-delivery', 'continuous-deploy' )

            # A URL to the license for this module.
            LicenseUri = 'https://www.apache.org/licenses/LICENSE-2.0'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/webmd-health-services/Whiskey'

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            ReleaseNotes = @'
* Added "AllowMissingPackage" property to "PublishProGetUniversalPackage" task. Set this property to "true" to not fail a build if there are no universal packages to publish.
* Added global "IfExists" and "UnlessExists" task properties for controlling if a task runs based on the existence of an item. You can use any PowerShell-supported path, e.g. env:ENV_NAME for environment variables, hklm:\path\to\key for registry keys, and path\to\file for files/directories. Relative paths are file system paths and are resolved from the directory of the build's whiskey.yml file or the task's working directory (given by its WorkingDirecotry property). Uses PowerShell's `Test-Path` cmdlet to determine if the path exists. Wildcards are supported.
* Added `Properties` property to `NuGetPack` task so that tokens inside .nuspec files can be replaced. The `Properties` property should be a name/value mapping. Each name/value is passed to nuget.exe pack command's `-Properties` parameter.
* Added `PackageID` property to `NuGetPack` task to handle situations where a package's ID doesn't match the source .nuspec/.csproj file.
* Added `PackageVersion` property to `NuGetPack` task to allow customizing the package's version number.
* Created `SetVariableFromPowerShellDataFile` task for creating variables from values in PowerShell data files (e.g. .psd1 files, module manifests, etc.).
* Fixed: `ProGetUniversalPackage` task no longer includes robocopy output text files in your package.
* Fixed: `ProGetUniversalPackage` task was creating upack.json property keys with uppercase letters when they are required to be lowercase.
* Created `GitHubRelease` task for creating a release in GitHub. The task supports uploading files into the release.
* Created `DotNetTest` task for running `dotnet test` on .NET Core test projects.
* MSBuild task no longer includes the build configuration in the build log file.
* DotNetBuild task now writes a detailed log to the build output directory and by default shows minimal output to the console. Before, it didn't log at all and showed detailed output to the console when run by a build server.
* Created `DotNetPublish` task for running `dotnet publish` on .NET Core projects.
* Fixed: `DotNetBuild` task no longer sets the `OutputDirectory` property relative to the whiskey.yml. The property is passed as-is to the `dotnet build` command and now allows absolute paths.
'@
        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    # HelpInfoURI = ''

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''
}
