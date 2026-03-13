import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { action: String }
  static targets = ["button"]

  connect() {
    this.buttonTargets.forEach(button => button.removeAttribute("hidden"))
  }

  disconnect() {
    this.buttonTargets.forEach(button => button.setAttribute("hidden", "hidden"))
  }

  submit(event) {
    const data = new FormData()
    this.element.querySelectorAll("input, select, textarea").forEach(input => {
      if (input.type === "checkbox" || input.type === "radio") {
        if (input.checked) {
          data.append(input.name, input.value)
        }
      } else if (input.type !== "submit") {
        data.append(input.name, input.value)
      }
    })
    if ([...data.values()].every(value => !value.trim())) {
      return
    }

    fetch(this.actionValue, {
      method: "POST",
      body: data,
      headers: {
        "Accept": "text/html",
        "X-CSRF-Token": this.authenticity_token,
        "X-Requested-With": "XMLHttpRequest"
      }
    })
    .then(response => {
      if (response.ok) {
        return response.text()
      } else {
        throw new Error(`Submitting frame data returned status ${response.status}`)
      }
    })
    .then(html => {
      Turbo.renderStreamMessage(html)
    })
    .catch(error => {
      console.error(error)
    })
  }

  get authenticity_token() {
    return document.querySelector("meta[name='csrf-token']").content
  }
}
