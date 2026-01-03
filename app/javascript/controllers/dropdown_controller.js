import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]
  static values = {
    openDelay: { type: Number, default: 0 },
    closeDelay: { type: Number, default: 300 }
  }

  connect() {
    this.openTimeout = null
    this.closeTimeout = null
  }

  disconnect() {
    this.clearTimeouts()
  }

  mouseEnter() {
    this.clearTimeouts()
    
    if (this.openDelayValue > 0) {
      this.openTimeout = setTimeout(() => {
        this.open()
      }, this.openDelayValue)
    } else {
      this.open()
    }
  }

  mouseLeave() {
    this.clearTimeouts()
    
    if (this.closeDelayValue > 0) {
      this.closeTimeout = setTimeout(() => {
        this.close()
      }, this.closeDelayValue)
    } else {
      this.close()
    }
  }

  open() {
    this.menuTarget.classList.remove("hidden")
  }

  close() {
    this.menuTarget.classList.add("hidden")
  }

  clearTimeouts() {
    if (this.openTimeout) {
      clearTimeout(this.openTimeout)
      this.openTimeout = null
    }
    if (this.closeTimeout) {
      clearTimeout(this.closeTimeout)
      this.closeTimeout = null
    }
  }
}

