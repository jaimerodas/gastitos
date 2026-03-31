import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { day: Number, month: Number, year: Number }

  connect() {
    this.element.querySelector("select")?.focus()
  }

  fill() {
    const selects = this.element.querySelectorAll("select")
    // Rails date_select generates selects in the order specified:
    // day, month, year (matching our order: option)
    selects.forEach(select => {
      const name = select.name
      if (name.includes("(3i)")) {
        select.value = this.dayValue
      } else if (name.includes("(2i)")) {
        select.value = this.monthValue
      } else if (name.includes("(1i)")) {
        select.value = this.yearValue
      }
    })
  }
}
