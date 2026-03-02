FactoryBot.define do
  factory :turn do
    turn_number { 1 }
    p1_action { 1 }
    p2_action { 1 }
    status { 1 }
    p1_hp_after { 1 }
    p2_hp_after { 1 }
    p1_energy_after { 1 }
    p2_energy_after { 1 }
    match { nil }
  end
end
