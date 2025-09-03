#!/bin/bash

# Quick Deployment Summary Script
# Run this after deployment to verify everything is working

echo "🔍 LMS-TRIAL Deployment Verification"
echo "====================================="

# Check PM2 status
echo ""
echo "📊 PM2 Process Status:"
pm2 status

# Check Nginx status
echo ""
echo "🌐 Nginx Status:"
sudo systemctl status nginx --no-pager -l

# Check MongoDB status
echo ""
echo "🗄️  MongoDB Status:"
sudo systemctl status mongod --no-pager -l

# Test backend health
echo ""
echo "🔧 Backend Health Check:"
curl -f http://localhost:5000/api/health 2>/dev/null && echo "✅ Backend is healthy" || echo "❌ Backend health check failed"

# Test frontend
echo ""
echo "🎨 Frontend Check:"
curl -f http://localhost 2>/dev/null && echo "✅ Frontend is accessible" || echo "❌ Frontend check failed"

# Check disk space
echo ""
echo "💾 Disk Space:"
df -h /

# Check memory usage
echo ""
echo "🧠 Memory Usage:"
free -h

# Check recent logs
echo ""
echo "📋 Recent PM2 Logs (last 10 lines):"
pm2 logs --lines 10

echo ""
echo "🌐 Your application should be accessible at:"
echo "   Frontend: http://16.171.146.116"
echo "   Backend API: http://16.171.146.116/api"
echo ""
echo "🔧 Useful commands:"
echo "   pm2 status                    - Check app status"
echo "   pm2 logs lms-trial-backend   - View app logs"
echo "   pm2 restart lms-trial-backend - Restart app"
echo "   sudo systemctl status nginx  - Check nginx status"
echo "   sudo systemctl status mongod - Check MongoDB status"
echo ""
