# GitHub Actions Setup Guide

## 🎯 Overview

This guide will help you set up GitHub Actions for automatic deployment to your production server.

## 📋 Prerequisites

1. GitHub repository created
2. Production server with SSH access
3. Server already configured (Nginx, PHP, MySQL, etc.)

## 🔐 Step 1: Generate SSH Key for GitHub Actions

On your **local machine** or **server**, generate a dedicated SSH key for deployments:

```bash
# Generate SSH key (don't use passphrase for automation)
ssh-keygen -t rsa -b 4096 -C "github-actions-deploy" -f ~/.ssh/github_actions_deploy

# This will create:
# - ~/.ssh/github_actions_deploy (private key)
# - ~/.ssh/github_actions_deploy.pub (public key)
```

## 🔑 Step 2: Add Public Key to Server

Copy the **public key** to your server:

```bash
# Copy public key content
cat ~/.ssh/github_actions_deploy.pub

# SSH to your server
ssh user@your-server

# Add the key to authorized_keys
echo "PUBLIC_KEY_CONTENT_HERE" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# Test the connection from your local machine
ssh -i ~/.ssh/github_actions_deploy user@your-server "echo 'Connection successful'"
```

## 🔒 Step 3: Add Secrets to GitHub Repository

Go to your GitHub repository:
1. Click on **Settings**
2. Click on **Secrets and variables** → **Actions**
3. Click **New repository secret**

Add the following secrets:

### Required Secrets:

#### 1. `SSH_PRIVATE_KEY`
```bash
# Copy the ENTIRE private key content (including BEGIN and END lines)
cat ~/.ssh/github_actions_deploy
```
Paste this content as the secret value.

#### 2. `SSH_KNOWN_HOSTS`
```bash
# Get the known hosts entry for your server
ssh-keyscan -H your-server-ip-or-domain
```
Paste the output as the secret value.

#### 3. `SERVER_USER`
Your SSH username (e.g., `ubuntu`, `root`, or your custom user)

#### 4. `SERVER_HOST`
Your server IP address or domain (e.g., `123.45.67.89` or `server.example.com`)

#### 5. `BACKEND_PATH`
Path to backend on server (e.g., `/var/www/api.exquiller.com`)

#### 6. `FRONTEND_PATH`
Path to frontend on server (e.g., `/var/www/exquiller.com`)

## 📸 Secret Configuration Example

```
SECRET NAME          | VALUE
---------------------|----------------------------------------
SSH_PRIVATE_KEY      | -----BEGIN RSA PRIVATE KEY-----
                     | MIIEpAIBAAKCAQEA...
                     | (entire private key)
                     | -----END RSA PRIVATE KEY-----
SSH_KNOWN_HOSTS      | |1|abc123...= ssh-rsa AAAAB3...
SERVER_USER          | ubuntu
SERVER_HOST          | 123.45.67.89
BACKEND_PATH         | /var/www/api.exquiller.com
FRONTEND_PATH        | /var/www/exquiller.com
```

## ✅ Step 4: Test GitHub Actions

### Option 1: Push to Main Branch

```bash
git add .
git commit -m "Test deployment"
git push origin main
```

### Option 2: Manual Trigger

1. Go to your GitHub repository
2. Click on **Actions** tab
3. Click on **Deploy to Production** workflow
4. Click **Run workflow** → **Run workflow**

## 📊 Monitor Deployment

1. Go to **Actions** tab in your GitHub repository
2. Click on the latest workflow run
3. You can see real-time logs for:
   - Backend deployment
   - Frontend deployment
   - Notifications

## 🐛 Troubleshooting

### Error: "Permission denied (publickey)"

**Solution:**
1. Verify the public key is in `~/.ssh/authorized_keys` on the server
2. Check file permissions:
   ```bash
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/authorized_keys
   ```
3. Verify `SSH_PRIVATE_KEY` secret contains the full private key

### Error: "Host key verification failed"

**Solution:**
1. Regenerate `SSH_KNOWN_HOSTS`:
   ```bash
   ssh-keyscan -H your-server-ip > known_hosts.txt
   ```
2. Update the `SSH_KNOWN_HOSTS` secret in GitHub

### Error: "rsync: command not found"

**Solution:**
Install rsync on your server:
```bash
# Ubuntu/Debian
sudo apt-get install rsync

# CentOS/RHEL
sudo yum install rsync
```

### Error: "Composer not found"

**Solution:**
Make sure Composer is in the PATH on your server:
```bash
which composer
# If not found, install it or add to PATH
```

### Deployment succeeds but site shows old version

**Solution:**
1. Clear browser cache
2. SSH to server and verify files:
   ```bash
   ssh user@server
   ls -la /var/www/api.exquiller.com
   ls -la /var/www/exquiller.com
   ```
3. Check Nginx is serving the correct directory
4. Hard refresh browser (Cmd+Shift+R on Mac, Ctrl+Shift+R on Windows)

## 🔄 Workflow Behavior

### Automatic Deployment
- Triggers on every push to `main` branch
- Deploys backend first, then frontend
- Sends status notification

### Manual Deployment
- Can be triggered manually from Actions tab
- Useful for rollbacks or specific deployments

### Deployment Order
1. ✅ Checkout code
2. ✅ Setup environment (PHP, Flutter)
3. ✅ Deploy Backend
   - Pull latest code
   - Install dependencies
   - Run migrations
   - Clear/cache configs
   - Restart services
4. ✅ Deploy Frontend
   - Build Flutter Web
   - Upload to server
5. ✅ Send notification

## 🎯 Best Practices

1. **Test Locally First**
   ```bash
   # Test backend deployment script
   ./deploy-backend.sh

   # Test frontend deployment script
   ./deploy-frontend.sh
   ```

2. **Use Branches**
   - Create feature branches for development
   - Only merge to `main` when ready to deploy
   - Consider adding a `staging` branch for testing

3. **Monitor Logs**
   - Check GitHub Actions logs after each deployment
   - Monitor server logs:
     ```bash
     tail -f /var/www/api.exquiller.com/storage/logs/laravel.log
     tail -f /var/log/nginx/error.log
     ```

4. **Database Backups**
   - Always backup database before major deployments
   - Consider adding automated backups to workflow

5. **Rollback Plan**
   - Keep backup of previous deployment
   - Know how to quickly rollback if needed

## 🚨 Security Notes

- **Never commit** SSH private keys to repository
- **Never commit** `.env` files with production secrets
- **Rotate** SSH keys periodically
- **Use** dedicated deployment user with limited permissions
- **Enable** 2FA on GitHub account
- **Review** deployment logs for suspicious activity

## 📞 Support

If you encounter issues:

1. Check workflow logs in GitHub Actions
2. Check server logs
3. Verify all secrets are correctly set
4. Test SSH connection manually
5. Review DEPLOYMENT_GUIDE.md for manual deployment steps

## 🎉 Success!

Once configured, your deployment workflow will be:

```bash
# Make changes
git add .
git commit -m "Update feature X"
git push origin main

# 🎉 Automatic deployment starts!
# ⏱️ Wait 2-5 minutes
# ✅ Visit https://exquiller.com to see changes
```

That's it! Your CI/CD pipeline is ready! 🚀
