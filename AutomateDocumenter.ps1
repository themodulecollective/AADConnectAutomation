[cmdletbinding(DefaultParameterSetName = 'ExistingConfig')]
param(
  [parameter(ParameterSetName = 'LatestConfig', Mandatory)]
  [string]$ProductionServer
  ,
  [parameter(ParameterSetName = 'LatestConfig', Mandatory)]
  [string]$StagingServer
  ,
  [parameter(ParameterSetName = 'LatestConfig')]
  [pscredential]$Credential
  ,
  [parameter(Mandatory)]
  [string]$TenantName #this can be an arbitrary value, it's just used to describe the organization configuration being documented. Use 'Contoso' and the -KeepSampleData paramter to test with the AADConnectSyncDocumenter Sample Data.
  ,
  [switch]$KeepSampleData #keeps the Contoso sample data folder
  ,
  [switch]$KeepExistingDocumenter
  ,
  [switch]$InvokeReport
)

#Get latest Azure AD Connect Sync Documenter
$latestAADCSDocumenter = $(Join-Path -Path $PSScriptRoot -ChildPath 'AADCSDocumenter.zip')
$expandDestination = $(Join-Path -Path $PSScriptRoot -ChildPath 'Documenter')
switch ($KeepExistingDocumenter)
{
  $true
  {
    if (
      $false -in @(
        Test-Path -Path $latestAADCSDocumenter -PathType Leaf
        Test-Path -Path $expandDestination -PathType Container
      ))
    {
      Throw('KeepExistingDocumenter was selected but the Documenter was not found in the expected location.')
    }
  }
  $false
  {
    try
    {
      $IWRParams = @{
        URI     = $(
          Invoke-RestMethod -uri 'https://api.github.com/repos/microsoft/AADConnectConfigDocumenter/releases/latest'
        ).assets.browser_download_url
        OutFile = $latestAADCSDocumenter
      }

      Invoke-WebRequest @IWRParams
    }
    catch
    {
      $MyError = $_
      Write-Error -Message $MyError.tostring()
      Throw('Failed to download or save the latest version of the AADConnectConfig Documenter.  Check write permissions to script location and connectivity to github.com and try again.')
    }

    #Expand the archive file
    try
    {
      Unblock-File -Path $latestAADCSDocumenter
      Expand-Archive -Path $latestAADCSDocumenter -DestinationPath $expandDestination
    }
    catch
    {
      $MyError = $_
      Write-Error -Message $MyError.tostring()
      Throw('Failed to unblock or expand the latest version of the AADConnectConfig Documenter. Check write permissions to the script location and try again.')
    }
  }
}

#Set the path to the Data folder
$DataPath = Join-Path -Path $expandDestination -ChildPath 'Data'

#Remove Sample Data from Documenter Data Folder
if ($true -ne $KeepSampleData)
{
  $ContosoDataPath = Join-Path -Path $DataPath -ChildPath 'Contoso'
  Remove-Item -Path $ContosoDataPath -Recurse -Force
}

# Get or Validate the configurations to report
$ConfigDestination = Join-Path -Path $DataPath -ChildPath $TenantName
$productionDestination = Join-Path -Path $ConfigDestination -ChildPath 'Production'
$stagingDestination = Join-Path -Path $ConfigDestination -ChildPath 'Staging'
switch ($PSCmdlet.ParameterSetName)
{
  'LatestConfig'
  {
    if (-not (Test-Path -Path $ConfigDestination -PathType Container))
    {
      New-Item -Path $ConfigDestination -ItemType Directory
    }
    $sessionParams = @{ }
    if ($PSBoundParameters.ContainsKey('Credential'))
    { $sessionParams.Credential = $Credential }
    $ProductionSession = New-PSSession -ComputerName $ProductionServer -Name 'ProductionAADConnectSession' @sessionParams
    $StagingSession = New-PSSession -ComputerName $StagingServer -Name 'StagingAADConnectSession' @sessionParams
    $Sessions = @(
      $ProductionSession
      $StagingSession
    )
    $timeStamp = Get-Date -Format yyyyMMddmmss
    $StagingConfigFolderName = 'Staging' + $timeStamp
    $ProductionConfigFolderName = 'Production' + $timeStamp

    Invoke-Command -Session $Sessions -ScriptBlock { Import-Module ADSync }

    Invoke-Command -Session $StagingSession -ScriptBlock { $configFolder = $(Join-Path -Path $([system.environment]::GetEnvironmentVariable('temp')) -ChildPath $using:StagingConfigFolderName) }
    Invoke-Command -Session $ProductionSession -ScriptBlock { $configFolder = $(Join-Path -Path $([system.environment]::GetEnvironmentVariable('temp')) -ChildPath $using:ProductionConfigFolderName) }
    Invoke-Command -Session $Sessions -ScriptBlock { New-Item -Path $configFolder -ItemType Directory }
    Invoke-Command -Session $Sessions -ScriptBlock { Get-ADSyncServerConfiguration -Path $configFolder }

    #Get the config files from Production
    $productionConfigPath = Invoke-Command -Session $ProductionSession -ScriptBlock { $configFolder }
    Copy-Item -FromSession $ProductionSession -Path $productionConfigPath -Destination $productionDestination -Recurse
    #Get the config files from Staging
    $stagingConfigPath = Invoke-Command -Session $StagingSession -ScriptBlock { $configFolder }
    Copy-Item -FromSession $StagingSession -Path $stagingConfigPath -Destination $stagingDestination -Recurse
  }
  'ExistingConfig'
  {
    if (
      $false -in @(
        Test-Path -Path $ConfigDestination -PathType Container
        Test-Path -Path $productionDestination -PathType Container
        Test-Path -Path $stagingDestination -PathType Container
      )
    )
    {
      throw("Expected Configuration data not found in $ConfigDestination")
    }
  }
}

#Run the documenter
Push-Location #preserve the current path location to return to it

Set-Location -Path $expandDestination

[scriptblock]$StringToInvoke = { $null = .\AzureADConnectSyncDocumenterCmd.exe `"$TenantName\Staging`" `"$TenantName\Production`" }

& $StringToInvoke

Pop-Location #return the path to the original current location

#Verify Report
$reportFolderPath = Join-Path -Path $expandDestination -ChildPath 'Report'
$reportHtmlPath = Join-Path -Path $reportFolderPath -ChildPath '*.html'
if (
  $false -in @(
    Test-Path -Path $reportFolderPath -PathType Container
    Test-Path -Path $reportHtmlPath -PathType Leaf
  ))
{
  throw("Expected Report folder and HTML file not found.  Check AADConnectSyncDocumenter-Error.log in $expandDestination")
}
else
{
  if ($true -eq $InvokeReport)
  {
    Invoke-Item -Path $reportHtmlPath
  }
  else
  {
    Write-Information -MessageData "Report HTML File is available in $ReportFolderPath"
  }
}