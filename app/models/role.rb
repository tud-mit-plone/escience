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

class Role < ActiveRecord::Base
  # Built-in roles
  BUILTIN_NON_MEMBER = 1
  BUILTIN_ANONYMOUS  = 2
  BUILTIN_OWNER      = 3
  BUILTIN_MEMBER     = 4

  ISSUES_VISIBILITY_OPTIONS = [
    ['all', :label_issues_visibility_all],
    ['default', :label_issues_visibility_public],
    ['own', :label_issues_visibility_own]
  ]

  serialize :permissions, Array

  scope :sorted, order("#{table_name}.builtin ASC, #{table_name}.position ASC")
  scope :givable, order("#{table_name}.position ASC").where("builtin != ?", BUILTIN_NON_MEMBER).where("builtin != ?", BUILTIN_ANONYMOUS)
  scope :builtin, lambda { |*args|
    compare = (args.first == true ? 'not' : '')
    where("#{compare} builtin = 0")
  }

  before_destroy :check_deletable
  has_many :workflow_rules, :dependent => :delete_all do
    def copy(source_role)
      WorkflowRule.copy(nil, source_role, nil, proxy_association.owner)
    end
  end

  has_many :member_roles, :dependent => :destroy
  has_many :members, :through => :member_roles
  acts_as_list

  attr_protected :builtin

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_length_of :name, :maximum => 30
  validates_inclusion_of :issues_visibility,
    :in => ISSUES_VISIBILITY_OPTIONS.collect(&:first),
    :if => lambda {|role| role.respond_to?(:issues_visibility)}


  # Copies attributes from another role, arg can be an id or a Role
  def copy_from(arg, options={})
    return unless arg.present?
    role = arg.is_a?(Role) ? arg : Role.find_by_id(arg.to_s)
    self.attributes = role.attributes.dup.except("id", "name", "position", "builtin", "permissions")
    self.permissions = role.permissions.dup
    self
  end

  def add_permission!(*perms)
    self.permissions = [] unless permissions.is_a?(Array)

    permissions_will_change!
    perms.each do |p|
      p = p.to_sym
      permissions << p unless permissions.include?(p)
    end
    save!
  end

  def remove_permission!(*perms)
    return unless permissions.is_a?(Array)
    permissions_will_change!
    perms.each { |p| permissions.delete(p.to_sym) }
    save!
  end

  # Returns true if the role has the given permission
  def has_permission?(perm)
    !permissions.nil? && permissions.include?(perm.to_sym)
  end

  def <=>(role)
    if role
      if builtin == role.builtin
        position <=> role.position
      else
        builtin <=> role.builtin
      end
    else
      -1
    end
  end

  def to_s
    name
  end

  def name
    case builtin
    when Role::BUILTIN_NON_MEMBER; l(:label_role_non_member, :default => read_attribute(:name))
    when Role::BUILTIN_ANONYMOUS; l(:label_role_anonymous,  :default => read_attribute(:name))
    when Role::BUILTIN_OWNER; l(:label_role_owner,  :default => read_attribute(:name))
    when Role::BUILTIN_MEMBER; l(:label_role_member,  :default => read_attribute(:name))
    else; read_attribute(:name)
    end
  end

  # Return true if the role is a builtin role
  def builtin?
    self.builtin != 0
  end

  # Return true if the role is the anonymous role
  def anonymous?
    builtin == 2
  end

  def owner?
    builtin == Role::BUILTIN_OWNER
  end

  # Return true if the role is a project member role
  def member?
    self.builtin? != Role::BUILTIN_ANONYMOUS && self.builtin != Role::BUILTIN_NON_MEMBER
  end

  # Return true if role is allowed to do the specified action
  # action can be:
  # * a parameter-like Hash (eg. :controller => 'projects', :action => 'edit')
  # * a permission Symbol (eg. :edit_project)
  def allowed_to?(action)
    if action.is_a? Hash
      allowed_actions.include? "#{action[:controller]}/#{action[:action]}"
    else
      allowed_permissions.include? action
    end
  end

  # Return all the permissions that can be given to the role
  def setable_permissions
    setable_permissions = Redmine::AccessControl.permissions - Redmine::AccessControl.public_permissions
    setable_permissions -= Redmine::AccessControl.members_only_permissions if self.builtin == BUILTIN_NON_MEMBER
    setable_permissions -= Redmine::AccessControl.loggedin_only_permissions if self.builtin == BUILTIN_ANONYMOUS
    setable_permissions
  end

  # Find all the roles that can be given to a project member
  def self.find_all_givable
    Role.givable.all
  end

  # Return the builtin 'non member' role.  If the role doesn't exist,
  # it will be created on the fly.
  def self.non_member
    find_or_create_system_role(BUILTIN_NON_MEMBER, 'Non member')
  end

  # Return the builtin 'anonymous' role.  If the role doesn't exist,
  # it will be created on the fly.
  def self.anonymous
    find_or_create_system_role(BUILTIN_ANONYMOUS, 'Anonymous')
  end

  def self.owner
    find_or_create_system_role(BUILTIN_OWNER, 'Owner')
  end

  def self.member
    find_or_create_system_role(BUILTIN_MEMBER, 'Member')
  end

  def self.default_permissions(role)
    permissions = case role
    when BUILTIN_ANONYMOUS
      []
    when BUILTIN_NON_MEMBER
      Role.perms([:add_project, :view_issues])
    when BUILTIN_OWNER
      Role.perms([:add_project, :manage_members, :add_subprojects, :view_calendar, :edit_project,
                  :select_project_modules, :manage_versions, :group_invitations_create]) \
      + Role.perms([:manage_boards, :edit_messages, :delete_messages, :add_messages,
                    :edit_own_messages, :delete_own_messages]) \
      + Role.perms([:view_calendar]) \
      + Role.perms([:manage_documents, :view_documents]) \
      + Role.perms([:manage_doodles, :delete_doodles, :create_doodles, :answer_doodles, :view_doodles]) \
      + Role.perms([:manage_files, :view_files]) \
      + Role.perms([:view_gantt]) \
      + Role.perms([:manage_categories, :view_issues, :add_issues, :edit_issues, :manage_issue_relations,
                    :manage_subtasks, :set_issues_private, :set_own_issues_private, :add_issue_notes,
                    :edit_issue_notes, :edit_own_issue_notes, :move_issues, :delete_issues,
                    :manage_public_queries, :save_queries, :view_issue_watchers, :add_issue_watchers,
                    :delete_issue_watchers]) \
      + Role.perms([:manage_news, :comment_news]) \
      + Role.perms([:log_time, :view_time_entries, :edit_time_entries, :edit_own_time_entries,
                    :manage_project_activities]) \
      + Role.perms([:appointments_create, :appointments_add_watchers, :group_invitations_create]) \
      + Role.perms([:manage_wiki, :rename_wiki_pages, :delete_wiki_pages, :view_wiki_pages,
                    :export_wiki_pages, :view_wiki_edits, :edit_wiki_pages, :delete_wiki_pages_attachments,
                    :protect_wiki_pages])
    when BUILTIN_MEMBER
      Role.perms([:view_calendar]) \
      + Role.perms([:add_messages, :edit_own_messages]) \
      + Role.perms([:view_calendar]) \
      + Role.perms([:manage_documents, :view_documents]) \
      + Role.perms([:manage_doodles, :delete_doodles, :create_doodles, :answer_doodles, :view_doodles]) \
      + Role.perms([:manage_files, :view_files]) \
      + Role.perms([:view_gantt]) \
      + Role.perms([:view_issues, :add_issues, :edit_issues, :manage_issue_relations, :manage_subtasks,
                    :add_issue_notes, :edit_own_issue_notes, :save_queries, :delete_issue_watchers]) \
      + Role.perms([:comment_news]) \
      + Role.perms([:log_time, :view_time_entries, :edit_own_time_entries]) \
      + Role.perms([:rename_wiki_pages, :delete_wiki_pages, :view_wiki_pages, :view_wiki_edits,
                    :edit_wiki_pages, :delete_wiki_pages_attachments, :protect_wiki_pages])
    end
    return permissions.map {|p| p.name}
  end

private

  def allowed_permissions
    @allowed_permissions ||= permissions + Redmine::AccessControl.public_permissions.collect {|p| p.name}
  end

  def allowed_actions
    @actions_allowed ||= allowed_permissions.inject([]) { |actions, permission| actions += Redmine::AccessControl.allowed_actions(permission) }.flatten
  end

  def check_deletable
    raise "Can't delete role" if members.any?
    raise "Can't delete builtin role" if builtin?
  end

  def self.find_or_create_system_role(builtin, name)
    role = where(:builtin => builtin).first
    if role.nil?
      permissions = self.default_permissions(builtin)
      role = create(:name => name, :position => 0) do |r|
        r.permissions = permissions
        r.builtin = builtin
      end
      raise "Unable to create the #{name} role." if role.new_record?
    end
    role
  end

  def self.create_system_roles
    self.anonymous
    self.non_member
    self.member
    self.owner
  end

  def self.perms(what=nil)
    if what.class == Symbol
      return [Redmine::AccessControl.permission(what)]
    elsif what.class == Array
      return what.map {|name| Redmine::AccessControl.permission(name)}
    end
  end


end
