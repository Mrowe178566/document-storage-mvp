import { Controller } from "@hotwired/stimulus"

// Click a button to copy the value of a sibling input/element to the clipboard.
// Usage:
//   <div data-controller="clipboard">
//     <input data-clipboard-target="source" value="https://...">
//     <button data-action="click->clipboard#copy" data-clipboard-target="button">Copy</button>
//   </div>
export default class extends Controller {
  static targets = ["source", "button"]

  async copy(event) {
    event.preventDefault()
    try {
      await navigator.clipboard.writeText(this.sourceTarget.value)
      this.flashCopied()
    } catch (err) {
      this.sourceTarget.select()
    }
  }

  flashCopied() {
    if (!this.hasButtonTarget) return
    const button = this.buttonTarget
    const original = button.textContent
    button.textContent = "Copied!"
    button.disabled = true
    setTimeout(() => {
      button.textContent = original
      button.disabled = false
    }, 1500)
  }
}
