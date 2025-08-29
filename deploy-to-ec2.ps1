# Automated EC2 Deployment Script for LMS System
# This script will deploy the entire LMS project to EC2 instance

param(
    [string]$PemKeyPath = "C:\Users\int0003\Desktop\RGLMS.pem",
    [string]$EC2IP = "16.170.227.75",
    [string]$GitRepo = "https://github.com/PrinceSD2/LMS-TRIAL.git",
    [string]$GitToken = "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"
)

Write-Host "====================================" -ForegroundColor Green
Write-Host "🚀 LMS Automated EC2 Deployment" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green
Write-Host "Target EC2: $EC2IP" -ForegroundColor Cyan
Write-Host "PEM Key: $PemKeyPath" -ForegroundColor Cyan
Write-Host ""

# Check if PEM key exists
if (!(Test-Path $PemKeyPath)) {
    Write-Host "❌ Error: PEM key not found at $PemKeyPath" -ForegroundColor Red
    exit 1
}

Write-Host "✅ PEM key found" -ForegroundColor Green

# Set correct permissions for PEM key (required for SSH)
Write-Host "🔧 Setting PEM key permissions..." -ForegroundColor Yellow
icacls $PemKeyPath /inheritance:r
icacls $PemKeyPath /grant:r "$($env:USERNAME):R"

# Create deployment script to run on EC2
$DeploymentScript = @"
#!/bin/bash
set -e

echo "🚀 Starting LMS Deployment on EC2..."

# Update system
echo "📦 Updating system packages..."
sudo apt-get update -y

# Install Node.js 18.x
echo "📦 Installing Node.js..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# Install PM2 globally
echo "📦 Installing PM2..."
if ! command -v pm2 &> /dev/null; then
    sudo npm install -g pm2
fi

# Install Git if not present
echo "📦 Installing Git..."
if ! command -v git &> /dev/null; then
    sudo apt-get install -y git
fi

# Remove existing project directory if it exists
echo "🧹 Cleaning up existing deployment..."
if [ -d "LMS-TRIAL" ]; then
    rm -rf LMS-TRIAL
fi

# Clone the repository with token authentication
echo "📥 Cloning repository..."
git clone https://$GitToken@github.com/PrinceSD2/LMS-TRIAL.git
cd LMS-TRIAL

# Install dependencies
echo "📦 Installing project dependencies..."
npm install

# Install server dependencies
echo "📦 Installing server dependencies..."
cd server
npm install
cd ..

# Install client dependencies
echo "📦 Installing client dependencies..."
cd client
npm install

# Create production environment file for client
echo "🔧 Setting up client production environment..."
cat > .env << EOF
REACT_APP_API_URL=http://16.170.227.75:5000
EOF

# Build React app for production
echo "🏗️ Building React application..."
npm run build
cd ..

# Create production environment file for server
echo "🔧 Setting up server production environment..."
cd server
cat > .env << EOF
MONGODB_URI=mongodb+srv://rglms10:RGLMS123@lmsdatabase.jo25hav.mongodb.net/LMSdata+
JWT_SECRET=LMSSECRETKEY
PORT=5000
NODE_ENV=production
EOF

# Create logs directory for PM2
mkdir -p logs

# Stop any existing PM2 processes
echo "🛑 Stopping existing processes..."
pm2 stop all || true
pm2 delete all || true

# Start the application with PM2
echo "🚀 Starting application with PM2..."
pm2 start server.js --name "lms-backend" --env production

# Save PM2 configuration
pm2 save

# Setup PM2 to start on boot
pm2 startup | grep "sudo" | bash || true

# Check if application is running
sleep 5
echo "🔍 Checking application status..."
pm2 list

# Test the API endpoint
echo "🧪 Testing API endpoint..."
curl -f http://localhost:5000/api/health || echo "⚠️ API health check failed"

echo ""
echo "✅ Deployment completed successfully!"
echo "📍 Application accessible at: http://16.170.227.75:5000"
echo "📊 Monitor with: pm2 monit"
echo "📝 View logs with: pm2 logs lms-backend"
"@

# Save the deployment script to a temporary file
$TempScript = "$env:TEMP\deploy-lms.sh"
$DeploymentScript | Out-File -FilePath $TempScript -Encoding UTF8

Write-Host "🔧 Connecting to EC2 and starting deployment..." -ForegroundColor Yellow

# Execute the deployment on EC2
try {
    # Copy the deployment script to EC2
    Write-Host "📤 Uploading deployment script..." -ForegroundColor Yellow
    & scp -o StrictHostKeyChecking=no -i $PemKeyPath $TempScript ubuntu@${EC2IP}:~/deploy-lms.sh

    # Make the script executable and run it
    Write-Host "▶️ Executing deployment on EC2..." -ForegroundColor Yellow
    & ssh -o StrictHostKeyChecking=no -i $PemKeyPath ubuntu@$EC2IP "chmod +x deploy-lms.sh && ./deploy-lms.sh"

    Write-Host ""
    Write-Host "====================================" -ForegroundColor Green
    Write-Host "🎉 DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
    Write-Host "====================================" -ForegroundColor Green
    Write-Host "🌐 Application URL: http://$EC2IP:5000" -ForegroundColor Cyan
    Write-Host "🔗 API Health Check: http://$EC2IP:5000/api/health" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📋 Next Steps:" -ForegroundColor Yellow
    Write-Host "1. Open your browser and navigate to http://$EC2IP:5000"
    Write-Host "2. The application should be fully functional"
    Write-Host "3. Check logs if needed: ssh -i $PemKeyPath ubuntu@$EC2IP 'pm2 logs'"
    Write-Host ""

} catch {
    Write-Host "❌ Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "💡 Troubleshooting steps:" -ForegroundColor Yellow
    Write-Host "1. Verify EC2 instance is running"
    Write-Host "2. Check security group allows SSH (port 22) and HTTP (port 5000)"
    Write-Host "3. Ensure PEM key has correct permissions"
    Write-Host "4. Try connecting manually: ssh -i $PemKeyPath ubuntu@$EC2IP"
} finally {
    # Clean up temporary file
    Remove-Item $TempScript -ErrorAction SilentlyContinue
}
