import { Controller } from "@hotwired/stimulus"
import consumer from "../channels/consumer"

// Connects to data-controller="room"
export default class extends Controller {
  static values = { token: String };

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
}
