class RoomsController < ApplicationController
  def new
    @room = Room.new(initial_hp: 3, guard_cooldown_turns: 1)
  end

  def create
  end

  def show
  end
end
