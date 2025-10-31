import { Controller } from "@hotwired/stimulus"
import { clearFlashMessages } from "flash_unified/all"

export default class ClearFlashMessagesController extends Controller {
  clear() {
    clearFlashMessages()
  }
}
