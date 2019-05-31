
$ROOT = (Get-Item -Path ".\").FullName
$URI = "https://us-central1-soloworkslondon.cloudfunctions.net/ProcessNetlinxCompileLog?"
$URI = "$($URI)root=$($ROOT)"

Invoke-WebRequest -Uri $URI -Method POST -InFile ".\compile.log" -OutFile ".\clean.log" -PassThru -UseBasicParsing

# Output to Console
Get-Content -Path ".\clean.log"