@echo off

:: Tell Bundler where the Gemfile and gems are.
set "BUNDLE_GEMFILE=%~dp0\lib\vendor\Gemfile"
set BUNDLE_IGNORE_CONFIG=

:: Run the actual app using the bundled Ruby interpreter, with Bundler activated.
cd %~dp0\lib\app
::@"%~dp0\lib\ruby\bin\ruby.bat" -rbundler/setup "%~dp0\lib\ruby/bin.real/bundle" exec rake spec
::@"%~dp0\lib\ruby\bin\ruby.bat" -rbundler/setup "%~dp0\lib\ruby\lib\ruby\gems\2.2.0\bin\bundle" exec "%~dp0\lib\ruby\bin.real\rake" spec:db

%~dp0/lib/ruby/bin/ruby.bat -rbundler/setup -I'%~dp0/lib/vendor/ruby/2.2.0/gems/rspec-core-3.5.3/lib';'%~dp0/lib/vendor/ruby/2.2.0/gems/rspec-support-3.5.0/lib' '%~dp0/lib/vendor/ruby/2.2.0/gems/rspec-core-3.5.3/exe/rspec' 'test/test_results_db.rb' --format documentation

%~dp0/lib/ruby/bin/ruby.bat -rbundler/setup -I'%~dp0/lib/vendor/ruby/2.2.0/gems/rspec-core-3.5.3/lib';'%~dp0/lib/vendor/ruby/2.2.0/gems/rspec-support-3.5.0/lib' '%~dp0/lib/vendor/ruby/2.2.0/gems/rspec-core-3.5.3/exe/rspec' 'test/test_tblastn.rb' --format documentation
%~dp0/lib/ruby/bin/ruby.bat -rbundler/setup -I'%~dp0/lib/vendor/ruby/2.2.0/gems/rspec-core-3.5.3/lib';'%~dp0/lib/vendor/ruby/2.2.0/gems/rspec-support-3.5.0/lib' '%~dp0/lib/vendor/ruby/2.2.0/gems/rspec-core-3.5.3/exe/rspec' 'test/test_blast.rb' --format documentation
::%~dp0/lib/ruby/bin/ruby.bat -rbundler/setup -I'%~dp0/lib/vendor/ruby/2.2.0/gems/rspec-core-3.5.3/lib';'%~dp0/lib/vendor/ruby/2.2.0/gems/rspec-support-3.5.0/lib' '%~dp0/lib/vendor/ruby/2.2.0/gems/rspec-core-3.5.3/exe/rspec' 'test/test_tblastx.rb' --format documentation

cd %~dp0
:: copy all results from tblastn test, query and db
mkdir %~dp0\db_and_queries\test-tblastn-db
mkdir %~dp0\db_and_queries\test-tblastn-query
xcopy /s /e /y %~dp0\lib\app\test\db %~dp0\db_and_queries\test-tblastn-db
xcopy /s /e /y %~dp0\lib\app\test\tblastn\query %~dp0\db_and_queries\test-tblastn-query
pause
