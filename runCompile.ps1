# 
# Powershell Script to compile project from command line
# 

$ROOT = (Get-Item -Path ".\").FullName

# Compile the Workspace from the Compiler .cfg file
$P = Start-Process -FilePath 'C:\Program Files (x86)\Common Files\AMXShare\COM\NLRC.exe' -ArgumentList  "-CFG""$($ROOT)\compile.cfg""" -NoNewWindow -Wait

# Exit wtith Compiler Exit Code
exit $P.ExitCode
