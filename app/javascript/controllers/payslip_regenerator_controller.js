import {Controller} from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["month", "dueDate"]

  connect() {
    // Debounce to avoid too many requests
    this.timeout = null
  }

  regenerate() {
    // Clear any pending timeout
    if (this.timeout) {
      clearTimeout(this.timeout)
    }

    // Debounce the request
    this.timeout = setTimeout(() => {
      const month = this.monthTarget.value
      const dueDate = this.dueDateTarget.value

      if (month && dueDate) {
        // Build URL with updated params
        const url = new URL(window.location.href)
        url.searchParams.set("month", month)
        url.searchParams.set("due_date", dueDate)

        // Use Turbo to navigate to the updated URL
        Turbo.visit(url.toString())
      }
    }, 300) // 300ms debounce
  }
}

