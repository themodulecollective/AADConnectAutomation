param(
    $ConnectorName #The name of the AzureAD Connector in the Azure AD Connect Sync installation
    ,
    $BinPath #The path to the bin folder for the Azure AD Sync installation (must contain the csexport.exe file)
    ,
    $OutputFolderPath #An output folder path to use for the files being created
)

$DateString = Get-Date -Format yyyyMMddHHmm
$xmlFilePath = Join-Path -Path $OutputFolderPath -ChildPath "$DateString-PendingExports.xml"
$perObjectCSVFilePath = Join-Path -Path $OutputFolderPath -ChildPath "$DateString-PerObjectPendingExports.csv"
$perAttributeCSVFilePath = Join-Path -Path $OutputFolderPath -ChildPath "$DateString-PerAttributePendingExports.csv"

Get-CSExport -ConnectorName $ConnectorName -BinPath $BinPath -ExportSet PendingExports -FilePath $xmlFilePath

#Get PerObject output
Convert-CSExportXMLToCSV -outtoCSV -sourceXMLfilepaths $xmlFilePath -targetFilePath $perObjectCSVFilePath

#Get PerAttribute output
Invoke-CSExportAnalyzer -BinPath $BinPath -inputXMLFilePath $xmlFilePath -FilePath $perAttributeCSVFilePath
