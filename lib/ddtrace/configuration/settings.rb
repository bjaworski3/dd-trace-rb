require 'ddtrace/ext/analytics'
require 'ddtrace/ext/runtime'
require 'ddtrace/configuration/options'

require 'ddtrace/environment'
require 'ddtrace/tracer'
require 'ddtrace/metrics'

module Datadog
  module Configuration
    # Global configuration settings for the trace library.
    class Settings
      extend Datadog::Environment::Helpers
      include Options

      option  :analytics_enabled,
              default: -> { env_to_bool(Ext::Analytics::ENV_TRACE_ANALYTICS_ENABLED, nil) },
              lazy: true

      option  :runtime_metrics_enabled,
              default: -> { env_to_bool(Ext::Runtime::Metrics::ENV_ENABLED, false) },
              lazy: true

      option :tracer, default: Tracer.new

      def initialize(options = {})
        configure(options)
      end

      def configure(options = {})
        self.class.options.dependency_order.each do |name|
          next unless options.key?(name)
          respond_to?("#{name}=") ? send("#{name}=", options[name]) : set_option(name, options[name])
        end

        yield(self) if block_given?
      end

      def runtime_metrics(options = nil)
        runtime_metrics = get_option(:tracer).writer.runtime_metrics
        return runtime_metrics if options.nil?

        runtime_metrics.configure(options)
      end

      # Backwards compatibility for configuring tracer e.g. `c.tracer debug: true`
      remove_method :tracer
      def tracer(options = nil)
        tracer = options && options.key?(:instance) ? set_option(:tracer, options[:instance]) : get_option(:tracer)

        tracer.tap do |t|
          unless options.nil?
            t.configure(options)
            t.class.log = options[:log] if options[:log]
            t.set_tags(options[:tags]) if options[:tags]
            t.set_tags(env: options[:env]) if options[:env]
            t.class.debug_logging = options.fetch(:debug, false)
          end
        end
      end
    end
  end
end
