# Pin npm packages by running ./bin/importmap

pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "@gouvfr/dsfr", to: "dsfr.module.min.js"
pin "application"
pin_all_from "app/javascript/controllers", under: "controllers"
