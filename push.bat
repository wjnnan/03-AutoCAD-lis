@echo off
chcp 936 >nul
cd /d "d:\My Code\Claude Code\03-AutoCAD-lisp"

echo ============================================
echo   TB-Toolbox 提交推送工具
echo ============================================
echo.

git add -A

if not "%~1"=="" (
    git commit -m "%*"
) else (
    set /p "msg=请输入提交说明(直接回车用默认: 更新): "
    if not defined msg set "msg=更新"
    git commit -m "%msg%"
)

git push

echo.
echo ============================================
echo   完成! 验证结果:
echo   https://github.com/wjnnan/03-AutoCAD-lis/actions
echo ============================================
pause
