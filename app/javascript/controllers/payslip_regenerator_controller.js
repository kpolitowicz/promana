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
      let dueDate = this.dueDateTarget.value

      if (month) {
        // If month changed, update due_date to same month (keeping day and year)
        if (dueDate) {
          const dueDateObj = new Date(dueDate)
          const monthObj = new Date(month)
          
          // Set due_date to same month as month field, keeping the day
          dueDateObj.setMonth(monthObj.getMonth())
          dueDateObj.setFullYear(monthObj.getFullYear())
          
          // Format as YYYY-MM-DD
          const day = dueDateObj.getDate().toString().padStart(2, '0')
          const monthNum = (dueDateObj.getMonth() + 1).toString().padStart(2, '0')
          dueDate = `${dueDateObj.getFullYear()}-${monthNum}-${day}`
          
          // Update the due_date field
          this.dueDateTarget.value = dueDate
        }

        if (month && dueDate) {
          // Build URL with updated params
          const url = new URL(window.location.href)
          url.searchParams.set("month", month)
          url.searchParams.set("due_date", dueDate)

          // Use Turbo to navigate to the updated URL
          Turbo.visit(url.toString())
        }
      }
    }, 300) // 300ms debounce
  }
}

