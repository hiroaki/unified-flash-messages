import { Controller } from "@hotwired/stimulus"
import { appendMessageToStorage, renderFlashMessages, clearFlashMessages } from "flash_unified/all"

// Minimal NG-word filter for demo purposes.
// Blocks form submission if any input/textarea contains the word "test" (case-insensitive).
export default class extends Controller {
	static values = { forbidden: String, alertMessage: String }

	validate(event) {
		const text = Array.from(this.element.querySelectorAll('input, textarea'))
			.map(el => el.value || '')
			.join(' ').toLowerCase();

		if (this.forbiddenValue && text.includes(this.forbiddenValue)) {
			event.preventDefault();
      const message = this.alertMessageValue || 'Submission blocked: contains forbidden word.';
      clearFlashMessages(message);
      appendMessageToStorage(message, 'alert');
      renderFlashMessages();
    }
	}
}
