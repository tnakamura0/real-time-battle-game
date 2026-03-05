class MatchesController < ApplicationController
  def index; end

  def show; end

  def result
    @match = Match.find(params[:id])

    redirect_to root_path, alert: "対戦が終了していません" if @match.status == "ongoing"

    redirect_to root_path, alert: "権限がありません" unless current_user.id == @match.player_1_id || current_user.id == @match.player_2_id
  end
end
