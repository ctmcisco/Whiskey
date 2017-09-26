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
    ModuleVersion = '0.19.0'

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
* The `Node` task no longer runs `npm prune`.
* The `PublishNodeModule` task now runs `npm prune --production` before publishing the node module.
* You can now specify a custom version of NUnit that the `NUnit2` and `NUnit3` tasks should use by setting the `Version` property to the version you want to use.
* The `PublishBuildMasterPackage` task now supports:
  * customizing package names with the `PackageName` property. The default value will continue to be the major, minor, and patch portions of the version number, e.g. `6.4.34`.
  * skipping/preventing a package from deploying with the `SkipDeploy` property. Set it to `true` and a package will be created in BuildMaster, but not deployed anywhere.
  * starting a deploy at a specific stage of a release's pipeline. Set the `StartAtStage` property to the name of the stage you want the deploy to start at. In order for a deploy to start at any stage in a pipeline, the "Enforce pipeline stage order for deployments" setting must be off. This can be set in the BuildMaster UI in the pipeline's Edit panel.
* The `Pester4` task can now show a "Describe Duration Report" and an "It Duration Report". These reports show the duration of each Describe and It block that were run, respectively, from longest to shortest. The task has two new properties that control the number of rows to show (i.e. they control how many of your longest Describe and It blocks to show). Use the `DescribeDurationReportCount` property to control how many of your longest-running Describe blocks to show. Use the `ItDurationReport` property to control how many of your longest-running It blocks to show.
* Fixed: Pester module was always downloaded by the `Pester3` and `Pester4` tasks even if it was already installed.
* Created a `Delete` task for deleting files and directories.
* Created a `GetPowerShellModule` task for downloading PowerShell modules needed during a build.

Whether or not a task runs can now be filtered by the branch being built. Every task now has `OnlyOnBranch` and `ExceptOnBranch` properties. Each property is a list of branch names that controls what branches a task does or doesn't run on. Wildcards patterns are supported. If you use `OnlyOnBranch`, that task will only run if the current branch matches one of the branch names. If you use `ExceptOnBranch`, that task will only run if the current branch doesn't match one of the branch names.

    PublishTasks:
    - PublishBuildMasterPackage:
        OnlyOnBranch: master
        ReleaseName: 6.4
        ApplicationName: Whiskey
    - PublishBuildMasterPackage:
        ExceptOnBranch: master
        ReleaseName: 6.5
        ApplicationName: Whiskey

The above example shows how you would publish different branches to different releases in BuildMaster. The master branch is packaged and deployed to the `6.4` release. All other branches are packaged and deployed to the `6.5` release.
'@
        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    # HelpInfoURI = ''

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''
}
