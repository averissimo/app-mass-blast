@echo off

:: Tell Bundler where the Gemfile and gems are.
set "BUNDLE_GEMFILE=%~dp0\lib\vendor\Gemfile"
set BUNDLE_IGNORE_CONFIG=

:: Run the actual app using the bundled Ruby interpreter, with Bundler activated.
cd %~dp0\lib\app
@"%~dp0\lib\ruby\bin\ruby.bat" -rbundler/setup "%~dp0\lib\ruby/bin.real/bundle" exec rake spec
cd %~dp0
:: copy all results from tblastn test, query and db
mkdir %~dp0\db_and_queries\test-tblastn-db
mkdir %~dp0\db_and_queries\test-tblastn-query
xcopy /s /e /y %~dp0\lib\app\test\db %~dp0\db_and_queries\test-tblastn-db
xcopy /s /e /y %~dp0\lib\app\test\tblastn\query %~dp0\db_and_queries\test-tblastn-query
pause
