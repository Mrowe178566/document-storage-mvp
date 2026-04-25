import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "folderName"]

  open(event) {
    event.preventDefault()
    const url = event.currentTarget.dataset.url
    const name = event.currentTarget.dataset.name
    this.formTarget.action = url
    this.folderNameTarget.textContent = name
    const modal = new bootstrap.Modal(document.getElementById("deleteModal"))
    modal.show()
  }
}
