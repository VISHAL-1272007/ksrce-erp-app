@echo off
REM ═══════════════════════════════════════════════════════
REM  KSRCE ERP — Build, Commit, Push & Deploy
REM  Run this from the project root: d:\Admin\college\college
REM ═══════════════════════════════════════════════════════

REM Use the directory where this script lives as the project root
cd /d "%~dp0"

REM Clean up temp files from previous runs
del /q "push_result.txt" 2>nul
del /q "git_push.bat" 2>nul
del /q "git_push2.bat" 2>nul
del /q "git_final.bat" 2>nul
del /q "git_verify.bat" 2>nul
del /q "commit_result.txt" 2>nul
del /q "commit_result2.txt" 2>nul
del /q "commit_final.txt" 2>nul
del /q "verify.txt" 2>nul
del /q "gitlog_result.txt" 2>nul
del /q "run_git.bat" 2>nul

REM ── Build Flutter web ──
echo === BUILDING FLUTTER WEB === > push_result.txt
call flutter build web --release >> push_result.txt 2>&1
if %ERRORLEVEL% neq 0 (
    echo BUILD FAILED — check push_result.txt for details
    exit /b 1
)

REM ── Git: stage, commit, push ──
echo === GIT COMMIT === >> push_result.txt
git add -A >> push_result.txt 2>&1
git commit -m "Deploy: production build %date% %time%" >> push_result.txt 2>&1

echo === PUSHING === >> push_result.txt
git push origin main --force-with-lease >> push_result.txt 2>&1

REM ── Firebase: deploy hosting ──
echo === DEPLOYING TO FIREBASE === >> push_result.txt
call firebase deploy --only hosting >> push_result.txt 2>&1

echo === ALL DONE === >> push_result.txt
echo.
echo Deploy complete! See push_result.txt for details.
