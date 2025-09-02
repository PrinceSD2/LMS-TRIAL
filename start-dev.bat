@echo off
echo =====================================
echo Starting LMS Development Environment
echo =====================================
echo.

echo Installing dependencies...
cd server
call npm install
cd ..\client
call npm install
cd ..

echo.
echo Starting development servers...
echo Backend will run on: http://localhost:5000
echo Frontend will run on: http://localhost:3000
echo.

start "LMS Backend" cmd /k "cd server && npm run dev"
timeout /t 3 /nobreak >nul
start "LMS Frontend" cmd /k "cd client && npm start"

echo.
echo Development servers are starting...
echo Backend: http://localhost:5000
echo Frontend: http://localhost:3000
echo.
echo Press any key to close this window...
pause >nul
