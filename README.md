# windows-dev

A simple utility that automates downloading Cygwin, exporting the system CA certificates, and formatting them as a PEM file. 

This is done just to create a PEM-encoded certificate chain that UNIX-y programs like Git Bash can use when cloning from 
Horizon over HTTPS. Without it, Git Bash would fail with SSL validation errors because it doesn't not know
how to interact with the Windows certificate API to read the CA certificates that way. 

One _can_ disable SSL validation, but that defeats the whole purpose of SSL in the first place.

## Usage

Open up a PowerShell window and run the following commands:

```powershell
Unblock-File .\bootstrap.ps1
.\bootstrap.ps1
```

This will download Cygwin, export the certificates, and format them to the default CA certificate chain located at 
`C:/root/cygwin64/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem`. 

If you are using Cygwin alongside GitBash, the GitBash git can be configured to use this file by running the following command:
```bash
git config --global http.sslCAInfo <path_to_ca_cert_chain>
```