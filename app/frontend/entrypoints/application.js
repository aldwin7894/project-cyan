import Rails from "@rails/ujs";
import "@hotwired/turbo-rails";
import * as ActiveStorage from "@rails/activestorage";
import Alpine from "alpinejs";
import "iconify-icon";
import Chart from "chart.js/auto";
import "../channels";

Rails.start();
ActiveStorage.start();

window.Alpine = Alpine;
window.Chart = Chart;
Alpine.start();
