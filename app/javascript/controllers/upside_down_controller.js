import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    storageKey: { type: String, default: "upside-down-enabled" }
  }

  connect() {
    this.enabled = this.readPreference()
    this.apply()
  }

  toggle(event) {
    event.preventDefault()
    this.enabled = !this.enabled
    this.persistPreference()
    this.apply()
  }

  readPreference() {
    try {
      const value = window.localStorage.getItem(this.storageKeyValue)

      return value !== "false"
    } catch (_) {
      return true
    }
  }

  persistPreference() {
    try {
      window.localStorage.setItem(this.storageKeyValue, String(this.enabled))
    } catch (_) {
    }
  }

  apply() {
    document.documentElement.dataset.upsideDown = String(this.enabled)

    document.querySelectorAll("[data-upside-down-toggle]").forEach((button) => {
      button.setAttribute("aria-pressed", String(this.enabled))
      button.setAttribute(
        "title",
        this.enabled ? "Remettre le site à l'endroit" : "Retourner le site"
      )
    })
  }
}
