# 
# Powershell Script to compile project from command line
# 

$ROOT = (Get-Item -Path ".\").FullName

$URI = "https://us-central1-soloworkslondon.cloudfunctions.net/GenerateNetlinxCompileCfg?"
$URI = "$($URI)root=$($ROOT)"
$URI = "$($URI)&logfile=compile.log"
$URI = "$($URI)&logconsole=true"

$R = Invoke-WebRequest -Uri $URI -Method POST -InFile ".\netlinx-global-code.apw" -OutFile ".\compile.cfg"

Start-Process -FilePath 'C:\Program Files (x86)\Common Files\AMXShare\COM\NLRC.exe' -ArgumentList  "-CFG""$($ROOT)\compile.cfg""" -NoNewWindow
