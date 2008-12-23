module ScrumAlliance
  module Redmine
    module IssueExtensions
      def story
        story = relations_to.detect {|rel| rel.relation_type == 'composes' }
        story && story.issue_from
      end
    end # IssueExtensions
  end # Redmine
end # ScrumAlliance