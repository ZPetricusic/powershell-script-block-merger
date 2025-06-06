$Path = Read-Host "Enter the path to the Powershell EVTX file"

# remove any problematic quotes
$Path = $Path.Replace('"', '')
$Path = $Path.Replace("'", '')

if (-NOT $(Test-Path $Path)) {
    Write-Host -BackgroundColor Red -ForegroundColor White "[!] Filepath `"$_`" does not exist! Exiting..."
    Exit
}

Write-Host -ForegroundColor Cyan "[*] Getting all unique Script Block IDs..."
$allScriptBlockIds = Get-WinEvent -FilterHashtable @{ 
    Path="$Path"; 
    ProviderName="Microsoft-Windows-PowerShell"; 
    Id = 4104 
} | % { $_.Properties[3].Value } | Get-Unique

Write-Host -BackgroundColor Red -ForegroundColor White "[!] This script will overwrite any existing files in this directory!"

do {
    $key = Read-Host "[?] Are you sure you want to continue? (y/n)"
    if ($key -eq "n") {
        Write-Host "[*] Exiting..."
        Exit
    }
} while ($key -ne "n" -and $key -ne "y")

Write-Host -ForegroundColor Cyan "[*] Parsing ScriptBlocks..."
$allScriptBlockIds | % {
	$currentId = $_
    $filename = "$currentId.ps1"
	Write-Host "Generating file: $filename"
	
    $StoreArrayHere = Get-WinEvent -FilterHashtable @{ 
        Path="$Path";
        ProviderName="Microsoft-Windows-PowerShell";
        Id = 4104
    } | Where-Object { $_.Properties[3].Value -like "*$currentId*" }

	$SortIt = $StoreArrayHere | sort { $_.Properties[0].Value }
    try {
	    $MergedScript = -join ($SortIt | % { $_.Properties[2].Value }) | Out-File -Force $filename -ErrorAction Stop
    } catch {
        Write-Host -ForegroundColor Red "[!] Failed to parse script block $currentId! Error:"
        Write-Host -ForegroundColor Red "$_"
    }
}