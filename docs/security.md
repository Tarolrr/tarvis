# Tarvis Security Guide

Security is critical when running a personal AI assistant that connects to your messaging services and email.

## Security Model Overview

OpenClaw implements multiple security layers:

1. **Local-first**: All processing happens on your machine
2. **Pairing mode**: Unknown senders must be approved
3. **Allowlists**: Explicit control over who can interact
4. **Encrypted connections**: Secure communication with external services
5. **Token-based webhooks**: Authenticated webhook endpoints

## DM Pairing Mode

### How It Works

When pairing mode is enabled (default), unknown senders receive a pairing code and their message is not processed until you approve them.

### Configuration

```json
{
  "channels": {
    "telegram": {
      "dm": {
        "policy": "pairing"
      }
    }
  }
}
```

### Approving Senders

When someone new messages your bot:

```bash
# They receive a pairing code (e.g., ABC123)
# You approve them with:
openclaw pairing approve telegram ABC123
```

After approval, they're added to your local allowlist and can interact freely.

### Disabling Pairing (Not Recommended)

To allow anyone to message your bot:

```json
{
  "channels": {
    "telegram": {
      "dm": {
        "policy": "open"
      },
      "allowFrom": ["*"]
    }
  }
}
```

⚠️ **Warning**: This allows anyone who finds your bot to interact with it.

## Allowlists

### Per-Channel Allowlists

Explicitly control who can interact:

```json
{
  "channels": {
    "telegram": {
      "allowFrom": ["tarolrr", "+1234567890"]
    },
    "whatsapp": {
      "allowFrom": ["+1234567890", "+0987654321"]
    }
  }
}
```

### Group Allowlists

Control which groups the bot responds in:

```json
{
  "channels": {
    "telegram": {
      "groups": {
        "group-id-1": {
          "enabled": true,
          "requireMention": true
        },
        "group-id-2": {
          "enabled": true
        }
      }
    }
  }
}
```

Use `"*"` to allow all groups (with mention requirement):

```json
{
  "channels": {
    "telegram": {
      "groups": {
        "*": {
          "requireMention": true
        }
      }
    }
  }
}
```

## Webhook Security

### Token Authentication

All webhooks require a secure token:

```json
{
  "hooks": {
    "enabled": true,
    "token": "your-very-secure-random-token-here"
  }
}
```

Generate a secure token:
```bash
openssl rand -hex 32
```

### Tailscale Funnel

For Gmail and other webhook integrations, use Tailscale Funnel for secure public endpoints:

```json
{
  "hooks": {
    "gmail": {
      "tailscale": {
        "enabled": true,
        "path": "/gmail-pubsub"
      }
    }
  }
}
```

Benefits:
- Encrypted HTTPS endpoint
- No port forwarding needed
- Access control via Tailscale ACLs
- Automatic certificate management

## Credential Storage

### Location

Credentials are stored in:
- `~/.openclaw/credentials/` - Channel credentials (WhatsApp, etc.)
- `~/.openclaw/openclaw.json` - Configuration (may contain tokens)

### Permissions

Ensure proper file permissions:

```bash
chmod 600 ~/.openclaw/openclaw.json
chmod 700 ~/.openclaw/credentials/
```

### Environment Variables

For sensitive data, use environment variables instead of config files:

```bash
export TELEGRAM_BOT_TOKEN="your-token"
export OPENAI_API_KEY="your-key"
export ANTHROPIC_API_KEY="your-key"
```

Add to `~/.bashrc` or `~/.zshrc` for persistence.

### Git Security

Never commit credentials to Git:

```gitignore
# .gitignore
.openclaw/
credentials/
*.key
*.pem
.env
secrets.json
tokens.json
```

## API Key Management

### Rotation

Regularly rotate API keys:

1. Generate new key from provider
2. Update configuration
3. Test functionality
4. Revoke old key

### Scoping

Use minimal required permissions:

- **OpenAI**: Use project-scoped keys
- **Google Cloud**: Use service accounts with minimal IAM roles
- **Telegram**: Bot tokens are scoped to the bot

## Network Security

### Local-Only Gateway

By default, the Gateway binds to localhost:

```json
{
  "gateway": {
    "host": "127.0.0.1",
    "port": 18789
  }
}
```

This prevents external access.

### Remote Access

For remote access, use Tailscale instead of exposing ports:

```json
{
  "gateway": {
    "tailscale": {
      "enabled": true,
      "funnel": false
    }
  }
}
```

Access via: `http://tarvis.your-tailnet.ts.net:18789`

### Firewall Rules

If running on a server, configure firewall:

```bash
# Allow only Tailscale interface
sudo ufw allow in on tailscale0
sudo ufw deny 18789
```

## Data Privacy

### Local Processing

All AI processing happens locally or via your configured API providers. OpenClaw does not send data to third-party servers.

### Message Storage

Messages are stored locally in:
- `~/.openclaw/sessions/` - Session history
- `~/.openclaw/logs/` - System logs

### Retention

Configure message retention:

```json
{
  "sessions": {
    "maxHistory": 50,
    "timeout": 3600
  }
}
```

### Clearing Data

Remove all session data:

```bash
rm -rf ~/.openclaw/sessions/*
```

## Model Security

### External Content Safety

For webhooks (like Gmail), external content is wrapped in safety boundaries by default:

```json
{
  "hooks": {
    "gmail": {
      "allowUnsafeExternalContent": false
    }
  }
}
```

⚠️ **Warning**: Only set to `true` if you trust the content source.

### Model Isolation

Use different models for different trust levels:

```json
{
  "hooks": {
    "gmail": {
      "model": "openai/gpt-4o-mini",
      "thinking": "off"
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "openai/gpt-4o"
      }
    }
  }
}
```

## Monitoring and Auditing

### Enable Logging

```json
{
  "gateway": {
    "verbose": true,
    "logLevel": "info"
  }
}
```

### Review Logs

```bash
# Real-time monitoring
journalctl --user -u openclaw -f

# Search for security events
journalctl --user -u openclaw | grep -i "unauthorized\|denied\|failed"
```

### Audit Trail

Track who interacts with your assistant:

```bash
# View session activity
ls -la ~/.openclaw/sessions/

# Check pairing approvals
openclaw pairing list
```

## Security Checklist

- [ ] Pairing mode enabled for all channels
- [ ] Allowlists configured for each channel
- [ ] Secure webhook tokens generated
- [ ] Tailscale configured for remote access
- [ ] File permissions set correctly (600/700)
- [ ] API keys stored in environment variables
- [ ] .gitignore configured to exclude credentials
- [ ] Regular API key rotation scheduled
- [ ] Logging enabled for monitoring
- [ ] Firewall rules configured (if applicable)
- [ ] Session retention limits set
- [ ] External content safety enabled

## Security Best Practices

1. **Principle of Least Privilege**: Only grant necessary permissions
2. **Defense in Depth**: Use multiple security layers
3. **Regular Updates**: Keep OpenClaw and dependencies updated
4. **Monitor Activity**: Review logs regularly
5. **Secure Backups**: Encrypt backups of configuration
6. **Incident Response**: Have a plan for compromised credentials
7. **Test Security**: Regularly verify security controls work

## Incident Response

### If Credentials Are Compromised

1. **Immediately revoke** the compromised credentials
2. **Generate new** credentials
3. **Update configuration** with new credentials
4. **Review logs** for unauthorized activity
5. **Clear sessions** if necessary
6. **Notify affected services** (if applicable)

### If Bot Is Compromised

1. **Stop the Gateway**: `systemctl --user stop openclaw`
2. **Review logs**: Check for suspicious activity
3. **Revoke all tokens**: Bot tokens, API keys, etc.
4. **Clear allowlists**: Remove unauthorized users
5. **Update credentials**: Generate new tokens
6. **Restart with clean state**: `openclaw gateway --port 18789`

## Reporting Security Issues

If you discover a security vulnerability in OpenClaw:

1. **Do not** open a public issue
2. Report to the OpenClaw security team
3. Follow responsible disclosure practices

## Additional Resources

- [OpenClaw Security Documentation](https://docs.openclaw.ai/gateway/security)
- [Tailscale Security Best Practices](https://tailscale.com/kb/1018/security)
- [OAuth 2.0 Security Best Practices](https://oauth.net/2/security-best-practices/)
