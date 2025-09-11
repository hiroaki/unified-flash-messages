// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import { initializeFlashMessageSystem } from "flash_messages"

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", initializeFlashMessageSystem);
} else {
  initializeFlashMessageSystem();
}
