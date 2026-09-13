@echo off
chcp 936 >nul
cd /d "d:\My Code\Claude Code\03-AutoCAD-lisp"

echo ============================================
echo   External AutoCAD Projects Verify
echo ============================================
echo.

if not exist "_tmp_pipe-router-autolisp" (
    echo [1/3] Cloning pipe-router-autolisp...
    git clone --depth 1 https://github.com/ferhatatesmech/pipe-router-autolisp.git _tmp_pipe-router-autolisp
)
if not exist "_tmp_AutoCAD-LISP" (
    echo [2/3] Cloning AutoCAD-LISP...
    git clone --depth 1 https://github.com/ahmed-abdelmotey/AutoCAD-LISP.git _tmp_AutoCAD-LISP
)
if not exist "_tmp_cathedral" (
    echo [3/3] Cloning cathedral...
    git clone --depth 1 https://github.com/Jciel/cathedral.git _tmp_cathedral
)

echo.
echo Running AutoCAD headless test...
del /q "_ext_result.log" 2>nul

"C:\Program Files\Autodesk\AutoCAD 2024\accoreconsole.exe" /s "d:\My Code\Claude Code\03-AutoCAD-lisp\_ext_test.scr"

echo.
echo ============================================
echo   RESULT
echo ============================================
if exist "_ext_result.log" (
    type "_ext_result.log"
) else (
    echo [ERROR] result file not generated
)

echo.
pause
