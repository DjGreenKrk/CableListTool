$ErrorActionPreference = "Stop"

Set-Location -Path $PSScriptRoot

Write-Host "Installing requirements..."
python -m pip install -r requirements.txt
if ($LASTEXITCODE -ne 0) {
    throw "pip install failed with exit code $LASTEXITCODE"
}

Write-Host "Building CableListTool.exe..."
$exePath = Join-Path $PSScriptRoot "dist\CableListTool.exe"
if (Test-Path -LiteralPath $exePath) {
    Write-Host "Removing previous build..."
    Remove-Item -LiteralPath $exePath -Force
}

python -m PyInstaller --noconfirm --clean CableListTool.spec
if ($LASTEXITCODE -ne 0) {
    throw "PyInstaller failed with exit code $LASTEXITCODE"
}

if (-not (Test-Path -LiteralPath $exePath)) {
    throw "Build finished without dist\CableListTool.exe"
}

Write-Host "Build complete:"
Write-Host $exePath
