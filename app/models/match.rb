class Match < ApplicationRecord
  enum :status, { ongoing: 0, player_1_won: 1, player_2_won: 2 }

  belongs_to :room, optional: true
  belongs_to :player_1, class_name: "User", optional: true
  belongs_to :player_2, class_name: "User", optional: true
end
