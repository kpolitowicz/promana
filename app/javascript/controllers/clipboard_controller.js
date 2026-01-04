import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source"]

  copy() {
    const text = this.sourceTarget.value
    navigator.clipboard.writeText(text).then(() => {
      // Show feedback
      const button = this.element.querySelector("button")
      const originalText = button.textContent
      button.textContent = "Copied!"
      button.classList.add("bg-green-600")
      button.classList.remove("bg-blue-600", "hover:bg-blue-700")
      
      setTimeout(() => {
        button.textContent = originalText
        button.classList.remove("bg-green-600")
        button.classList.add("bg-blue-600", "hover:bg-blue-700")
      }, 2000)
    }).catch(err => {
      console.error("Failed to copy text: ", err)
      alert("Failed to copy to clipboard")
    })
  }
}

