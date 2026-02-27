class RoomChannel < ApplicationCable::Channel
  def subscribed
    @room = Room.find_by(token: params[:token])

    return reject unless @room

    # 進行中の試合を取得
    # まだ試合がなければ、ホストをplayer_1として新しい試合を作成
    @match =
      @room.matches.find_by(status: :ongoing) || @room.matches.create(player_1: @room.owner, status: :ongoing, p1_hp: @room.initial_hp, p2_hp: @room.initial_hp)

    # ==== 接続してきたユーザーの判定と振り分け ====

    if current_user.id == @room.owner_id
      # ホストの接続
      stream_for @room

    elsif @match.player_2_id.nil?
      # Player2の枠が空いていたら対戦相手として接続
      @match.update!(player_2: current_user)
      stream_for @room

      # 2人揃い次第、対戦開始の合図をフロントエンドに送信
      RoomChannel.broadcast_to(@room, { type: "match_started", match_id: @match.id })

    elsif current_user.id == @match.player_2_id
      # Player2の再接続
      stream_for @room

    else
      # 3人目の接続は拒否する
      reject
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
