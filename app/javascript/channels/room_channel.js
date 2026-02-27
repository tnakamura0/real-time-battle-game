import consumer from "./consumer"

document.addEventListener("turbo:load", () => {
  const roomContainer = document.getElementById("room-container");

  if (roomContainer) {
    // HTMLのdata-token属性の値を取得
    const roomToken = roomContainer.dataset.token;

    // 既に同じチャンネルを購読している場合は、重複を避けるために切断する
    const existingSubscription = consumer.subscriptions.subscriptions.find(
      (sub) => sub.identifier === JSON.stringify({ channel: "RoomChannel", token: roomToken })
    );
    if (!existingSubscription) {
      consumer.subscriptions.create({ channel: "RoomChannel", token: roomToken }, {
        connected() {
          console.log(`部屋（${roomToken}）に接続しました！`);
        },

        disconnected() {
          console.log("切断されました");
        },

        received(data) {
          if (data.type == "match_started") {
            console.log(`対戦開始！（Match ID: ${data.match_id}）`)
          }
        }
      });
    }
  }
});
