# For Bundler.with_clean_env
require 'bundler/setup'
require 'yaml'

PACKAGE_NAME = 'mass-blast'
VERSION = '1.0.0'
TRAVELING_RUBY_VERSION = '20150715-2.2.2'

TARGET_LINUX_X86    = 'linux-x86'
TARGET_LINUX_X86_64 = 'linux-x86_64'
TARGET_OSX          = 'osx'
TARGET_WIN32        = 'win32'

desc 'Package your app'
task package: ['package:linux:x86',
               'package:linux:x86_64',
               'package:osx',
               'package:win32']

desc 'Package your app for BacHBerry project'
task bachberry: ['bachberry:linux:x86',
                 'bachberry:linux:x86_64',
                 'bachberry:osx',
                 'bachberry:win32']

namespace :bachberry do
  namespace :linux do
    desc 'Package BacHBerry files in app for Linux x86 '
    task x86: [:'package:linux:x86'] do
      bachberry_files(TARGET_LINUX_X86)
    end

    desc 'Package BacHBerry files in app for Linux x86 '
    task x86_64: [:'package:linux:x86_64'] do
      bachberry_files(TARGET_LINUX_X86_64)
    end
  end

  desc 'Package BacHBerry files in app for OS X'
  task osx: [:'package:osx'] do
    bachberry_files(TARGET_OSX)
  end

  desc 'Package BacHBerry files in app for Win x86'
  task win32: [:'package:win32'] do
    bachberry_files(TARGET_WIN32)
  end
end

namespace :package do
  namespace :linux do
    desc 'Package your app for Linux x86'
    task x86: [:bundle_install, "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-linux-x86.tar.gz"] do
      create_package(TARGET_LINUX_X86)
    end

    desc 'Package your app for Linux x86_64'
    task x86_64: [:bundle_install, "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-linux-x86_64.tar.gz"] do
      create_package(TARGET_LINUX_X86_64)
    end
  end

  desc 'Package your app for OS X'
  task osx: [:bundle_install, "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-osx.tar.gz"] do
    create_package(TARGET_OSX)
  end

  desc 'Package your app for Windows x86'
  task win32: [:bundle_install, "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-win32.tar.gz"] do
    create_package(TARGET_WIN32, :windows)
  end

  desc 'Get git clone of app'
  task :fetch_source do
    if File.exist? 'packaging/app'
      sh 'git --git-dir=packaging/app/.git pull'
    else
      sh 'git clone https://github.com/averissimo/mass-blast.git' \
        ' packaging/app'
    end
    cur_path = FileUtils.pwd
    FileUtils.cd 'packaging/app/', verbose: true
    sh 'rake bootstrap'
    FileUtils.cd cur_path
    sh 'cp packaging/app/Gemfile .'
  end

  desc 'Install gems to local directory'
  task bundle_install: [:fetch_source] do
    sh 'rm -rf packaging/tmp'
    sh 'mkdir packaging/tmp'
    sh 'cp Gemfile Gemfile.lock packaging/tmp/'
    Bundler.with_clean_env do
      sh 'cd packaging/tmp && env BUNDLE_IGNORE_CONFIG=1 bundle install --path ../vendor --without development'
    end
    sh 'rm -rf packaging/tmp'
    sh 'rm -f packaging/vendor/*/*/cache/*'
  end
end

file "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-linux-x86.tar.gz" do
  download_runtime(TARGET_LINUX_X86)
end

file "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-linux-x86_64.tar.gz" do
  download_runtime(TARGET_LINUX_X86_64)
end

file "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-osx.tar.gz" do
  download_runtime(TARGET_OSX)
end

file "packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-win32.tar.gz" do
  download_runtime(TARGET_WIN32)
end

def bachberry_files(target)
  package_dir = "#{PACKAGE_NAME}-#{VERSION}-#{target}"
  sh "cp -r packaging/bachberry/db      #{package_dir}/db_and_queries"
  sh "cp -r packaging/bachberry/queries #{package_dir}/db_and_queries"
end

def app_config(package_dir)
  # name of config file
  config_file = "#{package_dir}/user.yml"
  # cp user.yml from source
  #  and create an example file that has all the comments
  sh "cp #{package_dir}/lib/app/config/user.yml #{config_file}"
  sh "cp #{package_dir}/lib/app/config/user.yml #{config_file}.example"
  # cp file structure to base dir to help users
  sh "mkdir #{package_dir}/db_and_queries"
  sh "mkdir #{package_dir}/db_and_queries/db"
  sh "mkdir #{package_dir}/db_and_queries/queries"
  sh "mkdir #{package_dir}/output" # create directory for output
  sh "cp -r #{package_dir}/lib/app/db_and_queries/import_dbs #{package_dir}/db_and_queries"
  sh "cp #{package_dir}/lib/app/db_and_queries/db/taxdb* #{package_dir}/db_and_queries/db"
  data = YAML.load_file config_file
  data['output'] = { 'dir' => '../../output' }
  data['db']['parent'] = '../../db_and_queries/db'
  data['query']['parent'] = '../../db_and_queries'
  File.open(config_file, 'w') { |f| YAML.dump(data, f) }
  #
end

def create_package(target, os_type = :unix)
  package_dir = "#{PACKAGE_NAME}-#{VERSION}-#{target}"
  sh "rm -rf #{package_dir}"
  sh "mkdir -p #{package_dir}/lib/app"
  sh "cp -r packaging/app #{package_dir}/lib"
  sh "rm -rf #{package_dir}/lib/app/vendor/ruby"
  sh "mkdir #{package_dir}/lib/ruby"
  sh 'tar -xzf' \
    " packaging/traveling-ruby-#{TRAVELING_RUBY_VERSION}-#{target}.tar.gz" \
    " -C #{package_dir}/lib/ruby"
  if os_type == :unix
    sh "cp packaging/wrapper.sh #{package_dir}/mass-blast"
  else
    sh "cp packaging/wrapper.bat #{package_dir}/mass-blast.bat"
  end
  sh "cp -pR packaging/vendor #{package_dir}/lib/"
  sh "cp Gemfile Gemfile.lock #{package_dir}/lib/vendor/"
  sh "mkdir #{package_dir}/lib/vendor/.bundle"
  sh "cp packaging/bundler-config #{package_dir}/lib/vendor/.bundle/config"
  #
  app_config(package_dir)
  #
  return false if ENV['DIR_ONLY']
  if os_type == :unix
    sh "tar -czf #{package_dir}.tar.gz #{package_dir}"
  else
    sh "zip -9r #{package_dir}.zip #{package_dir}"
  end
  sh "rm -rf #{package_dir}"
  sh "rm Gemfile"
end

def download_runtime(target)
  sh 'cd packaging && curl -L -O --fail' \
    " http://d6r77u77i8pq3.cloudfront.net/releases/traveling-ruby-#{TRAVELING_RUBY_VERSION}-#{target}.tar.gz"
end
