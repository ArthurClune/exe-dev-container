---
name: exe-web-deploy
description: Deploy web applications on exe.dev VMs with automatic HTTPS proxy. Use when the user wants to run a web server, deploy a web app, or make their application accessible via HTTPS.
---

# exe.dev Web Deployment Skill

This skill helps you deploy web applications on exe.dev VMs with automatic HTTPS proxying.

## How exe.dev HTTP Proxy Works

- **Ports 3000-9999** are automatically proxied to HTTPS
- Access at `https://<vmname>.exe.xyz:<port>/`
- Port 80 is proxied to `https://<vmname>.exe.xyz/`
- **Default recommendation**: Use port 8000

## Deployment Workflow

When deploying a web application, follow this workflow:

### 1. Determine the VM Name
Check the hostname to determine the public URL:
```bash
hostname
```

### 2. Start the Server on Localhost
Always bind to `localhost` or `127.0.0.1`, never `0.0.0.0`:
- **Python**: `uvicorn app:app --host localhost --port 8000`
- **Node.js**: `app.listen(8000, 'localhost')`
- **Flask**: `app.run(host='localhost', port=8000)`
- **Other**: Configure to bind to `localhost:<port>`

### 3. Provide the Public URL
After starting the server, immediately provide the user with the public URL:
```
Your app is running at: https://<vmname>.exe.xyz:8000/
```

### 4. Make Public (Optional)
By default, sites require exe.dev login. To make public:
```bash
ssh exe.dev share set-public <vmname>
```

## Best Practices

1. **Port Selection**: Use port 8000 as default unless the user specifies otherwise
2. **Localhost Binding**: Always bind to localhost, not 0.0.0.0
3. **Public URLs**: Always provide the full `https://<vmname>.exe.xyz:<port>/` URL
4. **Testing**: After deployment, verify the app is accessible
5. **Security**: Warn users before making sites public

## Common Scenarios

### Static File Server
```bash
python3 -m http.server 8000 --bind localhost
# Access at: https://<vmname>.exe.xyz:8000/
```

### Python FastAPI/Flask
```bash
uvicorn main:app --host localhost --port 8000 --reload
# Access at: https://<vmname>.exe.xyz:8000/
```

### Node.js/Express
```javascript
app.listen(8000, 'localhost', () => {
  console.log('Server running on localhost:8000');
});
// Access at: https://<vmname>.exe.xyz:8000/
```

### Vite/React Dev Server
```bash
npm run dev -- --host localhost --port 8000
# Access at: https://<vmname>.exe.xyz:8000/
```

## Authentication Headers

When users are authenticated, your app receives these headers:
- `X-ExeDev-UserID` - Stable unique user ID
- `X-ExeDev-Email` - User's email address

Trigger login flow with: `/__exe.dev/login?redirect=/path`

## Troubleshooting

- **Connection refused**: Check if server is running on localhost
- **404 Not Found**: Verify the port is in range 3000-9999 or is port 80
- **Can't access**: Check if server crashed or binding failed
- **Need authentication**: Sites are private by default, use `ssh exe.dev share set-public` to make public
