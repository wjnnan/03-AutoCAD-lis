@echo off
rem ============================================================
rem  Install AutoLISP static-check pre-commit hook (no deps).
rem  NOTE: English comments only - cmd parses batch as GBK,
rem        UTF-8 Chinese comments break parsing.
rem
rem  Effect: every `git commit` runs `python run_tests.py --static`
rem  Skip once: git commit --no-verify
rem ============================================================
setlocal
cd /d "%~dp0"

if not exist ".git" (
  echo [install-hooks] ERROR: not a git repository root
  exit /b 1
)
if not exist "hooks\pre-commit" (
  echo [install-hooks] ERROR: hooks\pre-commit template not found
  exit /b 1
)

rem Copy template and force LF line endings (CRLF breaks sh shebang)
python -c "import pathlib; data=pathlib.Path('hooks/pre-commit').read_bytes().replace(b'\r\n', b'\n'); pathlib.Path('.git/hooks/pre-commit').write_bytes(data)"
if %errorlevel% neq 0 (
  echo [install-hooks] ERROR: failed to write hook (check python)
  exit /b 1
)

echo [install-hooks] pre-commit hook installed (runs run_tests.py --static)
echo [install-hooks] skip once with: git commit --no-verify
exit /b 0
