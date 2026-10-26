@echo off
rem 小确幸盲盒 - 启动本地服务器并打开页面
start "blindbox" /min powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0serve.ps1"
timeout /t 1 /nobreak >nul
start http://127.0.0.1:5173/
