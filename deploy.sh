#!/bin/bash

echo "===================================="
echo "LMS Deployment Script for EC2"
echo "===================================="
echo

# Set production environment
export NODE_ENV=production

echo "Building React app for production..."
cd client
npm run build
cd ..

echo "Copying production environment files..."
cp server/.env.production server/.env
cp client/.env.production client/.env

echo "Starting server in production mode..."
cd server
npm start

echo "===================================="
echo "Deployment Complete!"
echo "Application should be running on:"
echo "Frontend: http://16.170.227.75:3000"
echo "Backend API: http://16.170.227.75:5000"
echo "===================================="
