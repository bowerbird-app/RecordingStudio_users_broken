# frozen_string_literal: true

module RecordingStudioUsers
  class Policy
    ACTIONS = %i[provision show update search].freeze

    attr_reader :actor, :user, :record

    def initialize(actor:, user: nil, record: nil)
      @actor = actor
      @user = user
      @record = record
    end

    def allowed?(action)
      normalized = action.to_sym
      return false unless ACTIONS.include?(normalized)

      public_send("#{normalized}?")
    rescue NoMethodError, ArgumentError
      false
    end

    def provision?
      same_user?
    end

    def show?
      same_user?
    end

    def update?
      same_user?
    end

    def search?
      false
    end

    private

    def same_user?
      return false unless identifiable_users?
      return true if actor.equal?(user)

      polymorphic_type(actor) == polymorphic_type(user) && actor.id.to_s == user.id.to_s
    end

    def identifiable_users?
      persisted_identity?(actor) && persisted_identity?(user)
    end

    def persisted_identity?(record)
      record.respond_to?(:persisted?) && record.persisted? &&
        record.respond_to?(:id) && record.id.present?
    end

    def polymorphic_type(record)
      klass = record.class
      klass = klass.base_class if klass.respond_to?(:base_class)
      klass.name
    end
  end
end
