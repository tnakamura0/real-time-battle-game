FactoryBot.define do
  factory :match do
    p1_hp { 1 }
    p2_hp { 1 }
    p1_energy { 1 }
    p2_energy { 1 }
    p1_last_guarded_turn { 1 }
    p2_last_guarded_turn { 1 }
    status { 1 }
    room { nil }
    player_1 { nil }
    player_2 { nil }
  end
end
