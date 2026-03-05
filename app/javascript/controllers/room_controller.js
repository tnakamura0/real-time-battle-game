import { Controller } from "@hotwired/stimulus"
import consumer from "../channels/consumer"

// Connects to data-controller="room"
export default class extends Controller {
  static targets = [
    "waiting", "matchStartEffect", "battleBoard", "turnResultEffect",
    "chargeButton", "attackButton", "guardButton",
    "myStatus", "opponentStatus",
    "myActionDisplay", "opponentActionDisplay", "resultMessageDisplay"
  ];

  static values = {
    token: String,
    isP1: Boolean,
    guardCooldown: Number
  };

  initialize() {
    this.currentTurn = 1;
    this.myLastGuardTurn = null;
  }

  connect() {
    this.subscription = consumer.subscriptions.create(
      { channel: "RoomChannel", token: this.tokenValue },
      {
        connected: () => {
          console.log(`部屋（${this.tokenValue}）に接続しました！`);
        },
        disconnected: () => {
          console.log("切断されました");
        },
        received: (data) => {
          if (data.type === "match_started") {
            console.log(`対戦開始！（Match ID: ${data.match_id}）`);
            this.showMatchStartEffect();
            this.updateButtonStates(0, 0);
            this.resetPlayerStatuses();
          }

          if (data.type === "player_ready") {
            const isReadyPlayerMe = (this.isP1Value && data.player === "p1") || (!this.isP1Value && data.player === "p2");

            console.log(`isReadyPlayerMe: ${isReadyPlayerMe}`);

            if (isReadyPlayerMe) {
              // 自分が選び終わった場合
              this.myStatusTarget.textContent = "選択完了！";
              this.myStatusTarget.classList.replace("text-gray-500", "text-blue-500");
            } else {
              // 相手が選び終わった場合
              this.opponentStatusTarget.textContent = "選択完了！";
              this.opponentStatusTarget.classList.replace("text-gray-500", "text-red-500");
            }
          }

          if (data.type === "turn_resolved") {
            this.currentTurn = data.turn_number + 1;
            
            // 自分がP1かP2かによって、データを振り分ける
            const isP1 = this.isP1Value;
            const myAction = isP1 ? data.p1_action : data.p2_action;
            const opponentAction = isP1 ? data.p2_action : data.p1_action;
            const myEnergy = isP1 ? data.p1_energy : data.p2_energy;
            const opponentEnergy = isP1 ? data.p2_energy : data.p1_energy;

            // アクション名を日本語に変換
            const actionNames = { charge: "チャージ", attack: "攻撃", guard: "ガード" };
            this.myActionDisplayTarget.textContent = actionNames[myAction];
            this.opponentActionDisplayTarget.textContent = actionNames[opponentAction];

            // 組み合わせに基づく結果メッセージを生成して表示
            this.resultMessageDisplayTarget.textContent = this.generateResultMessage(myAction, opponentAction);

            // 演出画面へ切り替え（3秒後に次のターンまたは終了画面へ）
            this.showTurnResultEffect(data.match_status, data.match_id, myEnergy, opponentEnergy);
          }
        }
      }
    )
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe();
    }
  }

  // マッチング後に「手の選択画面」まで自動で切り替わる
  showMatchStartEffect() {
    this.waitingTarget.classList.add("hidden");
    this.matchStartEffectTarget.classList.remove("hidden");

    setTimeout(() => {
      this.matchStartEffectTarget.classList.add("hidden");
      this.battleBoardTarget.classList.remove("hidden");
    }, 3000)
  }

  pickHand(event) {
    const selectedHand = event.params.hand;
    console.log(`selectedHand: ${selectedHand}`)

    if (selectedHand === "guard") {
      this.myLastGuardTurn = this.currentTurn;
    }

    this.subscription.perform("play", { selectedHand: selectedHand } );

    this.disableAllButtons();
  }

  updateButtonStates(myEnergy, opponentEnergy) {
    this.chargeButtonTarget.disabled = (myEnergy >= 5);

    this.attackButtonTarget.disabled = (myEnergy <= 0);

    let canGuard = (opponentEnergy > 0);
    if (this.myLastGuardTurn !== null) {
      // クールダウンが経過しているかチェック
      const turnsPassed = this.currentTurn - this.myLastGuardTurn;
      if (turnsPassed <= this.guardCooldownValue) {
        canGuard = false;
      }
    }
    this.guardButtonTarget.disabled = !canGuard;
  }

  // すべてのボタンを強制的に無効化する（選択直後や演出中など）
  disableAllButtons() {
    this.chargeButtonTarget.disabled = true;
    this.attackButtonTarget.disabled = true;
    this.guardButtonTarget.disabled = true;
  }

  // ターンの初めにステータス表示を「考え中...」に戻すメソッド
  resetPlayerStatuses() {
    this.myStatusTarget.textContent = "考え中...";
    this.myStatusTarget.classList.add("text-gray-500");
    this.myStatusTarget.classList.remove("text-blue-500");

    this.opponentStatusTarget.textContent = "考え中...";
    this.opponentStatusTarget.classList.add("text-gray-500");
    this.opponentStatusTarget.classList.remove("text-red-500");
  }

  generateResultMessage(my, opponent) {
    if (my === "attack" && opponent === "charge") return "攻撃成功！相手に1ダメージ！";
    if (my === "attack" && opponent === "attack") return "相打ち！ダメージなし";
    if (my === "attack" && opponent === "guard")  return "ガードされた！ダメージなし";
    
    if (my === "charge" && opponent === "attack") return "攻撃を受けた！1ダメージ...";
    if (my === "charge" && opponent === "charge") return "お互いにエネルギーを溜めた";
    if (my === "charge" && opponent === "guard")  return "相手は警戒している...";
    
    if (my === "guard"  && opponent === "attack") return "ガード成功！攻撃を防いだ！";
    if (my === "guard"  && opponent === "charge") return "相手はエネルギーを溜めた";
    if (my === "guard"  && opponent === "guard")  return "お互いに様子を見ている";
    
    return "";
  }

  showTurnResultEffect(matchStatus, matchId, myEnergy, opponentEnergy) {
    // 対戦画面を隠して、結果演出画面を表示
    this.battleBoardTarget.classList.add("hidden");
    this.turnResultEffectTarget.classList.remove("hidden");

    setTimeout(() => {
      if (matchStatus === "ongoing") {
        // 試合が続く場合：演出画面を隠し、対戦画面に戻す
        this.turnResultEffectTarget.classList.add("hidden");
        this.battleBoardTarget.classList.remove("hidden");
        
        // UIのリセットとボタンの再評価
        this.resetPlayerStatuses();
        this.updateButtonStates(myEnergy, opponentEnergy);
      } else {
        // 試合終了の場合：対戦結果画面にリダイレクトする
        // ※ matches#show など、結果画面へのルーティングに合わせてURLを調整してください
        window.location.href = `/matches/${matchId}/result`;
      }
    }, 3000); // 3秒間結果を表示
  }
}
