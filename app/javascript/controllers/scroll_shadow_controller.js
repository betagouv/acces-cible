import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["host", "scroller"]

    connect() {
        if (!this.hasHostTarget || !this.hasScrollerTarget) return

        this.update = this.update.bind(this)
        this.scrollerTarget.addEventListener("scroll", this.update, { passive: true })
        this.resizeObserver = new ResizeObserver(this.update)
        this.resizeObserver.observe(this.scrollerTarget)
        this.update()
    }

    disconnect() {
        this.scrollerTarget?.removeEventListener("scroll", this.update)
        this.resizeObserver?.disconnect()
    }

    update() {
        const { scrollLeft, scrollWidth, clientWidth } = this.scrollerTarget
        const max = scrollWidth - clientWidth
        this.hostTarget.classList.toggle("is-scroll-left", scrollLeft > 2)
        this.hostTarget.classList.toggle("is-scroll-right", max > 2 && scrollLeft < max - 2)
    }
}
