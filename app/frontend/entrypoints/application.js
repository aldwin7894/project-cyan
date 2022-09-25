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

// fade animations
document.addEventListener("DOMContentLoaded", () => {
  const element = document.getElementsByTagName("body")[0];
  element.classList.add("animate__fadeIn", "animate__animated");

  element.addEventListener("animationend", () => {
    element.classList.remove("animate__fadeIn", "animate__animated");
  });
});
document.addEventListener("turbo:before-fetch-response", (event) => {
  const element = document.getElementById(event.target.id);
  element.classList.add("animate__fadeIn", "animate__animated", "animate__delay");
  element.addEventListener("animationend", () => {
    element.classList.remove("animate__fadeIn", "animate__animated", "animate__delay");
  });
});
