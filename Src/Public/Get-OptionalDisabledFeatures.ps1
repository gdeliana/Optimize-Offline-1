Function Get-OptionalDisabledFeatures {

	[CmdletBinding()]

	Param (
		[Parameter(Mandatory = $true,
			HelpMessage = 'full path to the root directory of the offline Windows image that you will service.')]
		[String]$Path,
		[Parameter(Mandatory = $false,
			HelpMessage = 'Specifies a temporary directory that will be used when extracting files for use during servicing. The directory must exist locally. If not specified, the \Windows\%Temp% directory will be used')]
		[String]$ScratchDirectory,
		[Parameter(Mandatory = $false,
			HelpMessage = 'the full path and file name to log to. If not set, the default is %WINDIR%\Logs\Dism\dism.log')]
		[String]$LogPath
	)

	return Get-WindowsOptionalFeature -Path $Path -ScratchDirectory $ScratchDirectory -LogPath $LogPath -LogLevel 1 | Select-Object -Property FeatureName, State | Sort-Object -Property FeatureName | Where-Object { $PSItem.FeatureName -notlike "SMB1Protocol*" -and $PSItem.FeatureName -ne "Windows-Defender-Default-Definitions" -and $PSItem.FeatureName -notlike "MicrosoftWindowsPowerShellV2*" -and $PSItem.State -eq "Disabled" } | ForEach-Object -Process {
		@{
			State = $_.State
			FeatureName = $_.FeatureName
			StateLabel = "Disabled"
		}
	}
}