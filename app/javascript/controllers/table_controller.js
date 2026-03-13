import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static classes = ["hidden"]
  static targets = ["checkbox", "detail", "counter", "counterOne", "counterMany", "toggleAll", "button"]

  connect() {
    if (this.hasToggleAllTarget) {
      this.updateCounter()
      this.updateToggleAll()
    }
  }

  toggle(event) {
    this.updateCounter()
    this.updateToggleAll()
  }

  toggleAll(event) {
    const checkAll = this.toggleAllTarget.checked
    this.checkboxTargets.forEach((el) => {
      el.checked = checkAll
      this.dispatch("change", { target: el, prefix: false }) // Keep DSFR row borders in sync
    })
    this.updateCounter()
  }

  updateCounter() {
    const count = this.checkedCount
    this.counter = count
    switch(count) {
      case 0:
        this.toggleAllTarget.checked = false
        this.hide(this.detailTarget, this.buttonTarget)
        break
      case 1:
        this.show(this.detailTarget, this.counterOneTarget, this.buttonTarget)
        this.hide(this.counterManyTarget)
        break
      default:
        this.show(this.detailTarget, this.counterManyTarget, this.buttonTarget)
        this.hide(this.counterOneTarget)
    }
  }

  updateToggleAll() {
    const count = this.checkedCount
    const total = this.checkboxCount
    this.toggleAllTarget.disabled = total == 0
    this.toggleAllTarget.checked = count > 0 && count == total
    this.toggleAllTarget.indeterminate = count > 0 && count < total
  }

  hide(...elements) {
    elements.forEach(el => el.classList.add(this.hiddenClass))
  }

  show(...elements) {
    elements.forEach(el => el.classList.remove(this.hiddenClass))
  }

  get checkboxCount() {
    return this.checkboxTargets.length
  }

  get checkedCount() {
    return this.checkboxTargets.filter(check => check.checked).length
  }

  set counter(value) {
    this.counterTarget.innerHTML = value
  }
}
