# Configuration
$servers = @{
    "1" = @{ Name = "server1"; IP = "192.168.10.1" }
    "2" = @{ Name = "server2"; IP = "192.168.10.2" }
    "3" = @{ Name = "server3"; IP = "192.168.10.3" }
    "4" = @{ Name = "server4"; IP = "192.168.10.4" }
    "5" = @{ Name = "server5"; IP = "192.168.10.5" }
    "6" = @{ Name = "server6"; IP = "192.168.1.6" }
    "7" = @{ Name = "server7x"; IP = "192.168.10.7" } 
    "8" = @{ Name = "server8"; IP = "192.168.1.8" } 
    "9" = @{ Name = "server9y"; IP = "192.168.1.8" } 
    "10" = @{ Name = "server10"; IP = "192.168.1.10" } 
    "11" = @{ Name = "server11"; IP = "192.168.1.11" }
    "12" = @{ Name = "server12"; IP = "192.168.10.12" } 
    "13" = @{ Name = "server13"; IP = "192.168.10.13" } 
}

$publicKeyPath = "C:\Users\<user>\.ssh\id_ed25519.pub"
$privateKeyPath = "C:\Users\<user>\.ssh\id_ed25519"
$signedKeyPath = "C:\Users\<user>\.ssh\id_ed25519-signed-key.pub"
$vaultAddress = "https://vault.io:8200"
$vaultRole = "ssh-client"
$vaultSignPath = "ssh-client-signer/sign/<user>-role"
$sshUser = "<user>"

# 1. Server Selection
Write-Host "Select a server:"

# Sort and display the servers in numerical order
foreach ($key in $servers.Keys | Sort-Object {[int]$_}) {
    Write-Host "$key. $($servers[$key].Name)"
}

do {
    $serverChoice = Read-Host "Enter server number"
} while (-not $servers.ContainsKey($serverChoice))

# Display the chosen server details
$selectedServer = $servers[$serverChoice]
Write-Host 

# 2. Set Vault Address
$env:VAULT_ADDR = $vaultAddress

# 3. Vault Login and Token Extraction
# Run the Vault login command
$commandOutput = vault login -method=oidc role=ssh-client

# Output the command result to help with debugging
Write-Host "Command Output:`n$commandOutput"

# Extract the token value from the command output
$lines = $commandOutput -split "`n"
foreach ($line in $lines) {
    if ($line -match '^token\s+([^\s]+)$') {
        $token = $matches[1]

        # Set the token as an environmental variable
        $env:VAULT_TOKEN = $token
        Write-Host "VAULT_TOKEN has been set to: $token"
    }
}

if (-not $token) {
    Write-Host "Failed to extract the token from the command output."
}
# 4. Sign Public Key
Write-Host "Signing public key..."

try {
    vault write -field=signed_key $vaultSignPath public_key="@$publicKeyPath" | Out-File -FilePath $signedKeyPath -Encoding utf8
    Write-Host "Public key signed successfully."
}
catch {
    Write-Error "Error signing public key: $($_.Exception.Message)"
    exit 1
}

# 5. SSH Connection
Write-Host "Connecting via SSH..."

try {
    ssh -i $signedKeyPath -i $privateKeyPath "$sshUser@$($selectedServer.IP)"
}
catch {
    Write-Error "SSH connection failed: $($_.Exception.Message)"
    exit 1
}

Write-Host "SSH session ended."

# Clean up the signed key file
Remove-Item $signedKeyPath -Force
