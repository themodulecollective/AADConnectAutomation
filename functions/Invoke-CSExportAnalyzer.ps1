function Invoke-CSExportAnalyzer
{
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [string]$BinPath  = $(Join-Path -Path $(Join-Path -Path $ENV:ProgramFiles -ChildPath 'Microsoft Azure AD Sync') -ChildPath 'Bin') # Azure AD Connect Bin Path
        ,
        [parameter(Mandatory)]
        [string]$InputXMLFilePath
        ,
        [parameter(Mandatory)]
        [string]$FilePath
    )

    $CSExportAnalyzerPath = Join-Path -Path $BinPath -ChildPath 'csexportanalyzer.exe'

    switch (Test-Path -Path $CSExportanalyzerPath -PathType Leaf)
    {
        $false
        {
            throw("CSExportAnalyzer.exe NOT Found in $BinPath")
        }
        $true
        {
            $CSExportAnalyzerArguments = @($InputXMLfilepath)

            $csvText = & $CSExportAnalyzerPath @CSExportAnalyzerArguments

            $csvText | Out-File -FilePath $FilePath
        }
    }
}