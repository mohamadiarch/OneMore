<#
.SYNOPSIS
Update OneMore registry keys to point to the current development directories
intead of the program files install paths
#>

param ()

Begin
{
    # ProductVersion may be truncated such as "4.12" so this expands it to be "4.12.0.0"
    function MakeVersion
    {
        param($version)
        $parts = $version.Split('.')
        for (($i = $parts.Length); $i -lt 4; $i++)
        {
            $version = "$version.0"
        }
        return $version
    }
}
Process
{
    $here = Get-Location
    $dll = Join-Path $here 'OneMore\bin\x86\Debug\River.OneMoreAddIn.dll'
    if (!(Test-Path $dll))
    {
        Write-Host "cannot find $dll"
        return
    }

    $guid = '{88AB88AB-CDFB-4C68-9C3A-F10B75A5BC61}'
    $pv = MaKeVersion (Get-Item $dll | % { $_.VersionInfo.ProductVersion })

    # onemore:// protocol handler registration
	$0 = 'Registry::HKEY_CLASSES_ROOT\onemore\shell\open\command'
    if (Test-Path $0)
    {
        $exe = Join-Path $here 'OneMoreProtocolHandler\bin\Debug\OneMoreProtocolHandler.exe'
        Write-Host "setting $0"
	    Set-ItemProperty $0 -Name '(Default)' -Type String -Value "$exe %1 %2 %3 %4 %5"
    }

    # CLSID
    $0 = "Registry::HKEY_CLASSES_ROOT\CLSID\$guid\InprocServer32"
    if (Test-Path $0)
    {
        Write-Host "setting $0"
        $asm = "River.OneMoreAddIn, Version=$pv, Culture=neutral, PublicKeyToken=null"
	    Set-ItemProperty $0 -Name Assembly -Type String -Value $asm
	    Set-ItemProperty $0 -Name CodeBase -Type String -Value $dll
    }

    $1 = "Registry::HKEY_CLASSES_ROOT\CLSID\$guid\InprocServer32\$pv"
    if (!(Test-Path $1))
    {
        write-Host "creating $1"
        New-Item -Path $0 -Name $pv
        $asm = "River.OneMoreAddIn, Version=$pv, Culture=neutral, PublicKeyToken=null"
	    Set-ItemProperty $1 -Name 'Assembly' -Type String -Value $asm
        Set-ItemProperty $1 -Name 'Class' -Type String -Value 'River.OneMoreAddIn.AddIn'
        Set-ItemProperty $1 -Name 'RuntimeVersion' (Get-ItemPropertyValue $0 -Name 'RuntimeVersion')
    }
    Write-Host "setting $1"
    Set-ItemProperty $1 -Name CodeBase -Type String -Value $dll

    # app path
    $0 = 'Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\River.OneMoreAddIn.dll'
    if (Test-Path $0)
    {
        Write-Host "setting $0"
	    Set-ItemProperty $0 -Name Path -Type String -Value $dll
    }
}
