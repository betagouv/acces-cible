import { Controller } from "@hotwired/stimulus"

// Usage: data: { controller: :autosubmit, action: "input->autosubmit#submit" }

export default class extends Controller {
  submit(event) {
    this.element.requestSubmit()
  }
}
