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

class SearchController < ApplicationController
  before_filter :require_login
  before_filter :find_optional_project

  helper :messages
  include MessagesHelper

  def index
    @question = params[:q] || ""
    @question.strip!
    @all_words = params[:all_words] ? params[:all_words].present? : true
    @titles_only = params[:titles_only] ? params[:titles_only].present? : false

    projects_to_search =
      case params[:scope]
      when 'all'
        nil
      when 'my_projects'
        User.current.memberships.collect(&:project)
      when 'subprojects'
        @project ? (@project.self_and_descendants.active.all) : nil
      else
        #@project
        nil
      end

    offset = 0
    begin; offset = params[:offset].to_i if params[:offset]; rescue; end

    # quick jump to an issue
    if @question.match(/^#?(\d+)$/) && Issue.visible.find_by_id($1.to_i)
      redirect_to :controller => "issues", :action => "show", :id => $1
      return
    end

    @object_types = Redmine::Search.available_search_types.dup
    @object_types_options = Redmine::Search.type_specific_options.dup

    if projects_to_search.is_a? Project
      # don't search projects
      @object_types.delete('projects')
      # only show what the user is allowed to view
      @object_types = @object_types.select {|o| User.current.allowed_to?("view_#{o}".to_sym, projects_to_search)}
    end

    @scope = @object_types.select {|t| params[t]}
    @scope = @object_types if @scope.empty?

    # extract tokens from the question
    # eg. hello "bye bye" => ["hello", "bye bye"]
    @tokens = @question.scan(%r{((\s|^)"[\s\w]+"(\s|$)|\S+)}).collect {|m| m.first.gsub(%r{(^\s*"\s*|\s*"\s*$)}, '')}
    # tokens must be at least 2 characters long
    @tokens = @tokens.uniq.select {|w| w.length > 1 }

    if !@tokens.empty?
      # no more than 5 tokens to search for
      @tokens.slice! 5..-1 if @tokens.size > 5

      @results = []
      #@results_by_type = Hash.new {|h,k| h[k] = 0}
      @results_by_type = {}
      @non_event_results = {}
      @sum = 0
      limit = 10
      @scope.each do |s|
        r, c = s.singularize.camelcase.constantize.search(@tokens, projects_to_search,
          :all_words => @all_words,
          :titles_only => @titles_only,
          :limit => (limit+1),
          :offset => offset,
          :before => params[:previous].nil?)
        if s.singularize.camelcase.constantize.included_modules.include?(Redmine::Acts::Event::InstanceMethods)
          @results += r
        else
          @non_event_results[s] ||= []
          @non_event_results[s] += r
        end
        @results_by_type[s] = r
        @sum += c
      end
      
      @results_by_type.each do |type, results|
          if type.singularize.camelcase.constantize.included_modules.include?(Redmine::Acts::Event::InstanceMethods)
            results = results.sort {|a,b| 
            if a.respond_to?('event_datetime') && b.respond_to?('event_datetime')
              b.event_datetime <=> a.event_datetime 
            end
            }
          else
            results = results.sort{|a,b|
              if(@object_types_options[a.class.name.pluralize.downcase] && 
              @object_types_options[a.class.name.pluralize.downcase][:sort_function])
              
                b.send(@object_types_options[a.class.name.pluralize.downcase][:sort_function]) <=> 
                a.send(@object_types_options[a.class.name.pluralize.downcase][:sort_function])           
              else
                b <=> a 
              end
            }
          end
      end

      if params[:previous].nil?
        @pagination_previous_date = offset 
        @pagination_next_date = offset.to_i + limit.to_i
            
        @results_by_type.each do |type, results| 
          if results.size > limit
            results = results[offset, limit]
          end
        end
      else
        @pagination_next_date = offset.to_i + limit.to_i
        @pagination_previous_date = offset.to_i - limit.to_i < 0 ? offset.to_i : offset.to_i - limit.to_i
          
        @results_by_type.each do |type, results| 
          if results.size > limit
            results = results[offset, offset + limit]
          end
        end
      end

      @results = @results.sort {|a,b| 
        if a.respond_to?('event_datetime') && b.respond_to?('event_datetime')
          b.event_datetime <=> a.event_datetime 
        end
      }
      @non_event_results.each do |k,v| 
        v.sort{|a,b|
            if(@object_types_options[a.class.name.pluralize.downcase] && 
            @object_types_options[a.class.name.pluralize.downcase][:sort_function])
            
             b.send(@object_types_options[a.class.name.pluralize.downcase][:sort_function]) <=> 
             a.send(@object_types_options[a.class.name.pluralize.downcase][:sort_function])           
          else
            b <=> a 
          end
        }
      end

      #logger.info("#{self}respond_to?(:visible) :: #{respond_to?(:visible)}")
      #logger.info("Results #{@results}")
      #logger.info("Results #{@non_event_results}")

       # if params[:previous].nil?
       #   @pagination_previous_date = @results[0].event_datetime if offset && @results[0]
       #   if @results.size > limit
       #     @pagination_next_date = @results[limit-1].event_datetime
       #     @results = @results[0, limit]
       #   end
       # else
       #   @pagination_next_date = @results[-1].event_datetime if offset && @results[-1]
       #   if @results.size > limit
       #     @pagination_previous_date = @results[-(limit)].event_datetime
       #     @results = @results[-(limit), limit]
       #   end
       # end

    else
      @question = ""
    end
    render :layout => false if request.xhr?
  end

private
  def find_optional_project
    return true unless params[:id]
    @project = Project.find(params[:id])
    check_project_privacy
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
