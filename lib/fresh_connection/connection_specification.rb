# frozen_string_literal: true
require 'active_support'
require 'active_support/core_ext'

module FreshConnection
  class ConnectionSpecification
    def initialize(spec_name, modify_spec: nil)
      @spec_name = spec_name.to_s
      @modify_spec = modify_spec.with_indifferent_access if modify_spec
    end

    def spec
      resolve.spec(@spec_name.to_sym)
    end

    private

    def resolve
      if defined?(ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver)
        ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver.new(build_config)
      elsif defined?(ActiveRecord::DatabaseConfigurations) && ActiveRecord::DatabaseConfigurations.method_defined?(:resolve)
        ActiveRecord::DatabaseConfigurations.new({}).resolve(build_config.to_h)
      else
        raise NotImplementedError
      end
    end

    def build_config
      puts base_config.class.name
      config = base_config.with_indifferent_access

      s_config = replica_config(config)
      config = config.merge(s_config) if s_config

      config = config.merge(@modify_spec) if defined?(@modify_spec)

      if defined?(ActiveRecord::DatabaseConfigurations)
        ActiveRecord::DatabaseConfigurations.new(@spec_name => config)
      else
        { @spec_name => config }
      end
    end

    def replica_config(config)
      if database_group_url
        config_from_url
      else
        config[@spec_name]
      end
    end

    def config_from_url
      connection_url_resolver_klass.new(database_group_url).to_hash
    end

    def base_config
      if ActiveRecord::Base.connection_pool.respond_to?(:spec)
        ActiveRecord::Base.connection_pool.spec.config
      elsif ActiveRecord::Base.connection_pool.respond_to?(:pool_config)
        ActiveRecord::Base.connection_pool.pool_config.db_config.configuration_hash
      else
        raise NotImplementedError
      end
    end

    def database_group_url
      ENV["DATABASE_#{@spec_name.upcase}_URL"]
    end

    def connection_url_resolver_klass
      if defined?(ActiveRecord::ConnectionAdapters::ConnectionSpecification::ConnectionUrlResolver)
        ActiveRecord::ConnectionAdapters::ConnectionSpecification::ConnectionUrlResolver
      elsif defined?(ActiveRecord::DatabaseConfigurations::ConnectionUrlResolver)
        ActiveRecord::DatabaseConfigurations::ConnectionUrlResolver
      else
        raise NotImplementedError
      end
    end
  end
end
