import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  open() {
    if (window.dsfr) {
      window.dsfr(this.element).modal.disclose()
    }
  }
}
