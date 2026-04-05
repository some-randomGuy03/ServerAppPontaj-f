@echo off
echo Starting Flutter app on Chrome with CORS disabled...
flutter run -d chrome --web-browser-flag="--disable-web-security" --web-browser-flag="--user-data-dir=C:/temp_chrome_dev"
pause
