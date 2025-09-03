#!/bin/bash

# Project Cleanup Script for LMS-TRIAL
# This script removes unnecessary files and prepares the project for deployment

echo "🧹 Starting project cleanup..."

# Remove unnecessary development files from root
echo "Removing unnecessary root files..."
rm -f auto-deploy.sh
rm -f cleanup.sh
rm -f deploy.sh
rm -f prepare-deploy.bat
rm -f quick-setup.ps1
rm -f quick-setup.sh
rm -f monitor.sh

# Remove development node_modules (will be reinstalled on server)
echo "Removing node_modules directories..."
rm -rf node_modules/
rm -rf client/node_modules/
rm -rf server/node_modules/

# Remove client build directory (will be rebuilt on server)
echo "Removing client build directory..."
rm -rf client/build/

# Remove unnecessary documentation files
echo "Removing unnecessary documentation..."
rm -f API_DOCS.md
rm -f DEPLOYMENT.md
rm -f PRODUCTION-READY.md

# Keep only essential files in migrations and seeds
echo "Cleaning up migrations and seeds..."
# Remove old migration files except the latest ones
find server/migrations/ -name "*.js" -not -name "addDuplicateFields.js" -delete
find server/seeds/ -name "*.js" -not -name "newSuperAdminSeed.js" -delete

# Create production environment files
echo "Creating production environment templates..."

# Server production env template
cat > server/.env.production << 'EOF'
NODE_ENV=production
PORT=5000
MONGODB_URI=mongodb://localhost:27017/lms-trial
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_EXPIRE=30d
CORS_ORIGIN=http://16.171.146.116
EOF

# Client production env template
cat > client/.env.production << 'EOF'
REACT_APP_API_URL=http://16.171.146.116:5000
GENERATE_SOURCEMAP=false
EOF

echo "✅ Project cleanup completed!"
echo ""
echo "📁 Essential files remaining:"
echo "  - client/ (React frontend)"
echo "  - server/ (Node.js backend)"
echo "  - package.json files"
echo "  - nginx.conf"
echo "  - ecosystem.config.json"
echo ""
echo "🚀 Project is ready for deployment!"
