@echo off
rem ================================================================
rem  TB-Toolbox 编译：intermediate.lsp -> toolbox.fas
rem  本脚本会把 AutoCAD 的输出写入 build\compile.log 便于排查。
rem ================================================================
chcp 936 >nul
setlocal
set "TBDIR=%~dp0"
set "ACAD=C:\Program Files\Autodesk\AutoCAD 2024\acad.exe"
set "LOG=%TBDIR%build\compile.log"

if not exist "%ACAD%" (
  echo [错误] 未找到 AutoCAD: %ACAD%
  pause & exit /b 1
)
if not exist "%TBDIR%build\intermediate.lsp" (
  echo [错误] 缺少 build\intermediate.lsp，请先执行合并步骤。
  pause & exit /b 1
)

echo 正在启动 AutoCAD 编译，请稍候...
echo 若弹出「用户帐户控制」请选“是”。
echo.
"%ACAD%" /nologo /b "%TBDIR%build\compile.scr" > "%LOG%" 2>&1
set "RC=%ERRORLEVEL%"

echo.
if exist "%TBDIR%build\toolbox.fas" (
  echo [成功] 已生成 build\toolbox.fas
  echo.
  echo 下一步：在 AutoCAD 命令行输入 VLISP 打开 Visual LISP，
  echo 用「文件 - 生成应用程序 - 新建应用程序向导」打包 .vlx：
  echo   应用程序文件: build\toolbox.fas
  echo   资源文件:     tb-dcl-launcher.dcl / tb-dcl-setting.dcl /
  echo                 tb-dcl-batchprint.dcl / tb-dcl-hotkey.dcl /
  echo                 tb-dcl-help.dcl
  echo.
  pause & exit /b 0
)

echo [失败] 未生成 toolbox.fas。acad.exe 退出码: %RC%
echo.
echo ---------- AutoCAD 输出（build\compile.log）----------
if exist "%LOG%" (
  type "%LOG%"
) else (
  echo （没有产生日志文件，说明 acad.exe 根本没启动起来）
)
echo ----------------------------------------------------------
echo.
echo 排查建议:
echo   1. 先确认平时双击 AutoCAD 图标能否正常打开；
echo   2. 若打不开，问题在 AutoCAD 本身（本次未见 ProgramData
echo      \Autodesk\AutoCAD 2024\ 配置目录）；
echo   3. 若 AutoCAD 能正常打开，直接在里面执行:
echo        (vlisp-compile (quote st)
echo          "D:/My Code/Claude Code/03-AutoCAD-lisp/TB-Toolbox/build/intermediate.lsp"
echo          "D:/My Code/Claude Code/03-AutoCAD-lisp/TB-Toolbox/build/toolbox.fas")
echo.
pause
