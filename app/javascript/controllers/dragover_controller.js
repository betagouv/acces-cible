import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.dragover = false
  }

  disconnect() {
    this.dragover = false
  }

  enter(event) {
    this.dragover = true
  }

  leave(event) {
    this.dragover = false
  }

  drop(event) {
    this.dragover = false
  }

  set dragover(add) {
    this.element.classList.toggle("dragover", add)
  }
}
