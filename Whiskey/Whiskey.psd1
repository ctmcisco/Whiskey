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
    ModuleVersion = '0.14.0'

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
    RequiredAssemblies = @( 'bin\SemanticVersion.dll', 'bin\YamlDotNet.dll' )

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    #ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @()

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
                            'Add-WhiskeyVariable',
                            'ConvertFrom-WhiskeyYamlScalar',
                            'ConvertTo-WhiskeySemanticVersion',
                            'Get-WhiskeyApiKey',
                            'Get-WhiskeyTask',
                            'Get-WhiskeyCredential',
                            'Install-WhiskeyNodeJs',
                            'Install-WhiskeyTool',
                            'Invoke-WhiskeyNodeTask',
                            'Invoke-WhiskeyNUnit2Task',
                            'Invoke-WhiskeyPester3Task',
                            'Invoke-WhiskeyPester4Task',
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
                            'Resolve-WhiskeyPowerShellModuleVersion',
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
* The version to build can now be taken from `package.json` files (for Node.js modules/applications) and PowerShell module manifest files (e.g. `*.psd1` files). Use the new `VersionFrom` property in your `whiskey.yml` file. It should be the path to a `package.json` file or a PowerShell module manifest file. The `package.json` file must have a `version` property. The module manifest file must have a `ModuleVersion` property.
* Fixed: `PublishProGetUniversalPackage` fails when uploading large packages (i.e. the upload request times out).
* The `NuGetPush`, `NuGetPack`, and `MSBuild` tasks now supports custom versions of nuget.exe. Use the `Version` property (the `NuGetVersion` property on the `MSBuild` task) to specify what version you want to use. That version of NuGet is installed into a `packages\NuGet.CommandLine.VERSION` directory in your build root.
* Fixed: the `PublishNodeModule` task doesn't fail a build if publishing fails.
* Fixed: the `ProGetUniversalPackage` task fails if a source or destination path ends with `\`.
* Added an `Exec` task for executing custom programs. Set the `Path` property to the path to the executable. Set `Argument` to any arguments to pass to the executable. Set `SuccessExitCode` to any exit codes that signify the command succeeded.
* Fixed: The `PublishProGetUniversalPackage` task replaces existing packages.
* ***BREAKING CHANGE***: Removed the `IgnorePackageJsonVersion` whiskey.yml configuration property. If you want Whiskey to pull the version from a Node.js package file, set the `VersionFrom` whiskey.yml property to the path to your `package.json` file.
* You can now use a custom version of NPM with the `Node` and `PublishNodeModule` tasks. Set the `engines.npm` property in your package.json file (e.g. `{ "engines": { "npm": "VERSION" } }`) to the version of NPM to use. That version will be installed in your local `node_modules` directory. Optionally, if there is a version of `npm` in your local `node_modules` directory, that is used instead of the global `npm`. The global version of NPM is still used when installing your local npm and when running the `npm prune` command.
* Created "Initializaton" mode. When a build is run in this mode, tasks install and configure any tools they use and then quit. They perform no build work. This is useful so if needed, developers can get everything installed without running a complete build.
'@
        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    # HelpInfoURI = ''

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''
}
