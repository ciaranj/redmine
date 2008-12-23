module ScrumAlliance
  module Redmine
    module IssueRelationExtensions
      def self.included(klass)
        klass.const_set("TYPE_COMPOSES", 'composes')

        types = klass::TYPES.dup
        types[klass::TYPE_COMPOSES] = { :name => :label_includes, :sym_name => :label_belongs_to, :order => 5 }

        klass.send :remove_const, "TYPES"
        klass.const_set("TYPES", types)
        
        klass::TYPES.freeze
      end
    end # IssueRelationExtensions
  end # Redmine
end # ScrumAlliance