import { Controller } from "@hotwired/stimulus"
import { clearFlashMessages } from "flash_messages"

export default class ClearFlashMessagesController extends Controller {
  clear() {
    clearFlashMessages()
  }
}
