# 
# Powershell Script to compile project from command line
# 

$ROOT = (Get-Item -Path ".\").FullName

# Compile the Workspace from the Compiler .cfg file
$P = Start-Process -FilePath 'C:\Program Files (x86)\Common Files\AMXShare\COM\NLRC.exe' -ArgumentList  "-CFG""$($ROOT)\compile.cfg""" -NoNewWindow -Wait -PassThru

# Process the Log File

$ROOT = (Get-Item -Path ".\").FullName
$URI = "https://us-central1-soloworkslondon.cloudfunctions.net/ProcessNetlinxCompileLog?"
$URI = "$($URI)root=$($ROOT)"

Invoke-WebRequest -Uri $URI -Method POST -InFile ".\compile.log" -OutFile ".\clean.log" -PassThru -UseBasicParsing

# Output to Console
Get-Content -Path ".\clean.log"


# Exit wtith Compiler Exit Code
exit $P.ExitCode
