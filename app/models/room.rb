class Room < ApplicationRecord
  has_secure_token :token

  before_validation :generate_passcode, on: :create

  enum :status, { waiting: 0, playing: 1, finished: 2 }

  validates :passcode, presence: true
  validates :initial_hp, presence: true
  validates :guard_cooldown_turns, presence: true
  validates :status, presence: true

  belongs_to :owner, class_name: "User"
  has_many :matches, dependent: :nullify

  private

  def generate_passcode
    return if passcode.present?

    loop do
      self.passcode = SecureRandom.random_number(10**4).to_s.rjust(4, "0")
      break unless Room.exists?(passcode: self.passcode)
    end
  end
end
