#!/bin/bash

# LMS Auto-Deployment Script for Updates
# Use this script for future deployments after initial setup

set -e

SERVER_IP="16.171.146.116"
APP_DIR="/var/www/lms"
BACKUP_DIR="/var/backups/lms"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run this script as root (use sudo)"
    exit 1
fi

print_status "🔄 Starting LMS Auto-Deployment..."

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup current version
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
print_status "📦 Creating backup..."
cp -r $APP_DIR/lms-system $BACKUP_DIR/lms-system-$TIMESTAMP

# Navigate to app directory
cd $APP_DIR/lms-system

# Pull latest changes (if using git)
if [ -d ".git" ]; then
    print_status "📥 Pulling latest changes from git..."
    git pull origin main
else
    print_warning "Git repository not found. Please manually update files."
    read -p "Press enter when files are updated..."
fi

# Install/update backend dependencies
print_status "📦 Updating backend dependencies..."
cd server
npm install --production
cd ..

# Build frontend
print_status "🎨 Building frontend..."
cd client
npm install
npm run build
cd ..

# Set proper permissions for frontend files
chown -R www-data:www-data client/build
chmod -R 755 client/build

# Restart PM2 application
print_status "🔄 Restarting backend application..."
pm2 restart lms-backend

# Wait for application to start
sleep 5

# Test if backend is responding
print_status "🧪 Testing backend health..."
if curl -f http://localhost:5000/api/auth/health >/dev/null 2>&1; then
    print_status "✅ Backend is responding"
else
    print_warning "⚠️  Backend health check failed, but continuing..."
fi

# Reload Nginx to pick up any changes
print_status "🔄 Reloading Nginx..."
nginx -t && systemctl reload nginx

# Clean old backups (keep only last 5)
print_status "🧹 Cleaning old backups..."
cd $BACKUP_DIR
ls -t | tail -n +6 | xargs -r rm -rf

print_status "✅ Auto-deployment completed successfully!"
echo ""
echo "📊 Deployment Status:"
echo "   Backend Status: $(pm2 jlist | jq -r '.[] | select(.name=="lms-backend") | .pm2_env.status')"
echo "   Nginx Status: $(systemctl is-active nginx)"
echo "   MongoDB Status: $(systemctl is-active mongod)"
echo ""
print_status "🌐 Application is running at: http://$SERVER_IP"
