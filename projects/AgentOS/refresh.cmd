@echo off
rem Headless AgentOS refresh. Registered in Windows Task Scheduler as "AgentOS refresh".
cd /d C:\Users\samgo\vault
set LOG=projects\AgentOS\data\refresh.log
echo [%date% %time%] start>> "%LOG%"
"C:\Users\samgo\.local\bin\claude.exe" -p "Run projects/AgentOS/refresh.md" --allowedTools "Read,Write,Edit,Bash,mcp__claude_ai_Google_Calendar__list_events,mcp__claude_ai_TickTick__list_projects,mcp__claude_ai_TickTick__get_project_with_undone_tasks,mcp__claude_ai_Supabase__execute_sql" >> "%LOG%" 2>&1
echo [%date% %time%] exit %errorlevel%>> "%LOG%"
