@echo off
title TurtleCompass Deploy
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0deploy.ps1" %*
