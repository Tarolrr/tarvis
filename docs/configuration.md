# Tarvis Configuration Reference

Configuration file location: `~/.openclaw/openclaw.json`

## Configuration Structure

```json
{
  "channels": {},
  "agents": {},
  "hooks": {},
  "gateway": {},
  "messages": {}
}
```

## Channels Configuration

### Telegram

```json
{
  "channels": {
    "telegram": {
      "botToken": "your-bot-token",
      "allowFrom": ["username1", "+1234567890"],
      "dm": {
        "policy": "pairing"
      },
      "groups": {
        "*": {
          "requireMention": true
        }
      },
      "webhookUrl": "https://your-domain.com/webhook",
      "webhookSecret": "your-secret"
    }
  }
}
```

**Options**:
- `botToken`: Your Telegram bot token from BotFather
- `allowFrom`: Array of usernames or phone numbers allowed to interact
- `dm.policy`: `"pairing"` (default) or `"open"`
- `groups`: Group-specific settings
- `requireMention`: Require bot mention in groups

### WhatsApp

```json
{
  "channels": {
    "whatsapp": {
      "allowFrom": ["+1234567890"],
      "groups": {
        "*": {
          "requireMention": true
        }
      }
    }
  }
}
```

**Setup**: Run `openclaw channels login` to pair your device.

### Discord

```json
{
  "channels": {
    "discord": {
      "token": "your-bot-token",
      "dm": {
        "policy": "pairing",
        "allowFrom": ["user-id"]
      },
      "guilds": {
        "guild-id": {
          "enabled": true
        }
      },
      "mediaMaxMb": 25
    }
  }
}
```

### Slack

```json
{
  "channels": {
    "slack": {
      "botToken": "xoxb-...",
      "appToken": "xapp-...",
      "dm": {
        "policy": "pairing"
      }
    }
  }
}
```

## Agent Configuration

### Default Model Settings

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "openai/gpt-4o",
        "fallbacks": [
          "openai/gpt-4o-mini",
          "anthropic/claude-3-5-sonnet-20241022"
        ]
      },
      "thinking": "high",
      "temperature": 0.7
    }
  }
}
```

**Thinking Modes**:
- `"off"`: No extended thinking
- `"low"`: Minimal reasoning
- `"medium"`: Balanced reasoning
- `"high"`: Extended reasoning for complex tasks

### Model Providers

**OpenAI**:
```json
{
  "providers": {
    "openai": {
      "apiKey": "sk-...",
      "organization": "org-..."
    }
  }
}
```

**Anthropic**:
```json
{
  "providers": {
    "anthropic": {
      "apiKey": "sk-ant-..."
    }
  }
}
```

**Google**:
```json
{
  "providers": {
    "google": {
      "authType": "oauth"
    }
  }
}
```

**OpenRouter**:
```json
{
  "providers": {
    "openrouter": {
      "apiKey": "sk-or-..."
    }
  }
}
```

## Hooks Configuration

### Gmail Webhook

```json
{
  "hooks": {
    "enabled": true,
    "token": "your-secure-webhook-token",
    "path": "/hooks",
    "presets": ["gmail"],
    "gmail": {
      "account": "your-email@gmail.com",
      "model": "openai/gpt-4o-mini",
      "thinking": "off",
      "serve": {
        "bind": "127.0.0.1",
        "port": 8788,
        "path": "/gmail-pubsub"
      },
      "tailscale": {
        "enabled": true,
        "path": "/gmail-pubsub"
      }
    }
  }
}
```

### Custom Webhooks

```json
{
  "hooks": {
    "enabled": true,
    "token": "your-token",
    "mappings": [
      {
        "match": {
          "path": "custom-hook"
        },
        "action": "agent",
        "wakeMode": "now",
        "sessionKey": "hook:custom:{{id}}",
        "messageTemplate": "Event: {{event}}",
        "deliver": true,
        "channel": "telegram"
      }
    ]
  }
}
```

## Gateway Configuration

### Basic Settings

```json
{
  "gateway": {
    "port": 18789,
    "host": "127.0.0.1",
    "verbose": true
  }
}
```

### Tailscale Integration

```json
{
  "gateway": {
    "tailscale": {
      "enabled": true,
      "funnel": true,
      "hostname": "tarvis"
    }
  }
}
```

### CORS Settings

```json
{
  "gateway": {
    "cors": {
      "enabled": true,
      "origins": ["https://your-domain.com"]
    }
  }
}
```

## Message Configuration

### Group Chat Settings

```json
{
  "messages": {
    "groupChat": {
      "mentionPatterns": ["@tarvis", "@bot", "tarvis"],
      "replyMode": "thread"
    }
  }
}
```

### Media Handling

```json
{
  "messages": {
    "media": {
      "maxSizeMb": 20,
      "transcription": {
        "enabled": true,
        "provider": "openai"
      },
      "vision": {
        "enabled": true,
        "model": "openai/gpt-4o"
      }
    }
  }
}
```

## Session Configuration

```json
{
  "sessions": {
    "mode": "per-sender",
    "timeout": 3600,
    "maxHistory": 50
  }
}
```

**Session Modes**:
- `"per-sender"`: Separate session per user
- `"per-channel"`: Shared session per channel
- `"global"`: Single global session
- `"per-group"`: Separate session per group

## Security Configuration

### DM Pairing

```json
{
  "security": {
    "dmPolicy": "pairing",
    "pairingCodeLength": 6,
    "pairingExpiry": 300
  }
}
```

### Allowlists

```json
{
  "security": {
    "globalAllowlist": ["+1234567890", "username"],
    "blockList": ["spammer"]
  }
}
```

### Rate Limiting

```json
{
  "security": {
    "rateLimit": {
      "enabled": true,
      "maxRequests": 10,
      "windowSeconds": 60
    }
  }
}
```

## Cron Jobs

```json
{
  "cron": {
    "jobs": [
      {
        "name": "daily-summary",
        "schedule": "0 9 * * *",
        "action": "agent",
        "message": "Give me a summary of today's tasks",
        "channel": "telegram",
        "to": "your-username"
      }
    ]
  }
}
```

## Environment Variables

OpenClaw supports environment variables that override config file settings:

- `TELEGRAM_BOT_TOKEN`: Telegram bot token
- `SLACK_BOT_TOKEN`: Slack bot token
- `SLACK_APP_TOKEN`: Slack app token
- `DISCORD_BOT_TOKEN`: Discord bot token
- `OPENAI_API_KEY`: OpenAI API key
- `ANTHROPIC_API_KEY`: Anthropic API key
- `OPENCLAW_SKIP_GMAIL_WATCHER`: Skip auto-starting Gmail watcher

## Configuration Best Practices

1. **Use environment variables for secrets**: Keep API keys out of config files
2. **Enable pairing mode**: Protect against unauthorized access
3. **Set up allowlists**: Explicitly control who can interact
4. **Configure model fallbacks**: Ensure reliability during outages
5. **Use Tailscale for remote access**: Secure tunnel instead of exposing ports
6. **Enable verbose logging initially**: Easier troubleshooting during setup
7. **Regular backups**: Keep a backup of your config file

## Example Full Configuration

```json
{
  "channels": {
    "telegram": {
      "botToken": "your-token",
      "allowFrom": ["tarolrr"],
      "dm": {
        "policy": "pairing"
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "openai/gpt-4o",
        "fallbacks": ["openai/gpt-4o-mini"]
      },
      "thinking": "medium"
    }
  },
  "hooks": {
    "enabled": true,
    "token": "secure-token-here",
    "presets": ["gmail"],
    "gmail": {
      "account": "your-email@gmail.com",
      "model": "openai/gpt-4o-mini"
    }
  },
  "gateway": {
    "port": 18789,
    "tailscale": {
      "enabled": true,
      "funnel": true
    }
  },
  "messages": {
    "groupChat": {
      "mentionPatterns": ["@tarvis"]
    }
  }
}
```
