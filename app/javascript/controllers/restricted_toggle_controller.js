import { Controller } from "@hotwired/stimulus"

// Toggles the visibility of the people-list section on the Manage Access page
// based on the Workspace / Restricted radio selection.
//
// Usage:
//   <div data-controller="restricted-toggle">
//     <input type="radio" data-action="change->restricted-toggle#hide">
//     <input type="radio" data-action="change->restricted-toggle#show">
//     <div data-restricted-toggle-target="people">...checkboxes...</div>
//   </div>
export default class extends Controller {
  static targets = ["people"]

  show() {
    if (this.hasPeopleTarget) this.peopleTarget.style.display = ""
  }

  hide() {
    if (this.hasPeopleTarget) this.peopleTarget.style.display = "none"
  }
}
