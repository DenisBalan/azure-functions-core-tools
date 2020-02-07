$baseDir = Get-Location

if (-not (@($env:Path -split ";") -contains $env:WIX))
{
    # Check if the Wix path points to the bin folder
    if ((Split-Path $env:WIX -Leaf) -ne "bin")
    {
        $env:Path += ";$env:WIX\bin"
    }
    else
    {
        $env:Path += ";$env:WIX"
    }
}

if ($env:APPVEYOR_REPO_BRANCH -eq "disabled") {
    Set-Location ".\src\Azure.Functions.Cli"
    $result = Invoke-Expression -Command "NuGet list Microsoft.Azure.Functions.JavaWorker -Source  https://ci.appveyor.com/NuGet/azure-functions-java-worker-fejnnsvmrkqg -PreRelease"
    $javaWorkerVersion = $result.Split()[1]
    Write-host "Adding Microsoft.Azure.Functions.JavaWorker $javaWorkerVersion to project" -ForegroundColor Green
    Invoke-Expression -Command "dotnet add package Microsoft.Azure.Functions.JavaWorker -v $javaWorkerVersion -s  https://ci.appveyor.com/NuGet/azure-functions-java-worker-fejnnsvmrkqg"
    
    $result = Invoke-Expression -Command "NuGet list Microsoft.Azure.Functions.PowerShellWorker -Source https://ci.appveyor.com/nuget/azure-functions-powershell-wor-0842fakagqy6 -PreRelease"
    $powerShellWorkerVersion = $result.Split()[1]
    Write-host "Adding Microsoft.Azure.Functions.PowerShellWorker $powerShellWorkerVersion to project" -ForegroundColor Green
    Invoke-Expression -Command "dotnet add package Microsoft.Azure.Functions.PowerShellWorker -v $powerShellWorkerVersion -s https://ci.appveyor.com/nuget/azure-functions-powershell-wor-0842fakagqy6"

    $result = Invoke-Expression -Command "NuGet list Microsoft.Azure.Functions.NodeJsWorker -Source https://ci.appveyor.com/nuget/azure-functions-nodejs-worker-0fcvx371y52p -PreRelease"
    $nodeJsWorkerVersion = $result.Split()[1]
    Write-host "Adding Microsoft.Azure.Functions.NodeJsWorker $nodeJsWorkerVersion to project" -ForegroundColor Green
    Invoke-Expression -Command "dotnet add package Microsoft.Azure.Functions.NodeJsWorker -v $nodeJsWorkerVersion -s https://ci.appveyor.com/nuget/azure-functions-nodejs-worker-0fcvx371y52p"

    $result = Invoke-Expression -Command "NuGet list Microsoft.Azure.WebJobs.Script.WebHost -Source https://ci.appveyor.com/NuGet/azure-webjobs-sdk-script-g6rygw981l9t -PreRelease"
    $WebHostVersion = $result.Split()[1]
    Write-host "Adding Microsoft.Azure.WebJobs.Script.WebHost $WebHostVersion to project" -ForegroundColor Green
    Invoke-Expression -Command "dotnet add package Microsoft.Azure.WebJobs.Script.WebHost -v $WebHostVersion -s https://ci.appveyor.com/NuGet/azure-webjobs-sdk-script-g6rygw981l9t"
    Set-Location "..\..\build"
}
else {
    Set-Location ".\build"
}

if ($env:APPVEYOR_REPO_BRANCH -eq "master") {
    Invoke-Expression -Command  "dotnet run --sign"
    if ($LastExitCode -ne 0) { $host.SetShouldExit($LastExitCode)  }
}
else {
    Invoke-Expression -Command  "dotnet run"
    if ($LastExitCode -ne 0) { $host.SetShouldExit($LastExitCode)  }
}

# Get runtime version
$artifactsPath = "$baseDir\artifacts"
$cli = Get-ChildItem -Path $artifactsPath -Include func.dll -Recurse | Select-Object -First 1
$cliVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($cli).FileVersion

@('x64', 'x86') | ForEach-Object { 
    $platform = $_

    # Generate win-x64 MSI
    # Copy icon and license
    Copy-Item "$basedir\icon.ico" -Destination $artifactsPath\win-$platform
    Copy-Item "$basedir\license.rtf" -Destination $artifactsPath\win-$platform
    Set-Location "$artifactsPath\win-$platform"
    
    $masterWxsName = "funcinstall"
    $fragmentName = "$platform-frag"
    $msiName = "func-cli"
    
    $masterWxsPath = "$baseDir\$masterWxsName.wxs"
    $fragmentPath = "$baseDir\$fragmentName.wxs"
    $msiPath = "$artifactsPath\$msiName-$platform.msi"
    
    Invoke-Expression "heat dir '.' -cg FuncHost -dr INSTALLDIR -gg -ke -out $fragmentPath -sreg -template fragment -var var.Source"
    Invoke-Expression "candle -arch $platform -dPlatform='$platform' -dSource='.' -dProductVersion='$cliVersion' $masterWxsPath $fragmentPath"
    Invoke-Expression "light -ext WixUIExtension -out $msiPath -sice:ICE61 $masterWxsName.wixobj $fragmentName.wixobj" 
}
