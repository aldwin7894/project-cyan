import "@hotwired/turbo-rails";
import * as ActiveStorage from "@rails/activestorage";
import Alpine from "alpinejs";
import "iconify-icon";
import Chart from "chart.js/auto";
import "tw-elements";
import "../channels";
import "~/stylesheets/application.css.scss";

ActiveStorage.start();

window.Alpine = Alpine;
window.Chart = Chart;
Alpine.start();

const popoverTriggerList = [].slice.call(
  document.querySelectorAll('[data-bs-toggle="popover"]'),
);
popoverTriggerList.map((popoverTriggerEl) => new window.Popover(popoverTriggerEl));
