class Room < ApplicationRecord
  enum status: { waiting: 0, playing: 1, finished: 2 }
  
  validates :token, presence: true
  validates :passcode, presence: true
  validates :initial_hp, presence: true
  validates :guard_cooldown_turns, presence: true
  validates :status, presence: true

  belongs_to :owner, class_name: "User"
end
