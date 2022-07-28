function Invoke-AADSyncDocumenter
{
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [string]$ProductionConfig
        ,
        [parameter(Mandatory)]
        [string]$StagingConfig
        ,
        [parameter(Mandatory)]
        [string]$DocumenterPath #Path to the file AzureADConnectSyncDocumenter.exe
        ,
        [parameter(Mandatory)]
        [string]$TenantName #this can be an arbitrary value, it's just used to describe the organization configuration being documented. Use 'Contoso' and the -KeepSampleData paramter to test with the AADConnectSyncDocumenter Sample Data.
        ,
        [switch]$InvokeReport
    )

    #Get latest Azure AD Connect Sync Documenter
    $DocumenterParentPath = Split-Path -Path $DocumenterPath -Parent
    $reportFolderPath = Join-Path -Path $DocumenterParentPath -ChildPath 'Report'
    $reportHtmlPath = Join-Path -Path $reportFolderPath -ChildPath '*.html'

    switch (Test-Path -Path $DocumenterPath -PathType Leaf)
    {
        $false
        {
            throw("AzureADConnectSyncDocumenter.exe NOT Found in $DocumenterParentPath")
        }
        $true
        {
            $DocumenterArguments = @("$TenantName\$StagingConfig","$TenantName\$ProductionConfig")

            Push-Location

            Set-Location $DocumenterParentPath

            $null = & $DocumenterPath @DocumenterArguments

            Pop-Location

            if ($true -eq $InvokeReport)
            {
                Invoke-Item -Path $reportHtmlPath
            }
            else
            {
                Write-Information -MessageData "Report HTML File is available in $ReportFolderPath"
            }
        }
    }
}