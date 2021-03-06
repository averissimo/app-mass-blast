@echo off

:: Tell Bundler where the Gemfile and gems are.
set "BUNDLE_GEMFILE=%~dp0\lib\vendor\Gemfile"
set BUNDLE_IGNORE_CONFIG=

:: Run the actual app using the bundled Ruby interpreter, with Bundler activated.
cd %~dp0\lib\app
@"%~dp0\lib\ruby\bin\ruby.bat" -rbundler/setup "%~dp0\lib\app\script.rb" "%~dp0\user.yml"
cd %~dp0
pause
