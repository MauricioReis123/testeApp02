@echo off
echo ==========================================
echo    Iniciando o envio para o GitHub...
echo ==========================================

git init
git add .
git commit -m "Primeiro commit do projeto Flutter"
git branch -M main
git remote add origin https://github.com/MauricioReis123/testeApp02.git
git push -u origin main

echo ==========================================
echo    Processo concluido com sucesso!
echo ==========================================
pause