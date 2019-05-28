# 
# Powershell Script to get a Compiler Config 
# 

$ROOT = (Get-Item -Path ".\").FullName
$URI = "https://us-central1-soloworkslondon.cloudfunctions.net/GenerateNetlinxCompileCfg?"
$URI = "$($URI)root=$($ROOT)"
$URI = "$($URI)&logfile=compile.log"
$URI = "$($URI)&logconsole=true"

# Fetching compile.cfg
$R = Invoke-WebRequest -Uri $URI -Method POST -InFile ".\netlinx-global-code.apw" -OutFile ".\compile.cfg" -PassThru

# Output to Console
Get-Content -Path ".\compile.cfg"

# Exit wtith Compiler Exit Code
IF($R.StatusCode -ne 200){
    Exit 1
}

