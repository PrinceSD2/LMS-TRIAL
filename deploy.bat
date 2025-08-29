@echo off
echo ====================================
echo 🚀 LMS Automated EC2 Deployment
echo ====================================

set PEM_KEY=C:\Users\int0003\Desktop\RGLMS.pem
set EC2_IP=16.170.227.75
set GIT_TOKEN=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

echo Target EC2: %EC2_IP%
echo Using PEM key: %PEM_KEY%
echo.

REM Check if PEM key exists
if not exist "%PEM_KEY%" (
    echo ❌ Error: PEM key not found at %PEM_KEY%
    pause
    exit /b 1
)

echo ✅ PEM key found
echo 🔧 Setting PEM key permissions...

REM Set PEM key permissions
icacls "%PEM_KEY%" /inheritance:r >nul 2>&1
icacls "%PEM_KEY%" /grant:r "%USERNAME%:R" >nul 2>&1

echo ✅ PEM key permissions set
echo.

echo 🚀 Starting deployment to EC2...
echo 📡 Connecting to EC2 and running deployment...

REM Create a temporary deployment script
echo #!/bin/bash > deploy_temp.sh
echo set -e >> deploy_temp.sh
echo. >> deploy_temp.sh
echo echo "🚀 Starting LMS Deployment on EC2..." >> deploy_temp.sh
echo echo "Timestamp: $(date)" >> deploy_temp.sh
echo. >> deploy_temp.sh
echo # Update system >> deploy_temp.sh
echo echo "📦 Updating system packages..." >> deploy_temp.sh
echo sudo apt-get update -y >> deploy_temp.sh
echo. >> deploy_temp.sh
echo # Install Node.js 18.x >> deploy_temp.sh
echo echo "📦 Installing Node.js..." >> deploy_temp.sh
echo if ! command -v node ^&^> /dev/null; then >> deploy_temp.sh
echo     curl -fsSL https://deb.nodesource.com/setup_18.x ^| sudo -E bash - >> deploy_temp.sh
echo     sudo apt-get install -y nodejs >> deploy_temp.sh
echo else >> deploy_temp.sh
echo     echo "Node.js already installed: $(node --version)" >> deploy_temp.sh
echo fi >> deploy_temp.sh
echo. >> deploy_temp.sh
echo # Install PM2 globally >> deploy_temp.sh
echo echo "📦 Installing PM2..." >> deploy_temp.sh
echo if ! command -v pm2 ^&^> /dev/null; then >> deploy_temp.sh
echo     sudo npm install -g pm2 >> deploy_temp.sh
echo else >> deploy_temp.sh
echo     echo "PM2 already installed" >> deploy_temp.sh
echo fi >> deploy_temp.sh
echo. >> deploy_temp.sh
echo # Install Git if not present >> deploy_temp.sh
echo echo "📦 Installing Git..." >> deploy_temp.sh
echo if ! command -v git ^&^> /dev/null; then >> deploy_temp.sh
echo     sudo apt-get install -y git >> deploy_temp.sh
echo else >> deploy_temp.sh
echo     echo "Git already installed: $(git --version)" >> deploy_temp.sh
echo fi >> deploy_temp.sh
echo. >> deploy_temp.sh
echo # Remove existing project directory >> deploy_temp.sh
echo echo "🧹 Cleaning up existing deployment..." >> deploy_temp.sh
echo rm -rf LMS-TRIAL >> deploy_temp.sh
echo. >> deploy_temp.sh
echo # Clone the repository >> deploy_temp.sh
echo echo "📥 Cloning repository from GitHub..." >> deploy_temp.sh
echo git clone https://%GIT_TOKEN%@github.com/PrinceSD2/LMS-TRIAL.git >> deploy_temp.sh
echo cd LMS-TRIAL >> deploy_temp.sh
echo. >> deploy_temp.sh
echo # Install root dependencies >> deploy_temp.sh
echo echo "📦 Installing root dependencies..." >> deploy_temp.sh
echo npm install >> deploy_temp.sh
echo. >> deploy_temp.sh
echo # Install and setup server >> deploy_temp.sh
echo echo "📦 Setting up server..." >> deploy_temp.sh
echo cd server >> deploy_temp.sh
echo npm install >> deploy_temp.sh
echo. >> deploy_temp.sh
echo # Create server production environment >> deploy_temp.sh
echo echo "🔧 Creating server .env file..." >> deploy_temp.sh
echo cat ^> .env ^<^< 'EOF' >> deploy_temp.sh
echo MONGODB_URI=mongodb+srv://rglms10:RGLMS123@lmsdatabase.jo25hav.mongodb.net/LMSdata+ >> deploy_temp.sh
echo JWT_SECRET=LMSSECRETKEY >> deploy_temp.sh
echo PORT=5000 >> deploy_temp.sh
echo NODE_ENV=production >> deploy_temp.sh
echo EOF >> deploy_temp.sh
echo. >> deploy_temp.sh
echo # Create logs directory >> deploy_temp.sh
echo mkdir -p logs >> deploy_temp.sh
echo cd .. >> deploy_temp.sh
echo. >> deploy_temp.sh
echo # Install and build client >> deploy_temp.sh
echo echo "📦 Setting up client..." >> deploy_temp.sh
echo cd client >> deploy_temp.sh
echo npm install >> deploy_temp.sh
echo. >> deploy_temp.sh
echo # Create client production environment >> deploy_temp.sh
echo echo "🔧 Creating client .env file..." >> deploy_temp.sh
echo cat ^> .env ^<^< 'EOF' >> deploy_temp.sh
echo REACT_APP_API_URL=http://16.170.227.75:5000 >> deploy_temp.sh
echo EOF >> deploy_temp.sh
echo. >> deploy_temp.sh
echo # Build React app >> deploy_temp.sh
echo echo "🏗️ Building React application..." >> deploy_temp.sh
echo npm run build >> deploy_temp.sh
echo cd .. >> deploy_temp.sh
echo. >> deploy_temp.sh
echo # Stop existing PM2 processes >> deploy_temp.sh
echo echo "🛑 Stopping existing processes..." >> deploy_temp.sh
echo pm2 stop all 2^>/dev/null ^|^| true >> deploy_temp.sh
echo pm2 delete all 2^>/dev/null ^|^| true >> deploy_temp.sh
echo. >> deploy_temp.sh
echo # Start the application >> deploy_temp.sh
echo echo "🚀 Starting application with PM2..." >> deploy_temp.sh
echo cd server >> deploy_temp.sh
echo pm2 start server.js --name "lms-backend" --env production >> deploy_temp.sh
echo. >> deploy_temp.sh
echo # Configure PM2 >> deploy_temp.sh
echo pm2 save >> deploy_temp.sh
echo pm2 startup ^| grep "sudo" ^| bash 2^>/dev/null ^|^| true >> deploy_temp.sh
echo. >> deploy_temp.sh
echo # Wait a moment for startup >> deploy_temp.sh
echo sleep 3 >> deploy_temp.sh
echo. >> deploy_temp.sh
echo # Check status >> deploy_temp.sh
echo echo "📊 Application status:" >> deploy_temp.sh
echo pm2 list >> deploy_temp.sh
echo. >> deploy_temp.sh
echo # Test the application >> deploy_temp.sh
echo echo "🧪 Testing application..." >> deploy_temp.sh
echo sleep 2 >> deploy_temp.sh
echo curl -f http://localhost:5000/api/health 2^>/dev/null ^&^& echo "✅ API health check passed" ^|^| echo "⚠️ API health check failed" >> deploy_temp.sh
echo. >> deploy_temp.sh
echo echo "" >> deploy_temp.sh
echo echo "=====================================" >> deploy_temp.sh
echo echo "✅ DEPLOYMENT COMPLETED SUCCESSFULLY!" >> deploy_temp.sh
echo echo "=====================================" >> deploy_temp.sh
echo echo "🌐 Application URL: http://16.170.227.75:5000" >> deploy_temp.sh
echo echo "🔗 API Health: http://16.170.227.75:5000/api/health" >> deploy_temp.sh
echo echo "" >> deploy_temp.sh
echo echo "📋 Management Commands:" >> deploy_temp.sh
echo echo "• View logs: pm2 logs lms-backend" >> deploy_temp.sh
echo echo "• Restart: pm2 restart lms-backend" >> deploy_temp.sh
echo echo "• Stop: pm2 stop lms-backend" >> deploy_temp.sh
echo echo "• Monitor: pm2 monit" >> deploy_temp.sh

REM Upload and execute the script
scp -o StrictHostKeyChecking=no -i "%PEM_KEY%" deploy_temp.sh ubuntu@%EC2_IP%:~/deploy.sh
ssh -o StrictHostKeyChecking=no -i "%PEM_KEY%" ubuntu@%EC2_IP% "chmod +x deploy.sh && ./deploy.sh"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ====================================
    echo 🎉 DEPLOYMENT COMPLETED!
    echo ====================================
    echo 🌐 Your LMS application is now live at:
    echo    http://%EC2_IP%:5000
    echo.
    echo 🔗 API Health Check:
    echo    http://%EC2_IP%:5000/api/health
    echo.
    echo 📋 To manage your application:
    echo    ssh -i "%PEM_KEY%" ubuntu@%EC2_IP%
    echo    pm2 logs lms-backend    # View logs
    echo    pm2 restart lms-backend # Restart app
    echo    pm2 monit              # Monitor resources
) else (
    echo.
    echo ❌ DEPLOYMENT FAILED
    echo.
    echo 🔧 Troubleshooting:
    echo 1. Check if EC2 instance is running in AWS Console
    echo 2. Verify security group allows:
    echo    - Port 22 (SSH)
    echo    - Port 5000 (Application)
    echo 3. Test SSH connection manually:
    echo    ssh -i "%PEM_KEY%" ubuntu@%EC2_IP%
)

REM Clean up
del deploy_temp.sh 2>nul

pause
