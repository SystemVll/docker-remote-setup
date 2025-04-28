# Docker TLS Certificate Generation Utility

This script automates the setup of secure Docker TLS communication by generating all necessary certificates with proper Subject Alternative Names (SANs) and configuring both the Docker daemon and client.

## Features

- 🔒 Creates a complete PKI infrastructure with a Certificate Authority (no more "it works on my machine" excuses!)
- 🔐 Generates server and client certificates with proper SANs (because typing OpenSSL commands manually is about as fun as debugging CSS)
- 🚀 Automatically configures Docker daemon for TLS verification (saving you from the config file typo rabbit hole)
- 🌐 Sets up environment variables for Docker client (so you don't have to remember them... or Google them for the 100th time)
- 🎨 User-friendly interface with color-coded messages and emojis (making certificate generation slightly less soul-crushing)

## Requirements

- Linux system with Docker installed (Windows users, we feel your pain)
- Root privileges (sudo, because breaking things as a regular user isn't fun enough)
- OpenSSL installed (bring your own cryptography!)

## Quick Start

You can run this script directly from GitHub using:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/SystemVll/docker-remote-setup/main/docker-tls-setup.sh)
```

Then sit back and watch your terminal fill with colorful emojis - finally, a script that's as excited about certificates as you pretend to be!

## Manual Installation

1. Download the script (the old-fashioned way):
   ```bash
   wget https://raw.githubusercontent.com/SystemVll/docker-remote-setup/main/docker-tls-setup.sh
   ```

2. Make it executable (because permission denied errors are so 1990s):
   ```bash
   chmod +x docker-tls-setup.sh
   ```

3. Run with sudo (what could possibly go wrong?):
   ```bash
   sudo ./docker-tls-setup.sh
   ```

## Configuration Options

The script will interactively prompt you for:
- Server hostname and alias (no, "awesome-docker-machine" is not a good hostname)
- Server IP address (yes, localhost counts... technically)
- Client name (be more creative than "client1" please)
- Certificate storage location (for when `/etc/docker/tls` is just too mainstream)
- CA private key password (not "password123" - we're looking at you, Dave from IT)

## Security Notes

- The certificates are stored at `/etc/docker/tls` by default (not on a Post-it note on your monitor)
- Remember to back up your certificates securely (not in that email to yourself titled "IMPORTANT CERTS!!!")
- The CA password should be stored in a safe place (your password manager, not your "secure" text file called passwords.txt)
- All certificate files have restricted permissions (0600) (because sharing is not always caring)

## Troubleshooting

If the Docker connection test fails:
1. Check if Docker daemon is running: `systemctl status docker` (have you tried turning it off and on again?)
2. Verify certificate paths in `/etc/docker/daemon.json` (typos are the silent killers of configuration files)
3. Ensure the environment variables are set: `source /etc/profile.d/docker-tls.sh` (because computers do what you tell them, not what you want them to do)
4. Check for networking issues between client and server (blame it on DNS, it's always DNS)

## License

MIT License (we're generous like that)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. We promise to review it sometime before the heat death of the universe.
