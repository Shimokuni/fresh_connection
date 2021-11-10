# frozen_string_literal: true

module FreshConnection
  module Extend
    module DatabaseConfigurations
      def resolve(*args)
        db_config = super

        case db_config.configuration_hash[:adapter].to_s
        when "mysql", "mysql2"
          require 'fresh_connection/extend/adapters/m2_adapter'
          __extend_adapter_by_fc(::ActiveRecord::ConnectionAdapters::Mysql2Adapter, M2Adapter)
        when "postgresql"
          require 'fresh_connection/extend/adapters/pg_adapter'
          __extend_adapter_by_fc(::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter, PgAdapter)
        else
          raise NotImplementedError, "This adapter('#{db_config.configuration_hash[:adapter]}') is not supported. If you specified the mysql or postgres adapter, it's probably a bug in FreshConnection. Please teach me (https://github.com/tsukasaoishi/fresh_connection/issues/new)"
        end

        db_config
      end

      def __extend_adapter_by_fc(klass, extend_adapter)
        return if klass.include?(extend_adapter)
        klass.prepend BaseAdapter
        klass.prepend extend_adapter
      end
    end
  end
end
