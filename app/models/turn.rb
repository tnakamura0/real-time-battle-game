class Turn < ApplicationRecord
  enum :status, { waiting: 0, finished: 1 }
  enum :p1_action, { charge: 0, attack: 1, guard: 2 }, prefix: true
  enum :p2_action, { charge: 0, attack: 1, guard: 2 }, prefix: true

  belongs_to :match
end
