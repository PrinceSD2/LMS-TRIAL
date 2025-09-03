#!/bin/bash

# Auto-Deploy Script for LMS-TRIAL
# This script handles automatic deployment of updates

set -e

echo "🔄 Starting auto-deployment for LMS-TRIAL..."

PROJECT_DIR="/var/www/lms-trial"
BACKUP_DIR="/var/backups/lms-trial"
DATE=$(date +%Y%m%d_%H%M%S)

# Function to rollback on failure
rollback() {
    echo "❌ Deployment failed! Rolling back..."
    if [ -d "$BACKUP_DIR/backup_$DATE" ]; then
        sudo rm -rf $PROJECT_DIR
        sudo mv $BACKUP_DIR/backup_$DATE $PROJECT_DIR
        pm2 restart lms-trial-backend
        sudo systemctl reload nginx
        echo "🔙 Rollback completed!"
    fi
    exit 1
}

# Set trap for rollback on error
trap rollback ERR

echo "📋 Pre-deployment checks..."

# Check if services are running
if ! pm2 describe lms-trial-backend > /dev/null 2>&1; then
    echo "❌ Backend service not running!"
    exit 1
fi

if ! sudo systemctl is-active --quiet nginx; then
    echo "❌ Nginx service not running!"
    exit 1
fi

# Create backup
echo "💾 Creating backup..."
sudo mkdir -p $BACKUP_DIR
sudo cp -r $PROJECT_DIR $BACKUP_DIR/backup_$DATE

echo "📥 Pulling latest changes..."
cd $PROJECT_DIR

# If using Git (uncomment if you set up Git deployment)
# git pull origin main

echo "📦 Installing/updating dependencies..."

# Update server dependencies
cd server
npm ci --only=production

# Update and rebuild client
cd ../client
npm ci
npm run build

echo "🔄 Restarting services..."

# Restart backend
pm2 restart lms-trial-backend

# Wait for backend to start
sleep 5

# Test backend health
if ! curl -f http://localhost:5000/api/health > /dev/null 2>&1; then
    echo "❌ Backend health check failed!"
    rollback
fi

# Reload nginx
sudo systemctl reload nginx

# Test frontend
if ! curl -f http://localhost > /dev/null 2>&1; then
    echo "❌ Frontend health check failed!"
    rollback
fi

echo "🧹 Cleaning up old backups (keeping last 5)..."
cd $BACKUP_DIR
ls -t | tail -n +6 | xargs -r sudo rm -rf

echo ""
echo "✅ Auto-deployment completed successfully!"
echo "📊 Service Status:"
pm2 status
echo ""
echo "🌐 Application is running at: http://16.171.146.116"
echo ""
