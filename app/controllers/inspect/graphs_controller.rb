# frozen_string_literal: true

module Inspect
  class GraphsController < ApplicationController
    skip_after_action :verify_policy_scoped
    before_action :set_object
    before_action :set_show_pii
    before_action :record_access_log_entry

    layout "full"

    SHOW_PII_BY_DEFAULT = false

    def show
      # Set default relationships when loading a page
      if params[:relationships].blank? &&
           GraphRecords::DEFAULT_TRAVERSALS.key?(@primary_type)
        default_rels = GraphRecords::DEFAULT_TRAVERSALS[@primary_type] || {}
        # Merge the default relationships and any additional_ids already provided.
        new_params = params.to_unsafe_h.merge("relationships" => default_rels)
        redirect_to inspect_path(new_params) and return
      end

      # Generate graph
      @traversals_config = build_traversals_config
      @graph_params = build_graph_params
      @show_pii = params[:show_pii]&.first == "1"

      @mermaid =
        GraphRecords
          .new(
            traversals_config: build_traversals_config,
            primary_type: @primary_type,
            clickable: true,
            show_pii: @show_pii
          )
          .graph(**@graph_params)
          .join("\n")
    end

    private

    def set_pii_settings
      @user_is_allowed_to_access_pii = user_is_support_with_pii_access?
      @show_pii = if @user_is_allowed_to_access_pii
                    params[:show_pii]&.first == "true" || SHOW_PII_BY_DEFAULT
                  else
                    false
                  end
    end

    def build_traversals_config
      traversals_config = {}
      to_process = Set.new([@primary_type])
      processed = Set.new

      # Process types until we've explored all connected relationships
      while (type = to_process.first)
        to_process.delete(type)
        processed.add(type)

        # Get selected relationships for this type
        selected_rels =
          Array(params.dig(:relationships, type)).reject(&:blank?).map(&:to_sym)

        # Add this type and its relationships to the config
        traversals_config[type] = selected_rels

        # Add target types to process queue
        klass = type.to_s.classify.constantize
        selected_rels.each do |rel|
          association = klass.reflect_on_association(rel)
          next unless association

          target_type = association.klass.name.underscore.to_sym
          to_process.add(target_type) unless processed.include?(target_type)
        end
      end

      traversals_config
    end

    def build_graph_params
      # Build the graph params
      graph_params = { @primary_type => [@object.id] }

      # Add additional IDs from the form
      if params[:additional_ids].present?
        params[:additional_ids].each do |type, ids_string|
          next if ids_string.blank?
          additional_ids = ids_string.split(",").map { |s| s.strip.to_i }
          next unless additional_ids.any?
          type_sym = type.to_sym
          graph_params[type_sym] ||= []
          graph_params[type_sym].concat(additional_ids)
        end
      end

      graph_params
    end

    def safe_get_primary_type
      singular_type = params[:object_type].downcase.singularize
      return nil unless GraphRecords::ALLOWED_TYPES.include?(singular_type)
      singular_type.to_sym
    end

    def pii_accessed?
      return false unless @show_pii

      additional_types = Array(params[:additional_ids].keys).map(&:to_sym)
      return true if additional_types.any? { |type| GraphRecords::DETAIL_WHITELIST_PII.key?(type) }

      build_traversals_config.values.flatten.any? do |rel|
        type = @primary_type.to_s.classify.constantize
        rel_class = type.reflect_on_association(rel)&.klass
        rel_class && GraphRecords::DETAIL_WHITELIST_PII.key?(rel_class.name.underscore.to_sym)
      end
    end


    def record_access_log_entry
      if pii_accessed? && @primary_type == :patient
        patient = Patient.find(@primary_id)

        # Build request details hash for ALL fields being accessed
        request_details = build_request_details

        patient.access_log_entries.create!(
          user: current_user,
          controller: "graph",
          action: "show_pii",
          request_details: request_details
        )
      end
    end

    def build_request_details
      details = {}

      # Process additional IDs
      Array(params[:additional_ids]&.keys).each do |type|
        add_fields_to_details(details, type.to_sym)
      end

      # Process traversal relationships
      build_traversals_config.each do |type, relationships|
        relationships.each do |rel|
          binding.irb
          next unless rel_class = type.to_s.classify.constantize.reflect_on_association(rel)&.klass

          rel_type = rel_class.name.underscore.to_sym
          add_fields_to_details(details, rel_type)
        end
      end

      details
    end

    def add_fields_to_details(details, type_sym)
      all_fields = GraphRecords::DETAIL_WHITELIST[type_sym]
      all_fields += GraphRecords::DETAIL_WHITELIST_PII[type_sym] if GraphRecords::DETAIL_WHITELIST_PII.key?(type_sym)
      details[type_sym] = all_fields.uniq if all_fields.any?
    end
  end
end
