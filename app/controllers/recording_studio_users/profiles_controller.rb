# frozen_string_literal: true

module RecordingStudioUsers
  class ProfilesController < ApplicationController
    before_action :authenticate_actor!

    def show
      @user = current_actor
      @profile = RecordingStudioUsers.profile_for(@user)
      return if @profile

      redirect_to edit_profile_path, alert: "Profile not found"
    end

    def edit
      @user = current_actor
      @profile = RecordingStudioUsers.profile_for(@user)
      @profile ||= RecordingStudioUsers.provision(@user, actor: current_actor).current_profile
    end

    def update
      @user = current_actor
      RecordingStudioUsers.revise_profile(
        user: @user,
        actor: current_actor,
        attributes: profile_params
      )

      redirect_to profile_path, notice: "Profile updated"
    rescue RecordingStudioUsers::Error, ActiveRecord::RecordInvalid, ArgumentError => e
      @profile = RecordingStudioUsers.profile_for(@user)
      flash.now[:alert] = e.message
      render :edit, status: :unprocessable_entity
    end

    private

    def profile_params
      params.require(:profile).permit(:display_name, :biography, :locale, :time_zone)
    end

    def current_actor
      return current_user if respond_to?(:current_user)
      return Current.actor if defined?(Current) && Current.respond_to?(:actor)

      nil
    end

    def authenticate_actor!
      return if current_actor.present?
      return authenticate_user! if respond_to?(:authenticate_user!)

      head :unauthorized
    end
  end
end
