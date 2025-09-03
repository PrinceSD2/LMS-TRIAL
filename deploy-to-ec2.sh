#!/bin/bash

# LMS-TRIAL Deployment Script for Ubuntu EC2
# Server IP: 16.171.146.116
# This script will deploy your MERN stack application

set -e  # Exit on any error

echo "🚀 Starting LMS-TRIAL deployment on Ubuntu EC2..."

# Configuration
SERVER_IP="16.171.146.116"
DOMAIN="16.171.146.116"  # Using IP as domain
PROJECT_DIR="/var/www/lms-trial"
USER="ubuntu"

echo "📍 Deployment Configuration:"
echo "  Server IP: $SERVER_IP"
echo "  Project Directory: $PROJECT_DIR"
echo "  User: $USER"
echo ""

# 1. Update system packages
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# 2. Install Node.js (using NodeSource repository for latest LTS)
echo "📥 Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs

# 3. Install MongoDB
echo "📥 Installing MongoDB..."
curl -fsSL https://pgp.mongodb.com/server-7.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
sudo apt update
sudo apt install -y mongodb-org

# Start and enable MongoDB
sudo systemctl start mongod
sudo systemctl enable mongod

# 4. Install Nginx
echo "📥 Installing Nginx..."
sudo apt install -y nginx

# 5. Install PM2 globally
echo "📥 Installing PM2..."
sudo npm install -g pm2

# 6. Create project directory
echo "📁 Creating project directory..."
sudo mkdir -p $PROJECT_DIR
sudo chown -R $USER:$USER $PROJECT_DIR

# 7. Clone or copy project files (assuming files are already uploaded)
echo "📂 Setting up project files..."
# Note: At this point, you should have already uploaded your project files to $PROJECT_DIR

# 8. Install dependencies and build
cd $PROJECT_DIR

echo "📦 Installing server dependencies..."
cd server
npm ci --only=production

echo "📦 Installing client dependencies and building..."
cd ../client
npm ci
npm run build

# 9. Create PM2 ecosystem file
echo "⚙️ Creating PM2 ecosystem file..."
cd $PROJECT_DIR
cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'lms-trial-backend',
    script: './server/server.js',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production',
      PORT: 5000,
      MONGODB_URI: 'mongodb://localhost:27017/lms-trial',
      JWT_SECRET: 'your-super-secret-jwt-key-change-this-in-production-please',
      JWT_EXPIRE: '30d',
      CORS_ORIGIN: 'http://16.171.146.116'
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true
  }]
};
EOF

# 10. Create logs directory
mkdir -p logs

# 11. Configure Nginx
echo "🌐 Configuring Nginx..."
sudo cat > /etc/nginx/sites-available/lms-trial << 'EOF'
server {
    listen 80;
    server_name 16.171.146.116;

    # Frontend (React app)
    location / {
        root /var/www/lms-trial/client/build;
        index index.html index.htm;
        try_files $uri $uri/ /index.html;
        
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
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 300;
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
    }

    # Socket.IO
    location /socket.io/ {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/javascript
        application/xml+rss
        application/json;
}
EOF

# Enable the site
sudo ln -sf /etc/nginx/sites-available/lms-trial /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test nginx configuration
sudo nginx -t

# 12. Set up firewall
echo "🔒 Configuring firewall..."
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw allow 5000  # Backend port
sudo ufw --force enable

# 13. Start services
echo "🚀 Starting services..."

# Start backend with PM2
pm2 start ecosystem.config.js
pm2 save
pm2 startup

# Restart nginx
sudo systemctl restart nginx
sudo systemctl enable nginx

echo ""
echo "✅ Deployment completed successfully!"
echo ""
echo "🌐 Your application is now available at:"
echo "   Frontend: http://16.171.146.116"
echo "   Backend API: http://16.171.146.116/api"
echo ""
echo "📊 To monitor your application:"
echo "   PM2 Status: pm2 status"
echo "   PM2 Logs: pm2 logs"
echo "   Nginx Status: sudo systemctl status nginx"
echo "   MongoDB Status: sudo systemctl status mongod"
echo ""
echo "🔧 Next steps:"
echo "1. Update the JWT_SECRET in ecosystem.config.js"
echo "2. Set up SSL certificate with Let's Encrypt (optional)"
echo "3. Configure domain name (optional)"
echo "4. Set up backup scripts for MongoDB"
echo ""
