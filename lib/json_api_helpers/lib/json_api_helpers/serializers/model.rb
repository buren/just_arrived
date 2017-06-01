# frozen_string_literal: true

require 'json_api_helpers/action_dispatch_request_wrapper'

module JsonApiHelpers
  module Serializers
    class Model
      attr_reader :serializer, :included, :fields, :current_user, :current_language, :model_scope, :meta, :request, :key_transform # rubocop:disable Metrics/LineLength

      def self.serialize(*args)
        new(*args).serialize
      end

      # private

      def initialize(
        model_scope,
        included: [],
        fields: {},
        current_user: nil,
        current_language: nil,
        meta: {},
        request: nil,
        key_transform: JsonApiHelpers.config.key_transform
      )
        @model_scope = model_scope
        @included = included
        @fields = fields
        @meta = meta
        @current_user = current_user
        @current_language = current_language
        @key_transform = key_transform
        # NOTE: ActiveModel::Serializer#serializer_for is from active_model_serializers
        @serializer = ActiveModel::Serializer.serializer_for(model_scope)
        @request = ActionDispatchRequestWrapper.new(request)
      end

      def serializer_instance
        serializer_options = {
          scope: {
            current_user: current_user,
            current_language: current_language,
            current_language_id: current_language&.id
          }
        }

        if @model_scope.respond_to?(:to_ary)
          serializer_options[:each_serializer] = serializer
        end

        serializer.new(@model_scope, serializer_options)
      end

      def serialize
        # NOTE: ActiveModelSerializers::Adapter#create is from active_model_serializers
        ActiveModelSerializers::Adapter.create(
          serializer_instance,
          key_transform: key_transform,
          include: included,
          fields: fields,
          meta: meta,
          serialization_context: request
        )
      end
    end
  end
end
