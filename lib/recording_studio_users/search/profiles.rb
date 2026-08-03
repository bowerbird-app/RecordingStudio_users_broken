# frozen_string_literal: true

module RecordingStudioUsers
  module Search
    class Profiles
      SEARCH_COLUMNS = %w[display_name given_name family_name].freeze
      MAX_QUERY_LENGTH = 200

      class << self
        def call(actor:, query:, limit: nil)
          RecordingStudioUsers.authorize!(:search, actor: actor)

          normalized_query = normalize_query(query)
          normalized_limit = normalize_limit(limit)
          relation = current_profiles
          return relation.none if normalized_query.blank?

          result = execute_search(relation.limit(normalized_limit), normalized_query, normalized_limit)
          constrain_result(relation, result, normalized_limit)
        end

        private

        def current_profiles
          recordings = RecordingStudio::Recording.unscoped.where(recordable_type: "RecordingStudioUsers::Profile")
          if RecordingStudio::Recording.column_names.include?("trashed_at")
            active_recording_ids = RecordingStudio::Recording.unscoped.where(trashed_at: nil).select(:id)
            recordings = recordings.where(trashed_at: nil, root_recording_id: active_recording_ids)
          end

          current_profile_ids = recordings.select(:recordable_id)
          RecordingStudioUsers::Profile.where(id: current_profile_ids)
        end

        def default_search(relation, query)
          escaped_query = ActiveRecord::Base.sanitize_sql_like(query.downcase)
          predicate = SEARCH_COLUMNS.map { |column| "LOWER(COALESCE(#{column}, '')) LIKE :query" }.join(" OR ")

          relation.where(predicate, query: "%#{escaped_query}%").order(:display_name, :id)
        end

        def execute_search(relation, query, limit)
          searcher = RecordingStudioUsers.configuration.profile_searcher
          return default_search(relation, query) unless searcher

          searcher.call(query: query, relation: relation, limit: limit)
        end

        def normalize_query(query)
          value = query.to_s.squish
          raise ContractError, "profile search query is too long" if value.length > MAX_QUERY_LENGTH

          value
        end

        def normalize_limit(limit)
          value = limit.nil? ? RecordingStudioUsers.configuration.profile_search_limit : Integer(limit)
          return value if value.between?(1, Configuration::MAX_PROFILE_SEARCH_LIMIT)

          raise ContractError, "profile search limit is out of range"
        rescue ArgumentError, TypeError
          raise ContractError, "profile search limit must be an integer"
        end

        def constrain_result(relation, result, limit)
          ids = result_ids(result, limit)
          relation.where(id: ids).limit(limit)
        end

        def result_ids(result, limit)
          return relation_result_ids(result, limit) if result.is_a?(ActiveRecord::Relation)

          records = result.respond_to?(:first) ? result.first(limit) : nil
          unless records.respond_to?(:all?) && records.all? { |record| record.is_a?(RecordingStudioUsers::Profile) }
            raise ContractError, "profile_searcher must return profiles or a profile relation"
          end

          records.map(&:id)
        end

        def relation_result_ids(result, limit)
          unless result.klass <= RecordingStudioUsers::Profile
            raise ContractError, "profile_searcher relation must contain profiles"
          end

          result.reselect(:id).limit(limit)
        end
      end
    end
  end
end
