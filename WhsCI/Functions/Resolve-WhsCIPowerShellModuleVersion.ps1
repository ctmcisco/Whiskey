function Resolve-WhsCIPowerShellModuleVersion
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the PowerShell module to download.
        $ModuleName,

        [string]
        # The version of the package to download. Must be a three part number, i.e. it must have a MAJOR, MINOR, and BUILD number.
        $Version
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    if( $Version )
    {
        if( -not [Management.Automation.WildcardPattern]::ContainsWildcardCharacters($version) )
        {
            $tempVersion = [Version]$Version
            if( $TempVersion -and ($TempVersion.Build -lt 0) )
            {
                $Version = [version]('{0}.{1}.0' -f $TempVersion.Major,$TempVersion.Minor)
            }
        }
        $Version = Find-Module -Name $ModuleName -AllVersions | 
                        Where-Object { $_.Version.ToString() -like $Version } | 
                        Sort-Object -Property 'Version' -Descending | 
                        Select-Object -First 1 | 
                        Select-Object -ExpandProperty 'Version'
        if( -not $Version )
        {
            Write-Error -Message ('Failed to find module {0} version {1} on the PowerShell Gallery. Either the {0} module does not exist, or it does but version {1} does not exist. Browse the PowerShell Gallery at https://www.powershellgallery.com/' -f $ModuleName, $tempVersion)
            return
        }
    }
    else
    {
        $Version = Find-Module -Name $ModuleName | Select-Object -ExpandProperty 'Version'
        if( -not $Version )
        {
            Write-Error -Message ('Unable to find any versions of the {0} module on the PowerShell Gallery. You can browse the PowerShell Gallery at https://www.powershellgallery.com/' -f $ModuleName)
            return
        }
    }
    return $Version
}