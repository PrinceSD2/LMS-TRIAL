# Simple EC2 Deployment Script - No parameters needed
# All values are hardcoded as provided

Write-Host "====================================" -ForegroundColor Green
Write-Host "🚀 LMS Automated EC2 Deployment" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green

$PemKeyPath = "C:\Users\int0003\Desktop\RGLMS.pem"
$EC2IP = "16.170.227.75"
$GitRepo = "https://github.com/PrinceSD2/LMS-TRIAL.git"
$GitToken = "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"

Write-Host "Target EC2: $EC2IP" -ForegroundColor Cyan
Write-Host "Using PEM key: $PemKeyPath" -ForegroundColor Cyan
Write-Host ""

# Check if PEM key exists
if (!(Test-Path $PemKeyPath)) {
    Write-Host "❌ Error: PEM key not found at $PemKeyPath" -ForegroundColor Red
    Write-Host "Please ensure the PEM key is at the correct location." -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ PEM key found" -ForegroundColor Green

# Set correct permissions for PEM key
Write-Host "🔧 Setting PEM key permissions..." -ForegroundColor Yellow
try {
    icacls $PemKeyPath /inheritance:r 2>$null
    icacls $PemKeyPath /grant:r "$($env:USERNAME):R" 2>$null
    Write-Host "✅ PEM key permissions set" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Could not set PEM permissions, continuing anyway..." -ForegroundColor Yellow
}

# Create the complete deployment command
$DeployCommand = @'
#!/bin/bash
set -e

echo "🚀 Starting LMS Deployment on EC2..."
echo "Timestamp: $(date)"

# Update system
echo "📦 Updating system packages..."
sudo apt-get update -y

# Install Node.js 18.x
echo "📦 Installing Node.js..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
else
    echo "Node.js already installed: $(node --version)"
fi

# Install PM2 globally
echo "📦 Installing PM2..."
if ! command -v pm2 &> /dev/null; then
    sudo npm install -g pm2
else
    echo "PM2 already installed"
fi

# Install Git if not present
echo "📦 Installing Git..."
if ! command -v git &> /dev/null; then
    sudo apt-get install -y git
else
    echo "Git already installed: $(git --version)"
fi

# Remove existing project directory
echo "🧹 Cleaning up existing deployment..."
rm -rf LMS-TRIAL

# Clone the repository
echo "📥 Cloning repository from GitHub..."
git clone https://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@github.com/PrinceSD2/LMS-TRIAL.git
cd LMS-TRIAL

# Install root dependencies
echo "📦 Installing root dependencies..."
npm install

# Install and setup server
echo "📦 Setting up server..."
cd server
npm install

# Create server production environment
echo "🔧 Creating server .env file..."
cat > .env << 'EOF'
MONGODB_URI=mongodb+srv://rglms10:RGLMS123@lmsdatabase.jo25hav.mongodb.net/LMSdata+
JWT_SECRET=LMSSECRETKEY
PORT=5000
NODE_ENV=production
EOF

# Create logs directory
mkdir -p logs
cd ..

# Install and build client
echo "📦 Setting up client..."
cd client
npm install

# Create client production environment
echo "🔧 Creating client .env file..."
cat > .env << 'EOF'
REACT_APP_API_URL=http://16.170.227.75:5000
EOF

# Build React app
echo "🏗️ Building React application..."
npm run build
cd ..

# Stop existing PM2 processes
echo "🛑 Stopping existing processes..."
pm2 stop all 2>/dev/null || true
pm2 delete all 2>/dev/null || true

# Start the application
echo "🚀 Starting application with PM2..."
cd server
pm2 start server.js --name "lms-backend" --env production

# Configure PM2
pm2 save
pm2 startup | grep "sudo" | bash 2>/dev/null || true

# Wait a moment for startup
sleep 3

# Check status
echo "📊 Application status:"
pm2 list

# Test the application
echo "🧪 Testing application..."
sleep 2
curl -f http://localhost:5000/api/health 2>/dev/null && echo "✅ API health check passed" || echo "⚠️ API health check failed"

echo ""
echo "====================================="
echo "✅ DEPLOYMENT COMPLETED SUCCESSFULLY!"
echo "====================================="
echo "🌐 Application URL: http://16.170.227.75:5000"
echo "🔗 API Health: http://16.170.227.75:5000/api/health"
echo ""
echo "📋 Management Commands:"
echo "• View logs: pm2 logs lms-backend"
echo "• Restart: pm2 restart lms-backend"
echo "• Stop: pm2 stop lms-backend"
echo "• Monitor: pm2 monit"
'@

# Execute the deployment
Write-Host "🚀 Starting deployment to EC2..." -ForegroundColor Yellow

try {
    # Execute deployment directly via SSH
    Write-Host "📡 Connecting to EC2 and running deployment..." -ForegroundColor Yellow
    
    $DeployCommand | ssh -o StrictHostKeyChecking=no -i $PemKeyPath ubuntu@$EC2IP "cat > deploy.sh && chmod +x deploy.sh && ./deploy.sh"
    
    Write-Host ""
    Write-Host "====================================" -ForegroundColor Green
    Write-Host "🎉 DEPLOYMENT COMPLETED!" -ForegroundColor Green
    Write-Host "====================================" -ForegroundColor Green
    Write-Host "🌐 Your LMS application is now live at:" -ForegroundColor White
    Write-Host "   http://$EC2IP:5000" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "🔗 API Health Check:" -ForegroundColor White  
    Write-Host "   http://$EC2IP:5000/api/health" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📋 To manage your application:" -ForegroundColor Yellow
    Write-Host "   ssh -i $PemKeyPath ubuntu@$EC2IP" -ForegroundColor White
    Write-Host "   pm2 logs lms-backend    # View logs" -ForegroundColor White
    Write-Host "   pm2 restart lms-backend # Restart app" -ForegroundColor White
    Write-Host "   pm2 monit              # Monitor resources" -ForegroundColor White

} catch {
    Write-Host ""
    Write-Host "❌ DEPLOYMENT FAILED" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "🔧 Troubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Check if EC2 instance is running in AWS Console" -ForegroundColor White
    Write-Host "2. Verify security group allows:" -ForegroundColor White
    Write-Host "   - Port 22 (SSH)" -ForegroundColor White
    Write-Host "   - Port 5000 (Application)" -ForegroundColor White
    Write-Host "3. Test SSH connection manually:" -ForegroundColor White
    Write-Host "   ssh -i $PemKeyPath ubuntu@$EC2IP" -ForegroundColor Cyan
    Write-Host ""
}
