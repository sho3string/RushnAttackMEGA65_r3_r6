$WorkingDirectory = Get-Location
$length = 95

	cls
	Write-Output " .-------------------------."
	Write-Output " |Building Green Beret ROMs|"
	Write-Output " '-------------------------'"

	New-Item -ItemType Directory -Path $WorkingDirectory"\arcade" -Force
	New-Item -ItemType Directory -Path $WorkingDirectory"\arcade\gberet" -Force

	Write-Output "Copying Green Beret ROMs"
	# Define the file paths within the folder
	$files = @("$WorkingDirectory\577l03.10c", "$WorkingDirectory\577l02.8c")
	# Specify the output file within the folder
	$outputFile = "$WorkingDirectory\arcade\gberet\rom1.bin"
	# Concatenate the files as binary data
	[Byte[]]$combinedBytes = @()
	foreach ($file in $files) {
		$combinedBytes += [System.IO.File]::ReadAllBytes($file)
	}
	[System.IO.File]::WriteAllBytes($outputFile, $combinedBytes)
	
	# Define the file paths within the folder
	$files = @("$WorkingDirectory\577l01.7c", "$WorkingDirectory\577l01.7c")
	# Specify the output file within the folder
	$outputFile = "$WorkingDirectory\arcade\gberet\rom2.bin"
	# Concatenate the files as binary data
	[Byte[]]$combinedBytes = @()
	foreach ($file in $files) {
		$combinedBytes += [System.IO.File]::ReadAllBytes($file)
	}
	[System.IO.File]::WriteAllBytes($outputFile, $combinedBytes)
	
	
	Write-Output "Copying Sprites"
	# Define the file paths within the folder
	$files = @("$WorkingDirectory\577l06.5e", "$WorkingDirectory\577l05.4e", "$WorkingDirectory\577l08.4f", "$WorkingDirectory\577l04.3e")
	# Specify the output file within the folder
	$outputFile = "$WorkingDirectory\arcade\gberet\sprites.bin"
	# Concatenate the files as binary data
	[Byte[]]$combinedBytes = @()
	foreach ($file in $files) {
		$combinedBytes += [System.IO.File]::ReadAllBytes($file)
	}
	[System.IO.File]::WriteAllBytes($outputFile, $combinedBytes)
	
	Write-Output "Copying Tiles"
	Copy-Item -Path $WorkingDirectory\577l07.3f -Destination $WorkingDirectory\arcade\gberet\577l07.3f
	
	Write-Output "Copying Sprite PROM"
	Copy-Item -Path $WorkingDirectory\577h10.5f -Destination $WorkingDirectory\arcade\gberet\577h10.5f
	
	Write-Output "Copying Character PROM"
	Copy-Item -Path $WorkingDirectory\577h11.6f -Destination $WorkingDirectory\arcade\gberet\577h11.6f
	
	Write-Output "Copying Palette PROM"
	Copy-Item -Path $WorkingDirectory\577h09.2f -Destination $WorkingDirectory\arcade\gberet\577h09.2f
	
	Write-Output "Generating blank config file"
	$bytes = New-Object byte[] $length
	for ($i = 0; $i -lt $bytes.Length; $i++) {
	$bytes[$i] = 0xFF
	}
	
	$output_file = Join-Path -Path $WorkingDirectory -ChildPath "arcade\gberet\gbcfg"
	$output_directory = [System.IO.Path]::GetDirectoryName($output_file)
	[System.IO.File]::WriteAllBytes($output_file,$bytes)

	Write-Output "All done!"