import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "row", "template", "add", "remove"]
  static values = { max: Number }

  connect() {
    this.nextIndex = this.rowTargets.length
    this.refresh()
  }

  add() {
    const row = this.templateTarget.innerHTML.replaceAll("NEW_INDEX", this.nextIndex++)
    this.listTarget.insertAdjacentHTML("beforeend", row)
    this.refresh()
    this.focusInput(this.rowTargets.at(-1))
  }

  remove(event) {
    const row = event.currentTarget.closest("[data-repeatable-fields-target='row']")
    const neighbour = row.nextElementSibling || row.previousElementSibling
    row.remove()
    this.refresh()
    this.focusInput(neighbour)
  }

  refresh() {
    this.addTarget.disabled = this.rowTargets.length >= this.maxValue
    this.removeTargets.forEach((button) => { button.disabled = this.rowTargets.length === 1 })
  }

  focusInput(row) {
    row?.querySelector("input")?.focus()
  }
}
