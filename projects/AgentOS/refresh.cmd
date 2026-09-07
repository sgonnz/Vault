@echo off
rem Headless AgentOS refresh. Registered in Windows Task Scheduler as "AgentOS refresh".
cd /d C:\Users\samgo\vault
set AGENTOS=projects\AgentOS
set LOG=%AGENTOS%\data\refresh.log
set OUT=%TEMP%\agentos-refresh-output.json
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format o"') do set STARTED=%%i
echo [%STARTED%] start>> "%LOG%"
"C:\Users\samgo\.local\bin\claude.exe" -p "Run projects/AgentOS/refresh.md" --output-format json --allowedTools "Read,Write,Edit,Bash,mcp__claude_ai_Google_Calendar__list_events,mcp__claude_ai_TickTick__list_projects,mcp__claude_ai_TickTick__get_project_with_undone_tasks,mcp__claude_ai_TickTick__list_completed_tasks_by_date,mcp__claude_ai_TickTick__get_focuses_by_time,mcp__claude_ai_TickTick__list_habits,mcp__claude_ai_TickTick__get_habit_checkins,mcp__claude_ai_Supabase__execute_sql" > "%OUT%" 2>> "%LOG%"
set CODE=%errorlevel%
python "%AGENTOS%\scripts\record-run.py" "%OUT%" "%STARTED%" %CODE% >> "%LOG%" 2>&1
echo [%STARTED%] exit code %CODE% >> "%LOG%"
