#!/bin/bash

# LMS Production Deployment Script for EC2
# Target IP: 16.171.146.116
# Deploys backend with PM2, frontend with Nginx

set -e  # Exit on any error

SERVER_IP="16.171.146.116"
PROJECT_NAME="lms-system"
APP_DIR="/var/www/lms"
DOMAIN_OR_IP="16.171.146.116"

echo "🚀 Starting LMS Deployment to $SERVER_IP"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
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

print_status "Installing system dependencies..."

# Update system
apt update && apt upgrade -y

# Install Node.js 18 LTS
print_status "Installing Node.js 18 LTS..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# Install other dependencies
apt install -y nginx mongodb git

# Install PM2 globally
npm install -g pm2

# Create application directory
print_status "Creating application directory..."
mkdir -p $APP_DIR
cd $APP_DIR

# If this is not the first deployment, backup current version
if [ -d "lms-system" ]; then
    print_status "Backing up current version..."
    mv lms-system lms-system-backup-$(date +%Y%m%d_%H%M%S)
fi

# Clone or copy application (assuming local deployment)
print_status "Setting up application files..."
# If deploying from local machine, you would copy files here
# For now, we'll assume files are already copied to $APP_DIR

# Create directory structure
mkdir -p lms-system
cd lms-system

print_status "Installing backend dependencies..."
cd server
npm install --production
cd ..

print_status "Building frontend..."
cd client
npm install
npm run build
cd ..

# Set up environment files
print_status "Setting up environment configuration..."

# Backend environment
cat > server/.env << EOF
NODE_ENV=production
PORT=5000
MONGODB_URI=mongodb://localhost:27017/lms_production
JWT_SECRET=$(openssl rand -base64 32)
CORS_ORIGIN=http://$DOMAIN_OR_IP
EOF

print_status "Starting MongoDB service..."
systemctl start mongod
systemctl enable mongod

# Wait for MongoDB to start
sleep 5

print_status "Setting up PM2 configuration..."
cat > ecosystem.config.js << EOF
module.exports = {
  apps: [
    {
      name: 'lms-backend',
      script: './server/server.js',
      cwd: '$APP_DIR/lms-system',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      env: {
        NODE_ENV: 'production',
        PORT: 5000
      },
      error_file: '/var/log/pm2/lms-backend.error.log',
      out_file: '/var/log/pm2/lms-backend.out.log',
      log_file: '/var/log/pm2/lms-backend.log'
    }
  ]
};
EOF

# Create PM2 log directory
mkdir -p /var/log/pm2

print_status "Starting backend with PM2..."
pm2 start ecosystem.config.js
pm2 save
pm2 startup

print_status "Configuring Nginx..."

# Backup default nginx config
cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.backup

# Create Nginx configuration
cat > /etc/nginx/sites-available/lms << EOF
server {
    listen 80;
    server_name $DOMAIN_OR_IP;

    # Frontend - React build files
    location / {
        root $APP_DIR/lms-system/client/build;
        index index.html index.htm;
        try_files \$uri \$uri/ /index.html;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }

    # Backend API
    location /api/ {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }

    # Socket.IO for real-time features
    location /socket.io/ {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # Gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
}
EOF

# Enable the site
ln -sf /etc/nginx/sites-available/lms /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test nginx configuration
nginx -t

print_status "Starting Nginx..."
systemctl restart nginx
systemctl enable nginx

# Set proper permissions
chown -R www-data:www-data $APP_DIR/lms-system/client/build
chmod -R 755 $APP_DIR/lms-system/client/build

print_status "Setting up firewall..."
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

print_status "Creating deployment completion marker..."
echo "$(date): LMS System deployed successfully" > $APP_DIR/deployment.log

print_status "🎉 Deployment completed successfully!"
echo ""
echo "📋 Deployment Summary:"
echo "   🌐 Frontend: http://$DOMAIN_OR_IP"
echo "   🔧 Backend API: http://$DOMAIN_OR_IP/api"
echo "   📁 App Directory: $APP_DIR/lms-system"
echo "   🔄 PM2 Process: lms-backend"
echo ""
echo "🔍 Useful Commands:"
echo "   pm2 status                    # Check backend status"
echo "   pm2 logs lms-backend          # View backend logs"
echo "   pm2 restart lms-backend       # Restart backend"
echo "   systemctl status nginx        # Check nginx status"
echo "   systemctl status mongod       # Check MongoDB status"
echo ""
echo "✅ Your LMS system is now live at: http://$DOMAIN_OR_IP"
