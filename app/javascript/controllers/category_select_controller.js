import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "formTemplate", "formContainer", "newForm"]

  changed() {
    if (this.selectTarget.value === "new") {
      this.showForm()
    }
  }

  showForm() {
    const template = this.formTemplateTarget.content.cloneNode(true)
    this.formContainerTarget.replaceChildren(template)
  }

  cancel() {
    this.formContainerTarget.replaceChildren()
    this.selectTarget.value = ""
  }

  async createCategory() {
    const form = this.formContainerTarget.querySelector("fieldset")
    const name = form.querySelector("#category_name").value.trim()
    const categoryType = form.querySelector("#category_category_type").value

    if (!name) return

    const response = await fetch("/categories", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ category: { name, category_type: categoryType } })
    })

    if (response.ok) {
      const category = await response.json()
      this.addOptionToSelect(category)
      this.formContainerTarget.replaceChildren()
    } else {
      const { errors } = await response.json()
      alert(errors.join(", "))
    }
  }

  addOptionToSelect(category) {
    const select = this.selectTarget
    const groupLabel = category.category_type === "expense" ? "Expenses" : "Income"

    let optgroup = select.querySelector(`optgroup[label="${groupLabel}"]`)
    if (!optgroup) {
      optgroup = document.createElement("optgroup")
      optgroup.label = groupLabel
      // Insert before the "create new" option
      const newOption = select.querySelector('option[value="new"]')
      select.insertBefore(optgroup, newOption)
    }

    const option = document.createElement("option")
    option.value = category.id
    option.textContent = category.name
    optgroup.appendChild(option)

    select.value = category.id
  }
}
