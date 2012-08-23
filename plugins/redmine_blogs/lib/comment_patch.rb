module RedmineBlogs
  module CommentPatch
    extend ActiveSupport::Concern

    included do
      class_eval do
        unloadable
      end
    end

    module ClassMethods
    end

    def attachments
      commented.respond_to?(:attachments) ? commented.attachments : nil
    end
  end
end
