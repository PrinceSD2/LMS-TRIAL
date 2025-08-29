# EC2 Deployment Guide for LMS System

## Prerequisites on EC2 Instance

1. **Connect to your EC2 instance:**
   ```bash
   ssh -i your-key.pem ubuntu@16.170.227.75
   ```

2. **Install Node.js and npm:**
   ```bash
   curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
   sudo apt-get install -y nodejs
   ```

3. **Install Git:**
   ```bash
   sudo apt-get update
   sudo apt-get install git
   ```

4. **Install PM2 (Process Manager):**
   ```bash
   sudo npm install -g pm2
   ```

## Deployment Steps

### Step 1: Transfer Files to EC2
You can use one of these methods:

**Option A: Using SCP (from your local machine):**
```bash
scp -i your-key.pem -r C:\Users\int0003\Desktop\jldikrryrr\LMS-TRIAL ubuntu@16.170.227.75:~/
```

**Option B: Using Git (if you have a repository):**
```bash
git clone https://github.com/your-username/LMS-TRIAL.git
cd LMS-TRIAL
```

### Step 2: Setup on EC2
```bash
cd ~/LMS-TRIAL

# Install dependencies
npm run install-all

# Build the React app
cd client
npm run build
cd ..

# Set up production environment
cp server/.env.production server/.env
```

### Step 3: Configure Security Groups
In AWS Console, ensure your EC2 security group allows:
- Port 22 (SSH)
- Port 5000 (Backend API)
- Port 3000 (Frontend - if serving separately)
- Port 80 (HTTP)
- Port 443 (HTTPS)

### Step 4: Start the Application
```bash
cd server
pm2 start server.js --name "lms-backend"
pm2 startup
pm2 save
```

### Step 5: Verify Deployment
- Backend API: http://16.170.227.75:5000/api/health
- Full Application: http://16.170.227.75:5000

## Environment Variables

### Server (.env.production)
```
MONGODB_URI=mongodb+srv://rglms10:RGLMS123@lmsdatabase.jo25hav.mongodb.net/LMSdata+
JWT_SECRET=LMSSECRETKEY
PORT=5000
NODE_ENV=production
```

### Client (.env.production)
```
REACT_APP_API_URL=http://16.170.227.75:5000
```

## Process Management Commands

```bash
# View running processes
pm2 list

# View logs
pm2 logs lms-backend

# Restart application
pm2 restart lms-backend

# Stop application
pm2 stop lms-backend

# Monitor processes
pm2 monit
```

## Troubleshooting

1. **Check if ports are open:**
   ```bash
   sudo netstat -tlnp | grep :5000
   ```

2. **Check application logs:**
   ```bash
   pm2 logs lms-backend
   ```

3. **Restart the application:**
   ```bash
   pm2 restart lms-backend
   ```

4. **Check security groups in AWS Console**

5. **Verify MongoDB connection:**
   - Ensure MongoDB Atlas allows connections from your EC2 IP

## Optional: Setup Nginx Reverse Proxy

For production, consider setting up Nginx:

```bash
sudo apt-get install nginx

# Create Nginx configuration
sudo nano /etc/nginx/sites-available/lms
```

Add this configuration:
```nginx
server {
    listen 80;
    server_name 16.170.227.75;

    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

Enable the site:
```bash
sudo ln -s /etc/nginx/sites-available/lms /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```
