@echo off
rem ============================================================
rem  AutoLISP test entry - passes args through to run_tests.py.
rem  NOTE: English comments only - cmd parses batch as GBK,
rem        UTF-8 Chinese comments break parsing.
rem
rem  Usage:
rem    test-all.bat              full suite (static+runtime+harness+smoke)
rem    test-all.bat --static     static checks only (no CAD needed)
rem    test-all.bat --list       list tests that would run
rem
rem  Exit code: 0 all pass, 1 failures.
rem ============================================================
cd /d "%~dp0"
python run_tests.py %*
exit /b %errorlevel%
