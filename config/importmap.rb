# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "flash_unified/auto", to: "flash_unified/auto.js"
pin "flash_unified", to: "flash_unified/flash_unified.js"
pin "flash_unified/turbo_helpers", to: "flash_unified/turbo_helpers.js"
pin "flash_unified/network_helpers", to: "flash_unified/network_helpers.js"
