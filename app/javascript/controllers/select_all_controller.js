import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["selectAll", "checkbox"]

  toggle() {
    this.checkboxTargets.forEach(cb => cb.checked = this.selectAllTarget.checked)
  }
}
