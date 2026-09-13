@echo off
chcp 936 >nul
cd /d "d:\My Code\Claude Code\03-AutoCAD-lisp"

echo ============================================
echo   New Commands Verify
echo ============================================
echo.

del /q "_new_cmd_result.log" 2>nul

"C:\Program Files\Autodesk\AutoCAD 2024\accoreconsole.exe" /s "d:\My Code\Claude Code\03-AutoCAD-lisp\_new_cmd_test.scr"

echo.
echo ============================================
echo   RESULT
echo ============================================
if exist "_new_cmd_result.log" (
    type "_new_cmd_result.log"
) else (
    echo [ERROR] result file not generated
)
echo.
pause
