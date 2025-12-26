---
name: exe-systemd-service
description: Create persistent systemd services that survive reboots on exe.dev VMs. Use when the user wants to run a service continuously, start a service on boot, or ensure a process restarts automatically.
---

# exe.dev Systemd Service Skill

This skill helps you create persistent systemd services that automatically start on boot and restart on failure.

## When to Use Systemd Services

Use systemd services when:
- Running a web server that should always be available
- Running background workers or task queues
- Running any service that needs to survive reboots
- Running processes that should auto-restart on failure

## Service Creation Workflow

### 1. Determine Service Requirements

Before creating a service, identify:
- **Service name**: Short, descriptive name (e.g., `myapp`, `api-server`)
- **Working directory**: Where the service runs from
- **Start command**: The exact command to start the service
- **User**: Which user should run the service (default: current user)

### 2. Create the Service File

Create a service file at `/etc/systemd/system/<service-name>.service`:

```bash
sudo tee /etc/systemd/system/myapp.service << 'EOF'
[Unit]
Description=My Application
After=network.target

[Service]
Type=simple
User=exedev
WorkingDirectory=/home/exedev/myapp
ExecStart=/home/exedev/myapp/start.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
```

### 3. Enable and Start the Service

```bash
# Reload systemd to recognize the new service
sudo systemctl daemon-reload

# Enable service to start on boot and start it now
sudo systemctl enable --now myapp

# Verify it's running
sudo systemctl status myapp
```

### 4. Monitor and Manage

```bash
# View logs (follow mode)
journalctl -u myapp -f

# View last 50 lines
journalctl -u myapp -n 50

# Stop the service
sudo systemctl stop myapp

# Restart the service
sudo systemctl restart myapp

# Check if service is running
sudo systemctl is-active myapp
```

## Service File Template

Use this template and customize for specific needs:

```ini
[Unit]
Description=<Short description of your service>
After=network.target

[Service]
Type=simple
User=<username>
WorkingDirectory=<absolute-path-to-working-directory>
ExecStart=<absolute-path-to-executable-with-args>
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Environment variables (optional)
Environment="PORT=8000"
Environment="NODE_ENV=production"

# Or load from file
EnvironmentFile=/home/exedev/myapp/.env

[Install]
WantedBy=multi-user.target
```

## Key Configuration Options

### Restart Policies
- `Restart=always` - Always restart on exit (recommended for most services)
- `Restart=on-failure` - Only restart on failure
- `Restart=no` - Never restart
- `RestartSec=10` - Wait 10 seconds before restarting

### Service Types
- `Type=simple` - Process runs in foreground (most common)
- `Type=forking` - Process forks to background
- `Type=oneshot` - Process exits after starting

### After Dependencies
- `After=network.target` - Start after network is available
- `After=network-online.target` - Start after network is fully online

## Common Service Examples

### Python Web Application
```ini
[Service]
Type=simple
User=exedev
WorkingDirectory=/home/exedev/webapp
ExecStart=/home/exedev/webapp/.venv/bin/uvicorn app:app --host localhost --port 8000
Restart=always
```

### Node.js Application
```ini
[Service]
Type=simple
User=exedev
WorkingDirectory=/home/exedev/nodeapp
ExecStart=/usr/bin/node /home/exedev/nodeapp/server.js
Restart=always
Environment="NODE_ENV=production"
```

### Background Worker
```ini
[Service]
Type=simple
User=exedev
WorkingDirectory=/home/exedev/worker
ExecStart=/home/exedev/worker/.venv/bin/python worker.py
Restart=always
RestartSec=30
```

## Best Practices

1. **Use Absolute Paths**: Always use absolute paths for `WorkingDirectory` and `ExecStart`
2. **Set Proper User**: Don't run services as root unless necessary
3. **Enable Restart**: Set `Restart=always` for production services
4. **Add Description**: Write clear descriptions for maintenance
5. **Check Logs**: Use `journalctl` to monitor service health
6. **Test First**: Test your command manually before creating the service
7. **Reload After Changes**: Run `sudo systemctl daemon-reload` after editing service files

## Troubleshooting

### Service won't start
```bash
# Check detailed status
sudo systemctl status myapp

# Check recent logs
journalctl -u myapp -n 50

# Check for syntax errors
systemd-analyze verify /etc/systemd/system/myapp.service
```

### Service keeps restarting
```bash
# Check logs for error messages
journalctl -u myapp -f

# Verify the ExecStart command works manually
cd /path/to/working/directory
./your-start-command
```

### Changes not taking effect
```bash
# Always reload after editing service files
sudo systemctl daemon-reload
sudo systemctl restart myapp
```

## Web Service Integration

For web services on exe.dev, combine with the web deployment workflow:
1. Create the systemd service to run on localhost
2. The exe.dev proxy automatically handles HTTPS
3. Service will be available at `https://<vmname>.exe.xyz:<port>/`

Example web service:
```ini
[Service]
ExecStart=/usr/bin/uvicorn app:app --host localhost --port 8000
```
Access at: `https://<vmname>.exe.xyz:8000/`
