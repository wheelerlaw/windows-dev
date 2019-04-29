$ErrorActionPreference = "stop"

$cygwin_dir = "C:/root/cygwin64"

mkdir $cygwin_dir -ErrorAction Stop

Write-Output ""
Write-Output "Downloading Cygwin"

# Use px to allow UNIX-y programs that don't speak NTML to connect to the internet through the corporate proxies.
# See https://github.com/genotrance/px for more information
$px = $(Start-Process -NoNewWindow -PassThru ./dist/px.exe)
$env:http_proxy="http://localhost:3128"
$env:https_proxy="http://localhost:3128"

$proxy = New-Object System.Net.WebProxy($env:http_proxy)
$wc = new-object system.net.WebClient
$wc.proxy = $proxy

$wc.DownloadFile('https://cygwin.com/setup-x86_64.exe',"$cygwin_dir/setup-x86_64.exe")

Write-Output "Installing cygwin"
& "$cygwin_dir/setup-x86_64.exe" `
    --quiet-mode `
    --no-admin `
    --no-desktop `
    --site "http://mirrors.kernel.org/sourceware/cygwin/" `
    --root "$cygwin_dir" `
    --local-package-dir "$cygwin_dir/pkg" `
    --verbose `
    --prune-install `
    --packages wget,rsync,curl,lynx `
| Out-Null

Add-Content "$cygwin_dir/etc/nsswitch.conf" "db_home: /cygdrive/c/Users/%U"

# Export the BofA public CA certificates from the system store, and PEM encode them so UNIX-y programs
# like Git Bash can use them. This allows Git to clone from Horizon over HTTPS without needing to disable SSL.
$cert_dir = "$cygwin_dir/certs"
mkdir $cert_dir
$(Get-ChildItem -Path cert:\LocalMachine\Root -Recurse) + $( Get-ChildItem -Path cert:\LocalMachine\CA -Recurse) |
        Where-Object {
            $_.notafter -gt (Get-Date) -AND !$_.hasprivatekey
        } |
        Sort-Object -property thumbprint -unique |
        ForEach-Object {
            Export-Certificate -Cert $_ -FilePath "$cert_dir/$($_.thumbprint).cer"
            & "$cygwin_dir/bin/openssl.exe" x509 -inform DER -in "$cert_dir/$($_.thumbprint).cer" -outform PEM -out "$cygwin_dir/etc/pki/ca-trust/source/anchors/$($_.thumbprint).pem"
        }

# Run the Cywgin setup bash scripts since I'm better at bash than powershell.
Write-Output "Running scripts"
$env:CHERE_INVOKING=1
& "$cygwin_dir/bin/bash" --login ./setup.bash "$cygwin_dir/corp-ca-bundle.pem"

# Stop px when we are done, since we don't need it anymore.
Stop-Process -Id $px.Id
