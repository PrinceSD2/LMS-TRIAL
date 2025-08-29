Write-Host "====================================" -ForegroundColor Green
Write-Host "LMS Deployment Script for EC2" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green
Write-Host

# Set production environment
$env:NODE_ENV = "production"

Write-Host "Building React app for production..." -ForegroundColor Yellow
Set-Location client
npm run build
Set-Location ..

Write-Host "Copying production environment files..." -ForegroundColor Yellow
Copy-Item "server\.env.production" "server\.env" -Force
Copy-Item "client\.env.production" "client\.env" -Force

Write-Host "Starting server in production mode..." -ForegroundColor Yellow
Set-Location server
Start-Process -FilePath "npm" -ArgumentList "start" -NoNewWindow

Write-Host "====================================" -ForegroundColor Green
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "Application should be running on:" -ForegroundColor Cyan
Write-Host "Backend API: http://16.170.227.75:5000" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Green
