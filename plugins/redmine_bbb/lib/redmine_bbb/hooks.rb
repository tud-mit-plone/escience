# Provides a link to the issue age graph on the issue index page
require 'open-uri'
require 'rexml/document'
module RedmineBbb

class ProjectSidebarBigBlueButtonHook < Redmine::Hook::ViewListener
  def view_projects_show_sidebar_bottom(context = {})
    @project = context[:project]
    output = ""
    begin
      if(User.current.allowed_to?(:bigbluebutton_join, @project) || User.current.allowed_to?(:bigbluebutton_start, @project))
        url = Setting.plugin_redmine_bbb['bbb_help']
        link = url.empty? ? "" : "&nbsp;&nbsp;<a href='" + url + "' target='_blank' class='icon icon-help'>&nbsp;</a>"

        server = Setting.plugin_redmine_bbb['bbb_ip'].empty? ? Setting.plugin_redmine_bbb['bbb_server'] : Setting.plugin_redmine_bbb['bbb_ip']
        meeting_started=false
        #First, test if meeting room already exists
        moderatorPW=Digest::SHA1.hexdigest("root"+@project.identifier)
        data = callapi(server, "getMeetingInfo","meetingID=" + @project.identifier + "&password=" + moderatorPW, true)
        
        doc = REXML::Document.new(data)
	      if doc.root.elements['returncode'].text == "FAILED"
          output << "</ul><hr /><div style='white-space:nowrap;margin-left:7px;'>#{l(:label_bigbluebutton)} (<i>#{l(:label_bigbluebutton_status_closed)}</i>)</div>"
          output << "<ul>"
          output << "   <li class=\"help\">#{link_to(l(:label_help), url, :class => 'icon icon-question')}</li>" unless url.empty?
        else
          meeting_started = true
          output << "</ul><hr /><div style='white-space:nowrap;margin-left:7px;'>#{l(:label_bigbluebutton)} (<i>#{l(:label_bigbluebutton_status_closed)}</i>)</div>"            
          output << "<div class=\"people\">#{doc.root.elements['attendees'].count+" "+l(:label_bigbluebutton_people)}</div>" unless doc.root.elements['attendees'].empty?
          output << "<ul>"
          output << "   <li>#{link_to(l(:label_help), url, :class => 'icon icon-question')}</li>" unless url.empty?
          if Setting.plugin_redmine_bbb['bbb_popup'] != '1'
            output << "   <li>#{link_to(l(:label_bigbluebutton_join), {:controller => 'bbb', :action => 'start', :project_id => context[:project], :only_path => true}, :class => 'icon icon-signin')}</i>"
          else
            output << "   <li>#{link_to_function(l(:label_bigbluebutton_join),"var wihe='width'+screen.availWidth+',height='+screen.availHeight; open('"+url_for(:controller => 'bbb', :action => 'start', :project_id => context[:project], :only_path => true)+'\\'+"','Meeting','directories=no,location=no,resizable=yes,scrollbars=yes,status=no,toolbar=no,' + wihe);return false;", :class => "icon icon-signin")}</li>"
          end
 
          doc.root.elements['attendees'].each do |attendee|
            name=attendee.elements['fullName'].text
#              output << "<li>#{name}</li>"
          end
        end
        output << "</ul></div>"

        if !meeting_started
          if User.current.allowed_to?(:bigbluebutton_start, @project)
            if Setting.plugin_redmine_bbb['bbb_popup'] != '1'
              output << "<ul><li>"
              output << link_to(l(:label_bigbluebutton_start), {:controller => 'bbb', :action => 'start', :project_id => context[:project], :only_path => true}, :class => 'icon icon-circle-blank')
              output << "</li></ul>"
            else
              output << "<ul><li><a href='' onclick='javascript:var wihe = \"width=\"+screen.availWidth+\",height=\"+screen.availHeight; open(\"" + url_for(:controller => 'bbb', :action => 'start', :project_id => context[:project], :only_path => true) + "\",\"Meeting\",\"directories=no,location=no,resizable=yes,scrollbars=yes,status=no,toolbar=no,\" + wihe);return false;', class='icon icon-circle-blank' >#{l(:label_bigbluebutton_start)}</a></li></ul>"
            end
          end
        end
      end
    rescue Exception => e
#      config.logger.error(e.message)
#      config.logger.error(e.backtrace.inspect)
      output << "</ul><hr /><div style='margin-left:11px;'>#{l(:label_bigbluebutton)}<br/>"
      output << "<i class='icon-exclamation-sign' style='color:#d4b93f'></i> #{l(:label_bigbluebutton_error)}</div>"
    end
    return output
  end

  private

  def each_xml_element(node, name)
    if node && node[name]
      if node[name].is_a?(Hash)
        yield node[name]
      else
        node[name].each do |element|
          yield element
        end
      end
    end
  end

  def callapi (server, api, param, getcontent)
    salt = Setting.plugin_redmine_bbb['bbb_salt']
    tmp = api + param + salt
    checksum = Digest::SHA1.hexdigest(tmp)
    url = server + "/bigbluebutton/api/" + api + "?" + param + "&checksum=" + checksum
    if getcontent
      connection = open(url)
      return connection.read
    else
      return url
    end
  end

end
end
