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
          // Parse dates as local dates to avoid timezone issues
          const monthParts = month.split('-')
          const dueDateParts = dueDate.split('-')
          
          // Extract year and month from month field, day from due_date
          const newYear = parseInt(monthParts[0], 10)
          const newMonth = parseInt(monthParts[1], 10)
          const day = parseInt(dueDateParts[2], 10)
          
          // Create new date string in YYYY-MM-DD format
          dueDate = `${newYear}-${newMonth.toString().padStart(2, '0')}-${day.toString().padStart(2, '0')}`
          
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

