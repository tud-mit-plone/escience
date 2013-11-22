#
# vendor/plugins/redmine_etherpad/init.rb
#

require 'redmine'
require 'uri'

Redmine::Plugin.register :redmine_ethersheet do
  name 'Redmine Ethersheet plugin'
  author 'Charlie DeTar, Reichmann Christian'
  description 'Embed ethersheet in redmine wikis.'
  version '0.0.1'
  #url 'https://github.com/yourcelf/redmine_etherpad'
  #author_url 'https://github.com/yourcelf'

  Redmine::WikiFormatting::Macros.register do
    desc "Embed ethersheet"
    macro :ethersheet do |obj, args|
      conf = Redmine::Configuration['ethersheet']
      unless conf and conf['host'] 
        raise "Please define etherpad parameters in configuration.yml."
      end

      # Defaults from configuration.
      controls = {
        'showControls' => conf.fetch('showControls', true),
        'showChat' => conf.fetch('showChat', true),
        'showLineNumbers' => conf.fetch('showLineNumbers', false),
        'useMonospaceFont' => conf.fetch('useMonospaceFont', false),
        'noColors' => conf.fetch('noColors', false),
        'width' => conf.fetch('width', '640px'),
        'height' => conf.fetch('height', '480px'),
      }

      # Override defaults with given arguments.
      padname, *params = args
      for param in params
        key, val = param.strip().split("=")
        unless controls.has_key?(key)
          raise "#{key} not a recognized parameter."
        else
          controls[key] = val
        end
      end

      # Set current user name.
      if User.current
        controls['userName'] = User.current.name
      elsif conf.fetch('loginRequired', true)
        return "TODO: embed read-only."
      end

      width = controls.delete('width')
      height = controls.delete('height')

      def hash_to_querystring(hash)
        hash.keys.inject('') do |query_string, key|
          query_string << '&' unless key == hash.keys.first
          query_string << "#{URI.encode(key.to_s)}=#{URI.encode(hash[key].to_s)}"
        end
      end
      
      return CGI::unescapeHTML("<iframe src='#{conf['host']}/s/#{URI.encode(padname)}?' width='#{width}' height='#{height}'></iframe>").html_safe
    end
  end
end
