import {Controller} from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "template"]
  static values = {index: Number}

  connect() {
    this.indexValue = this.containerTarget.children.length
  }

  add(event) {
    event.preventDefault()
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, this.indexValue)
    this.containerTarget.insertAdjacentHTML("beforeend", content)
    this.indexValue++
  }

  remove(event) {
    event.preventDefault()
    const lineItem = event.target.closest(".line-item")
    const destroyInput = lineItem.querySelector('input[name*="_destroy"]')
    if (destroyInput) {
      destroyInput.checked = true
      lineItem.style.display = "none"
    } else {
      lineItem.remove()
    }
  }
}
