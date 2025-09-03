#!/bin/bash

# LMS Project Cleanup Script
# Removes unnecessary files and folders for production deployment

echo "🧹 Starting LMS Project Cleanup..."

# Remove development files
echo "📁 Removing development files..."
rm -f setup.bat
rm -f start-dev.bat
rm -f deploy.ps1
rm -f OPTIMIZATION_SUMMARY.md

# Clean root node_modules (not needed for production)
echo "📦 Removing root node_modules..."
rm -rf node_modules/
rm -f package-lock.json

# Keep essential files:
# - README.md (documentation)
# - API_DOCS.md (API reference)
# - ecosystem.config.json (PM2 config)
# - package.json (for scripts)
# - .gitignore (version control)

# Clean client development files
echo "🎨 Cleaning client development files..."
cd client/
rm -rf node_modules/
rm -f package-lock.json
# Remove build folder to force fresh build
rm -rf build/
cd ..

# Clean server development files  
echo "🖥️ Cleaning server development files..."
cd server/
rm -rf node_modules/
rm -f package-lock.json
cd ..

# Create production environment files if they don't exist
echo "🔧 Creating production environment templates..."

if [ ! -f "server/.env.production" ]; then
cat > server/.env.production << 'EOF'
NODE_ENV=production
PORT=5000
MONGODB_URI=mongodb://localhost:27017/lms_production
JWT_SECRET=your-super-secure-jwt-secret-change-this-in-production
CORS_ORIGIN=http://16.171.146.116
EOF
fi

if [ ! -f "client/.env.production" ]; then
cat > client/.env.production << 'EOF'
REACT_APP_API_URL=http://16.171.146.116:5000
GENERATE_SOURCEMAP=false
EOF
fi

echo "✅ Project cleanup completed!"
echo "📋 Summary:"
echo "   ✓ Removed development batch files"
echo "   ✓ Cleaned node_modules from all directories"
echo "   ✓ Removed lock files (will be regenerated)"
echo "   ✓ Created production environment templates"
echo ""
echo "🚀 Project is ready for deployment!"
