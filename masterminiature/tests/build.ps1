param(
    [string]$Fqbn = 'esp32:esp32:esp32',
    [string]$ArduinoCli = "$env:LOCALAPPDATA/Programs/Arduino IDE/resources/app/lib/backend/resources/arduino-cli.exe"
)
$ErrorActionPreference = 'Stop'
$masterRoot = Split-Path -Parent $PSScriptRoot
$slaveRoot = Join-Path (Split-Path -Parent $masterRoot) 'slaveminiature'
$librariesRoot = Join-Path (Split-Path -Parent $masterRoot) 'libraries'
foreach ($sketchRoot in @($masterRoot, $slaveRoot)) {
    $buildRoot = Join-Path $sketchRoot '.build/esp32'
    & $ArduinoCli compile --fqbn $Fqbn --jobs 2 --libraries $librariesRoot --build-path $buildRoot $sketchRoot
    if ($LASTEXITCODE -ne 0) { throw "Compile failed for $sketchRoot (exit $LASTEXITCODE)" }
}
