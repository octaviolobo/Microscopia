@echo off
echo === Instalando Sistema de Laudos - Microscopia Vaginal ===
echo.

python --version 2>NUL
if %errorlevel% neq 0 (
    echo ERRO: Python nao encontrado. Instale Python 3.9+ em python.org
    pause
    exit /b 1
)

echo Instalando dependencias...
pip install -r requirements.txt

if %errorlevel% neq 0 (
    echo ERRO na instalacao. Tente: pip install -r requirements.txt
    pause
    exit /b 1
)

echo.
echo === Instalacao concluida! ===
echo Para iniciar: execute run.bat
echo.
pause
