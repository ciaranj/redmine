class BurndownChart
  attr_accessor :dates, :version, :start_date
  
  delegate :to_s, :to => :chart
  
  def initialize(version)
    self.version = version
    
    self.start_date = version.created_on.to_date
    end_date = version.effective_date.to_date
    self.dates = (start_date..end_date).inject([]) { |accum, date| accum << date }
  end
  
  def chart
    Gchart.line(
      :size => '900x333', 
      :data => data,
      :axis_with_labels => 'x,y',
      :axis_labels => [dates.map {|d| d.strftime("%m-%d") }.join("|"), hours_left_labels],
      :line_colors => "DDDDDD,FF0000"
    )
  end
  
  def data
    [ideal_data, sprint_data]
  end
  
  def hours_left_labels
    (0..sprint_data.max).step(5) << (sprint_data.max + 5)
  end
  
  def sprint_data
    @sprint_data ||= dates.map do |date|
      issues = version.fixed_issues.select {|issue| issue.created_on.to_date <= date }
      issues.inject(0) do |total_hours_left, issue|
        journal = issue.journals.find(:first, 
          :conditions => ["created_on <= ?", date], 
          :order => "created_on desc", 
          :select => "journal_details.value", 
          :joins => "left join journal_details on journal_details.journal_id = journals.id and journal_details.prop_key = 'done_ratio'")
        
        ratio = journal ? journal.value.to_i : 0 # e.g. 70
        total_hours_left += (issue.estimated_hours.to_i * (100-ratio)/100)
      end
    end
  end
  
  def ideal_data
    hours = version.fixed_issues.map do |issue|
      journal = issue.journals.find(:first, 
        :conditions => ["created_on <= ?", start_date], 
        :order => "created_on desc", 
        :select => "journal_details.value",
        :joins => "left join journal_details on journal_details.journal_id = journals.id and journal_details.prop_key = 'estimated_hours'")
      
      journal ? journal.value.to_i : issue.estimated_hours.to_i
    end.sum
    
    [hours, 0]
  end
end