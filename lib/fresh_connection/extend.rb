# frozen_string_literal: true
require 'active_support'

ActiveSupport.on_load(:active_record) do
  if respond_to?(:connection_handlers) && connection_handlers.empty?
    self.connection_handlers = { writing_role => ActiveRecord::Base.default_connection_handler }
  end

  require 'fresh_connection/extend/ar_base'
  require 'fresh_connection/extend/ar_relation'
  require 'fresh_connection/extend/ar_relation_merger'
  require 'fresh_connection/extend/ar_statement_cache'
  require 'fresh_connection/extend/ar_resolver'

  ActiveRecord::Base.extend FreshConnection::Extend::ArBase
  ActiveRecord::Relation.prepend FreshConnection::Extend::ArRelation
  ActiveRecord::Relation::Merger.prepend FreshConnection::Extend::ArRelationMerger
  ActiveRecord::StatementCache.prepend FreshConnection::Extend::ArStatementCache
  ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver.prepend(
    FreshConnection::Extend::ArResolver
  )
end
