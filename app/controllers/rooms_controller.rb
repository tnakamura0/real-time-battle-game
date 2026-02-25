class RoomsController < ApplicationController
  def new
    @room = Room.new(initial_hp: 3, guard_cooldown_turns: 1)
  end

  def create
    @room = current_user.build_owned_room(room_params)
    if @room.save
      redirect_to room_path(@room.token), success: t("defaults.flash_message.created", item: Room.model_name.human)
    else
      flash.now[:danger] = t("defaults.flash_message.not_created", item: Room.model_name.human)
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @room = Room.find_by!(token: params[:id])
  end

  private

  def room_params
    params.require(:room).permit(:initial_hp, :guard_cooldown_turns)
  end
end
