# frozen_string_literal: true

module Bayarcash
  module Resources
    # Base data-transfer object for API responses.
    #
    # Attributes are populated from the (snake_case) keys of the API payload and
    # exposed as reader methods. Declared attributes always respond (returning nil
    # when the API omits them); any unknown field the API returns is captured too,
    # so the DTOs are tolerant of new or missing fields.
    class Resource
      # Declare known attributes for a resource subclass. Each becomes a reader that
      # returns nil when absent.
      #
      # @param names [Array<Symbol, String>]
      def self.attributes(*names)
        @declared_attributes ||= []
        names.each do |name|
          key = name.to_s
          @declared_attributes << key unless @declared_attributes.include?(key)
          define_method(key) { @attributes[key] }
        end
      end

      # @return [Array<String>] declared attribute names, including inherited ones
      def self.declared_attributes
        inherited = superclass.respond_to?(:declared_attributes) ? superclass.declared_attributes : []
        inherited + (@declared_attributes || [])
      end

      # @param attributes [Hash] the API payload
      # @param bayarcash [Bayarcash::Client, nil] owning client (never serialized)
      def initialize(attributes = {}, bayarcash = nil)
        @bayarcash = bayarcash
        @attributes = {}
        fill(attributes)
      end

      # Read a raw attribute by key (string or symbol).
      #
      # @param key [String, Symbol]
      # @return [Object, nil]
      def [](key)
        @attributes[key.to_s]
      end

      # @return [Hash{String => Object}] the attributes, with nested resources converted
      def to_h
        @attributes.each_with_object({}) do |(key, value), memo|
          memo[key] = deep_to_h(value)
        end
      end
      alias to_array to_h
      alias to_hash to_h

      def respond_to_missing?(name, include_private = false)
        key = name.to_s
        @attributes.key?(key) || self.class.declared_attributes.include?(key) || super
      end

      def method_missing(name, *args)
        key = name.to_s
        if @attributes.key?(key) || self.class.declared_attributes.include?(key)
          @attributes[key]
        else
          super
        end
      end

      private

      def fill(attributes)
        (attributes || {}).each do |key, value|
          @attributes[key.to_s] = value
        end
      end

      def deep_to_h(value)
        case value
        when Resource
          value.to_h
        when Array
          value.map { |item| item.is_a?(Resource) ? item.to_h : item }
        else
          value
        end
      end
    end
  end
end
