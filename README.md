# ssh_certificate
SSH into servers using a CA/PKI instead of passwords or SSH keys. The certificate is JIT, so no credential exist before the cert is created and none exist after it expires.


This PowerShell script automates the process of authenticating with a HashiCorp Vault server to obtain a signed SSH key, which is then used to connect to a user-selected server. It's a method to provide temporary, secure access without using traditional SSH passwords or permanent keys on the target servers.

How the Code Works
The script is divided into five main sections:

1. Configuration and Server Selection
The script starts with a configuration block that defines a list of servers with their names and IP addresses, along with file paths for SSH keys and Vault-related information. It presents a numbered menu of servers to the user and prompts them to enter a number. The script then validates the user's input to ensure they select a valid server from the list.

2. Vault Login and Token Extraction
This part sets the VAULT_ADDR environment variable to the specified Vault server address. It then runs the vault login -method=oidc command, which initiates an OpenID Connect (OIDC) authentication flow. The script captures the command's output, which contains a temporary token after a successful login. It parses this output using a regular expression to extract the VAULT_TOKEN and sets it as an environment variable, allowing subsequent Vault commands to authenticate automatically.

3. Sign Public Key
Using the authenticated Vault token, the script calls vault write to send the user's public SSH key (id_ed25519.pub) to a specific path on the Vault server (ssh-client-signer/sign/billy-role). The Vault server, acting as a Certificate Authority (CA), signs the public key and returns a new, temporary signed key. This signed key is saved to a file (id_ed25519-signed-key.pub).

4. SSH Connection
The script then uses the ssh command to connect to the chosen server. It passes both the original private key (-i $privateKeyPath) and the newly signed public key (-i $signedKeyPath) to establish the connection. The remote server, which has been configured to trust Vault as a CA, validates the signed key and grants access to the user (billy).

5. Cleanup
After the SSH session ends, the script automatically removes the temporary signed key file (id_ed25519-signed-key.pub). This is a security best practice, as the signed key is only valid for a limited time and should not be stored permanently.
