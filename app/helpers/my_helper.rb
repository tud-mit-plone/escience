# encoding: utf-8
#
# Redmine - project management software
# Copyright (C) 2006-2012  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

module MyHelper
  # Renders a tree of projects as a nested set of unordered lists
  # The given collection may be a subset of the whole project tree
  # (eg. some intermediate nodes are private and can not be seen)
  def render_project_hierarchy
  projects = Project.visible.find(:all, :order => 'lft')
    s = ''
    if projects.any?
      ancestors = []
      original_project = @project
      projects.each do |project|
        # set the project environment to please macros.
        @project = project
        if (ancestors.empty? || project.is_descendant_of?(ancestors.last))
          s << "<ul class='projects #{ ancestors.empty? ? 'root' : nil}'>\n"
        else
          ancestors.pop
          s << "</li>"
          while (ancestors.any? && !project.is_descendant_of?(ancestors.last))
            ancestors.pop
            s << "</ul></li>\n"
          end
        end
        classes = (ancestors.empty? ? 'root' : 'child')
        s << "<li class='#{classes}'><div class='#{classes}'>" +
               link_to_project(project, {}, :class => "project #{User.current.member_of?(project) ? 'my-project' : nil}")
        ancestors << project
      end
      s << ("</li></ul>\n" * ancestors.size)
      @project = original_project
    end
    s.html_safe
  end

  def extract_block_name(block)
    return [block.split('_').first, block.split('_').length > 1 ? block.split('_').last : nil]
  end

  def render_usermessage_inbox
    authors = UserMessage.get_names_of_sender
    s = ''
    if authors.any?
      s << "<ul class='authors'>\n"
      authors.each do |author|
          s << "<li>" +
                link_to("#{author.author} (#{author.created_at.strftime('%d.%m.%y - %H:%M')})", {:title  => "#{author.author}", :controller => 'user_messages', :action => 'show', :id => author.id})
          s << "</li>"
      end
      s << ("</li></ul>\n")
    end
    s.html_safe
  end

end
