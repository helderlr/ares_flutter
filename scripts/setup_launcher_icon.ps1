$assetsDir = Join-Path $PSScriptRoot "..\assets\images"
New-Item -ItemType Directory -Force -Path $assetsDir | Out-Null
$logoPath = Join-Path $assetsDir "logo_domina.png"
Invoke-WebRequest -Uri "https://aresia.com.br/logo.png" -OutFile $logoPath -UseBasicParsing
Write-Host "Logo salva em: $logoPath"
Set-Location (Join-Path $PSScriptRoot "..")
flutter pub get
dart run flutter_launcher_icons
Write-Host "Icone do launcher atualizado. Reinstale o app no celular."
