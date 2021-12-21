// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

import Rails from "@rails/ujs"
import "@hotwired/turbo"
import * as ActiveStorage from "@rails/activestorage"
import "channels"

Rails.start()
ActiveStorage.start()

import "alpine-turbo-drive-adapter"
import Alpine from "alpinejs"

window.Alpine = Alpine
Alpine.start()

import "stylesheets/admin.css.scss"

document.addEventListener('turbo:before-render', () => {
  let permanents = document.querySelectorAll('[data-turbo-permanent]')

  let undos = Array.from(permanents).map(el => {
    el._x_ignore = true

    return () => {
      delete el._x_ignore
    }
  })

  document.addEventListener('turbo:render', function handler() {
    while (undos.length) undos.shift()()

    document.removeEventListener('turbo:render', handler)
  })
})
