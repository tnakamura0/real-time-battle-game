import { Controller } from "@hotwired/stimulus"
import consumer from "../channels/consumer"

// Connects to data-controller="room"
export default class extends Controller {
  static targets = ["waiting", "matchStartEffect", "battleBoard", "turnResultEffect", "chargeButton", "attackButton", "guardButton"]
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
          }

          if (data.type === "player_ready") {
            // 「考え中」と「選択完了」を表示を切り替える処理
          }

          if (data.type == "turn_resolved") {
            this.currentTurn = data.turn_number + 1;

            const myEnergy = this.isP1Value ? data.p1_energy : data.p2_energy;
            const opponentEnergy = this.isP1Value ? data.p2_energy : data.p1_energy;

            // ボタンの状態を最新にする
            // 結果演出画面の表示などを行った後に実行する
            this.updateButtonStates(myEnergy, opponentEnergy);
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

    if (selectedHand === "guard") {
      this.myLastGuardTurn = this.currentTurn;
    }

    this.subscription.perform("play", { action: selectedHand } );

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
}
