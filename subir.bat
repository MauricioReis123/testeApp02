@echo off
chcp 65001 >nul
title Enviando Projeto para o GitHub - Sem Frescura

echo ========================================================
echo AUTOMATIZADOR GITHUB - UPLOAD DIRETO
echo ========================================================
echo.

:: URL fixa do seu projeto (sem comandos de input para nao falhar)
set "REPO_URL=https://github.com/MauricioReis123/testeApp02.git"

echo [1/5] Removendo configuracoes antigas do Git (se existirem)...
rd /s /q .git 2>nul
echo Feito.

echo.
echo [2/5] Inicializando um repositorio Git limpo...
git init
if errorlevel 1 goto erro

echo.
echo [3/5] Adicionando todos os arquivos e pastas...
git add .
if errorlevel 1 goto erro

echo.
echo [4/5] Criando o commit inicial...
git commit -m "Upload automatizado via script bat"
if errorlevel 1 goto erro

echo.
echo [5/5] Enviando para o GitHub (Branch main)...
git branch -M main
git remote add origin %REPO_URL%
git push -u origin main --force

if errorlevel 1 goto erro

echo.
echo ========================================================
echo SUCESSO! Seus arquivos foram enviados para o GitHub!
echo ========================================================
echo.
pause
exit

:erro
echo.
echo ========================================================
echo [!] OCORREU UM ERRO DURANTE O ENVIO.
echo ========================================================
echo Lembre-se: quando o Git abrir a janela pedindo usuario e senha,
echo no campo da SENHA voce DEVE colar o seu Personal Access Token (PAT)
echo gerado no GitHub, e nao a senha da sua conta!
echo.
pause