# For Bundler.with_clean_env
require 'bundler/setup'
require 'bundler'
require 'yaml'

PACKAGE_NAME = 'mass-blast'

VERSIONS_PATH = 'versions.yml'

VERSION = if (test_version = (File.exist?('VERSION') &&
                              YAML.load_file('VERSION')))
            #
            YAML.load_file('VERSION')['version']
          else
            'please-create-VERSION-file'
          end

TRAVELING_RUBY_VERSION = '20150715-2.2.2'

TARGET_LINUX_X86    = 'linux-x86'
TARGET_LINUX_X86_64 = 'linux-x86_64'
TARGET_OSX          = 'osx'
TARGET_WIN32        = 'win32'

COMMIT = if test_version && test_version['commit']
           test_version['commit']
         else
           'origin/master'
         end
#

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
      sh 'git -C packaging/app fetch --all'
      sh 'git -C packaging/app fetch --tags'
    else
      sh 'git clone https://github.com/averissimo/mass-blast.git' \
        ' packaging/app'
    end
    sh "git -C packaging/app checkout origin/master"
    sh "git -C packaging/app checkout #{COMMIT}"
  end

  desc 'Install gems to local directory'
  task bundle_install: [:fetch_source] do
    sh 'rm -rf packaging/tmp'
    sh 'mkdir packaging/tmp'
    sh 'cp packaging/app/Gemfile packaging/tmp/'
    Bundler.with_clean_env do
      sh 'cd packaging/tmp && env BUNDLE_IGNORE_CONFIG=1' \
        ' bundle install --path ../vendor --without development'
      sh 'cp packaging/tmp/Gemfile packaging/tmp/Gemfile.lock packaging/vendor'
      sh "mkdir -p packaging/vendor/.bundle"
      sh "cp packaging/bundler-config packaging/vendor/.bundle/config"
    end
    sh 'rm -rf vendor'
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

def app_config(package_dir)
  # name of config file
  config_file = "#{package_dir}/user.yml"
  # cp user.yml from source
  #  and create an example file that has all the comments
  sh "cp #{package_dir}/lib/app/user.yml #{config_file}"
  sh "cp #{package_dir}/lib/app/user.yml #{config_file}.example"
  # cp file structure to base dir to help users
  sh "mkdir #{package_dir}/db_and_queries"
  sh "mkdir #{package_dir}/db_and_queries/db"
  sh "mkdir #{package_dir}/db_and_queries/queries"
  sh "mkdir #{package_dir}/db_and_queries/annotation"
  sh "mkdir #{package_dir}/output" # create directory for output
  sh "cp -r #{package_dir}/lib/app/db_and_queries/import_dbs #{package_dir}/db_and_queries"
  sh "cp -r #{package_dir}/lib/app/db_and_queries/db #{package_dir}/db_and_queries"
  data = YAML.load_file config_file
  data['debug'] = {} if data['debug'].nil?
  data['debug']['file'] = 'log.txt'
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
    sh "cp packaging/testing.sh #{package_dir}/testing"
  else
    sh "cp packaging/wrapper.bat #{package_dir}/mass-blast.bat"
    sh "cp packaging/testing.bat #{package_dir}/testing.bat"
  end
  sh "cp -pR packaging/vendor #{package_dir}/lib/"
  #
  # retrieve external data
  #
#  cur_path = FileUtils.pwd
#  FileUtils.cd 'packaging/app/', verbose: true
#  sh 'env BUNDLE_GEMFILE="../vendor/Gemfile" rake bootstrap'
#  FileUtils.cd cur_path
  #
  ##
  app_config(package_dir)
  package(package_dir, os_type) unless ENV['DIR_ONLY']
  # save version number
  versions = if File.exist? VERSIONS_PATH
               YAML.load_file(VERSIONS_PATH)
             else
               {}
             end
  versions[VERSION] ||= {}
  versions[VERSION][DateTime.now.to_s] = `git -C packaging/app rev-parse HEAD`
  File.open(VERSIONS_PATH, 'wb') do |f|
    f.write(YAML.dump(versions))
  end
  #
end

def package(package_dir, os_type)
  if os_type == :unix
    sh "tar -czf #{package_dir}.tar.gz #{package_dir}"
  else
    sh "zip -9r #{package_dir}.zip #{package_dir}"
  end
  sh "rm -rf #{package_dir}"
end

def download_runtime(target)
  sh 'cd packaging && curl -L -O --fail' \
    " http://d6r77u77i8pq3.cloudfront.net/releases/traveling-ruby-#{TRAVELING_RUBY_VERSION}-#{target}.tar.gz"
end
