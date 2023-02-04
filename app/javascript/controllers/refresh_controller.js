import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    path: String,
    time: Number
  };

  connect() {
    if (this.hasTimeValue && this.timeValue > 0) {
      setTimeout(() => {
        this.element.parentElement.src = this.pathValue;
      }, this.timeValue);
    }
  }
}
