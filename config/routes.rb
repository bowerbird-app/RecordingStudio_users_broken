# frozen_string_literal: true

RecordingStudioUsers::Engine.routes.draw do
  root "home#index"
  resource :profile, only: %i[show edit update], controller: "profiles"
end
