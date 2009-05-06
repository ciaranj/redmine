module ScrumAlliance
  module Redmine
    module AddExtraClassesToIssueExtension
      def self.included(klass)
        klass.class_eval do
          alias_method_chain :css_classes, :tracker_name
        end
      end
      def css_classes_with_tracker_name
        "#{css_classes_without_tracker_name} type-#{@tracker.name.downcase}"
      end    
    end # AddExtraClassesToIssueExtension
  end # Redmine
end # ScrumAlliance