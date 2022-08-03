import Rails from "@rails/ujs";
import "@hotwired/turbo-rails";
import * as ActiveStorage from "@rails/activestorage";
import Alpine from "alpinejs";
import "iconify-icon";
import "../channels";

Rails.start();
ActiveStorage.start();

window.Alpine = Alpine;
Alpine.start();
