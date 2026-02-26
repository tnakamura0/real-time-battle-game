// app/javascript/controllers/passcode_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "hidden"]

  handleInput(event) {
    const currentInput = event.target
    const index = this.inputTargets.indexOf(currentInput)

    // 半角数字のみを許可する
    currentInput.value = currentInput.value.replace(/[^0-9]/g, '')

    // 1文字入力されたら次のフィールドへフォーカスを移動
    if (currentInput.value.length === 1 && index < this.inputTargets.length - 1) {
      this.inputTargets[index + 1].focus()
    }

    this.updateHiddenValue()
  }

  handleKeydown(event) {
    const currentInput = event.target
    const index = this.inputTargets.indexOf(currentInput)

    // Backspaceキーが押され、かつ現在の入力欄が空の場合、1つ前のフィールドに戻る
    if (event.key === "Backspace" && currentInput.value === "" && index > 0) {
      this.inputTargets[index - 1].focus()
    }
  }

  updateHiddenValue() {
    // 4つの入力欄の値を結合してhiddenフィールドにセット
    this.hiddenTarget.value = this.inputTargets.map(input => input.value).join('')
  }
}