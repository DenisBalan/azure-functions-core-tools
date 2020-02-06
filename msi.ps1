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