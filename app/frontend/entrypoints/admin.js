import "iconify-icon";
import "@hotwired/turbo-rails";
import * as ActiveStorage from "@rails/activestorage";
import Alpine from "alpinejs";
import "../channels";
import "~/stylesheets/admin.css.scss";

ActiveStorage.start();

window.Alpine = Alpine;
Alpine.start();
