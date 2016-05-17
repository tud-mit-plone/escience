source 'https://rubygems.org'

gem 'rails', '3.2.19'
gem "jquery-rails", "~> 2.0.2"
gem "i18n", "~> 0.6.0"
gem "coderay", "~> 1.0.6"
gem "fastercsv", "~> 1.5.0", :platforms => [:mri_18, :mingw_18, :jruby]
gem "builder", "3.0.0"
gem 'sprockets'

# Optional gem for LDAP authentication
group :ldap do
  gem "net-ldap", "~> 0.3.1"
end

# Optional gem for OpenID authentication
group :openid do
  gem "ruby-openid", "~> 2.1.4", :require => "openid"
  gem "rack-openid"
end

# Optional gem for exporting the gantt to a PNG file, not supported with jruby
platforms :mri, :mingw do
  group :rmagick do
    # RMagick 2 supports ruby 1.9
    # RMagick 1 would be fine for ruby 1.8 but Bundler does not support
    # different requirements for the same gem on different platforms
    gem "rmagick", ">= 2.0.0"
  end
end

=begin
# Database gems
platforms :mri, :mingw do
  group :postgresql do
    #gem "pg", ">= 0.11.0"
  end

  group :sqlite do
    gem "sqlite3"
  end
end

platforms :mri_18, :mingw_18 do
  group :mysql do
    gem "mysql"
  end
end

if RUBY_VERSION =~ /^1/
  platforms :mri_19, :mingw_19 do
    group :mysql do
      gem "mysql2", "~> 0.3.11"
    end
  end
end

if RUBY_VERSION =~ /^2/
  platforms :mri_20, :mingw_20 do
    group :mysql do
      gem "mysql2", "~> 0.3.11"
    end
  end
end

platforms :jruby do
  gem "jruby-openssl"

  group :mysql do
    gem "activerecord-jdbcmysql-adapter"
  end

  group :postgresql do
    gem "activerecord-jdbcpostgresql-adapter"
  end

  group :sqlite do
    gem "activerecord-jdbcsqlite3-adapter"
  end
end
=end

group :production do
  gem "mysql2", "~> 0.3.10"
  gem "passenger"
end

group :development do
  gem "rdoc", ">= 2.4.2"
  gem "yard"
  gem "sqlite3"
  gem "byebug"
end

group :test do
  gem "shoulda", "~> 2.11"
  # Shoulda does not work nice on Ruby 1.9.3 and JRuby 1.7.
  # It seems to need test-unit explicitely.
  platforms = [:mri_19]
  platforms << :jruby if defined?(JRUBY_VERSION) && JRUBY_VERSION >= "1.7"
  gem "test-unit", :platforms => platforms
  gem 'minitest', '3.5.0'
  gem "mocha", "~>0.13.3", :require => false
  gem 'cane', '~> 2.6.2'
  gem 'flay'
  # for rolling back each modification during a test
  gem 'database_cleaner'
end

local_gemfile = File.join(File.dirname(__FILE__), "Gemfile.local")
if File.exists?(local_gemfile)
  puts "Loading Gemfile.local ..." if $DEBUG # `ruby -d` or `bundle -v`
  instance_eval File.read(local_gemfile)
end

# Load plugins' Gemfiles
Dir.glob File.expand_path("../plugins/*/Gemfile", __FILE__) do |file|
  puts "Loading #{file} ..." if $DEBUG # `ruby -d` or `bundle -v`
  instance_eval File.read(file)
end

group :development, :test do
    gem 'railroady'
end

gem "thin"
gem "SyslogLogger"  # in production mode log to syslog
gem "acts-as-taggable-on", '3.5.0'
#piwik analytics
gem 'piwik_analytics', '~> 1.0.0'
#gem 'turbolinks'
#pry console no need for readline
gem "pry"
#dropbox plugin
gem "oauth"
gem  "multipart-post"
# htmlentities are needed for decoding wysiwyg into wiki
gem "htmlentities"
gem "rghost"
gem 'render_parent', '>= 0.0.4'
gem "xml-object"
# Activities rendering
gem "nokogiri"
# for redmine_social_plugin
gem "meta_search"
gem "will_paginate"
gem "power_enum"
gem 'acts_as_commentable', '3.0.1'
gem 'cocaine','0.3.2'
gem 'paperclip','3.1.4'
gem 'docsplit', '~> 0.7.5'
gem 'iconv'
gem 'capit'
gem 'rqrcode_png'
gem 'pismo'
gem 'sys-proctable'
gem 'simplecov', :require => false, :group => :test
gem "galetahub-simple_captcha", :require => "simple_captcha"
