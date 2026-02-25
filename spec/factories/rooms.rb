FactoryBot.define do
  factory :room do
    token { "MyString" }
    passcord { "MyString" }
    initial_hp { 1 }
    guard_cooldown_turns { 1 }
    status { 1 }
    owner { nil }
  end
end
