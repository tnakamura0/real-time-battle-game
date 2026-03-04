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

      # 2人揃い次第、最初のターンを作成して対戦開始の合図をフロントエンドに送信
      @match.turns.create!
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

  def play(data)
    selected_action = data["selectedHand"]

    current_turn = @match.turns.find_by(status: :waiting)

    return unless current_turn

    # サーバー側バリデーション
    return unless valid_action?(current_user, selected_action, current_turn.turn_number)

    if current_user.id == @match.player_1_id
      current_turn.update!(p1_action: selected_action)
      RoomChannel.broadcast_to(@room, { type: "player_ready", player: "p1" })
    elsif current_user.id == @match.player_2_id
      current_turn.update!(p2_action: selected_action)
      RoomChannel.broadcast_to(@room, { type: "player_ready", player: "p2" })
    end

    if current_turn.p1_action.present? && current_turn.p2_action.present?
      resolve_turn(current_turn)
    end
  end

  private

  def valid_action?(user, action, current_turn_number)
    is_p1 = (user.id == @match.player_1_id)

    # 判定に必要なステータスを取得
    my_energy       = is_p1 ? @match.p1_energy : @match.p2_energy
    opponent_energy = is_p1 ? @match.p2_energy : @match.p1_energy
    my_last_guard   = is_p1 ? @match.p1_last_guarded_turn : @match.p2_last_guarded_turn

    case action
    when "attack"
      # ルール：自分のエネルギーが0の時は攻撃できない
      my_energy > 0

    when "guard"
      # ルール：相手のエネルギーが0の時はガードできない
      return false if opponent_energy <= 0

      # ルール：設定したターン数を経過すると再びガードできる（クールダウン判定）
      if my_last_guard.present?
        # 例: turn 1でガードし、cooldownが 1 の場合
        # turn 2 の時: (2 - 1) = 1。1 > 1 は false (まだガード不可)
        # turn 3 の時: (3 - 1) = 2。2 > 1 は true (ガード可能)
        (current_turn_number - my_last_guard) > @room.guard_cooldown_turns
      else
        true # まだ一度もガードしていない場合はOK
      end

    when "charge"
      # ルール：チャージはいつでも選択可能（上限の5以上にならない制御は resolve_turn で実施済み）
      true

    else
      # 予期せぬ文字列（"hoge"など）が送られてきた場合は弾く
      false
    end
  end

  def resolve_turn(turn)
    # 現在のステータスを取得
    p1_action = turn.p1_action
    p2_action = turn.p2_action

    p1_hp = @match.p1_hp
    p2_hp = @match.p2_hp
    p1_energy = @match.p1_energy
    p2_energy = @match.p2_energy

    # エネルギーの計算
    new_p1_energy = calculate_energy(p1_action, p1_energy)
    new_p2_energy = calculate_energy(p2_action, p2_energy)

    # ダメージの計算
    # ルール上、ダメージが発生するのは「自分が攻撃し、かつ相手がチャージの時」のみ
    p1_damage = (p2_action == "attack" && p1_action == "charge") ? 1 : 0
    p2_damage = (p1_action == "attack" && p2_action == "charge") ? 1 : 0

    new_p1_hp = p1_hp - p1_damage
    new_p2_hp = p2_hp - p2_damage

    # ガード使用履歴の更新
    new_p1_last_guard = p1_action == "guard" ? turn.turn_number : @match.p1_last_guarded_turn
    new_p2_last_guard = p2_action == "guard" ? turn.turn_number : @match.p2_last_guarded_turn

    # 勝敗の判定
    match_status = :ongoing
    if new_p1_hp <= 0
      match_status = :player_2_won
    elsif new_p2_hp <= 0
      match_status = :player_1_won
    end

    # データベースの更新
    # トランザクションで確実に両方保存する
    ActiveRecord::Base.transaction do
      turn.update!(
        status: :finished,
        p1_hp_after: new_p1_hp,
        p2_hp_after: new_p2_hp,
        p1_energy_after: new_p1_energy,
        p2_energy_after: new_p2_energy
      )

      @match.update!(
        p1_hp: new_p1_hp,
        p2_hp: new_p2_hp,
        p1_energy: new_p1_energy,
        p2_energy: new_p2_energy,
        p1_last_guarded_turn: new_p1_last_guard,
        p2_last_guarded_turn: new_p2_last_guard,
        status: match_status
      )

      # 試合が続く場合は、次のターンを作成する
      if match_status == :ongoing
        @match.turns.create!(turn_number: turn.turn_number + 1)
      end
    end

    # フロントエンドへ結果をブロードキャスト
    RoomChannel.broadcast_to(@room, {
      type: "turn_resolved",
      turn_number: turn.turn_number,
      p1_action: p1_action,
      p2_action: p2_action,
      p1_hp: new_p1_hp,
      p2_hp: new_p2_hp,
      p1_energy: new_p1_energy,
      p2_energy: new_p2_energy,
      match_status: match_status
    })
  end

  # エネルギー計算用のヘルパーメソッド
  def calculate_energy(action, current_energy)
    if action == "charge"
      [ current_energy + 1, 5 ].min # 最大値5を保証
    elsif action == "attack"
      current_energy - 1
    else
      current_energy # guardの場合は増減なし
    end
  end
end
