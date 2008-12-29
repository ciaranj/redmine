module ScrumAlliance
  module Redmine
    module IssueExtensions
      def story
        story = relations_to.detect {|rel| rel.relation_type == 'composes' }
        story && story.issue_from
      end
      
      def tasks
        tasks = relations_from.select { |rel| rel.relation_type == "composes" }
        tasks && tasks.map(&:issue_to)
      end

      def done_ratio
        return read_attribute(:done_ratio) if tasks.blank?
        total_estimate = tasks.sum(&:estimated_hours)
        hours_done = tasks.sum { |t| t.estimated_hours * (t.done_ratio / 100.0) }
        100 - (((total_estimate - hours_done) / total_estimate) * 100).to_i
      end
    end # IssueExtensions
  end # Redmine
end # ScrumAlliance
