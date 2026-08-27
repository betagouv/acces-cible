import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static values = { url: String }

    connect() {
        this.visit = this.visit.bind(this)
        this.element.addEventListener("click", this.visit)
    }

    disconnect() {
        this.element.removeEventListener("click", this.visit)
    }

    visit(event) {
        if (event.target.closest("a, button, input, label")) return
        if (getSelection().toString()) return

        Turbo.visit(this.urlValue)
    }
}
