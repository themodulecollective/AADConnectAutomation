function Get-CSExport
{
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [string]$ConnectorName
        ,
        [parameter(Mandatory)]
        [string]$BinPath  = $(Join-Path -Path $(Join-Path -Path $ENV:ProgramFiles -ChildPath 'Microsoft Azure AD Sync') -ChildPath 'Bin') # Azure AD Connect Bin Path
        ,
        [parameter(Mandatory)]
        [ValidateSet('Disconnectors','ImportErrors','ExportErrors','PendingImports','PendingExports')]
        [string]$ExportSet
        ,
        [parameter(Mandatory)]
        [string]$FilePath
    )
    $exportSetFriendlyToCode = @{
        'Disconnectors'  = 's'
        'ImportErrors'   = 'i'
        'ExportErrors'   = 'e'
        'PendingImports' = 'm'
        'PendingExports' = 'x'
    }

    $exportIndicator = $ExportSetFriendlyToCode.$ExportSet

    $CSExportPath = Join-Path -Path $BinPath -ChildPath 'csexport.exe'

    switch (Test-Path -Path $CSExportPath -PathType Leaf)
    {
        $false
        {
            throw("CSExport.exe NOT Found in $BinPath")
        }
        $true
        {
            $CSExportArguments = @($ConnectorName,$filepath,"/f:$exportIndicator")

            $null = & $CSExportPath @CSExportArguments
        }
    }
}