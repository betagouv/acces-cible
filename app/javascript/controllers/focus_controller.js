// Adapted from https://boringrails.com/articles/self-destructing-stimulus-controllers/

import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { selector: String }

  connect() {
    if (this.hasSelectorValue) {
      document.querySelector(this.selectorValue)?.focus()
    }
    this.element.remove()
  }
}
