# frozen_string_literal: true

module Toqua
  module Scoping
    extend ActiveSupport::Concern

    def apply_scopes(start)
      s = start
      self.class.__scopes.each do |scope, opts|
        s = __run_scope(s, scope, opts)
      end
      s
    end

    class ScopeApplicable
      def self.accept?(opts, context)
        if_condition(context, opts) && action_condition(context, opts)
      end

      def self.action_condition(context, opts)
        if opts[:only]
          [opts[:only]].flatten.include?(context.action_name.to_sym)
        else
          true
        end
      end

      def self.if_condition(context, opts)
        if opts[:if]
          !!evaluate(context, opts[:if])
        elsif opts[:unless]
          !evaluate(context, opts[:unless])
        else
          true
        end
      end

      def self.evaluate(context, object)
        if object.respond_to?(:call)
          context.instance_exec(&object)
        else
          context.send(object)
        end
      end
    end

    def __run_scope(relation, scope, opts)
      if ScopeApplicable.accept?(opts, self)
        instance_exec(relation, &scope)
      else
        relation
      end
    end

    included do
      class_attribute(:__scopes)
      self.__scopes = []
    end

    class_methods do
      def scope(opts = {}, &block)
        self.__scopes += [[block, opts]]
      end
    end
  end
end
