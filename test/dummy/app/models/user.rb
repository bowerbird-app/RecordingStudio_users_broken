class User < ApplicationRecord
  include RecordingStudioUsers::User

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end
