import "iconify-icon";
import "@hotwired/turbo-rails";
import * as ActiveStorage from "@rails/activestorage";
import Alpine from "alpinejs";
import Chart from "chart.js/auto";
import "tw-elements";
import "../channels";
import "~/stylesheets/application.css.scss";

ActiveStorage.start();

window.Alpine = Alpine;
window.Chart = Chart;
Alpine.start();

const initElems = () => {
  // popover
  const popoverTriggerList = [].slice.call(
    document.querySelectorAll('[data-bs-toggle="popover"]'),
  );
  popoverTriggerList.map((popoverTriggerEl) => new window.Popover(popoverTriggerEl));

  // tooltip
  const tooltipTriggerList = [].slice.call(
    document.querySelectorAll('[data-bs-toggle="tooltip"]')
  );
  tooltipTriggerList.map((tooltipTriggerEl) => new window.Tooltip(tooltipTriggerEl));
};
initElems();


// fade animations
document.addEventListener("DOMContentLoaded", () => {
  const loader = document.getElementById("loader");
  const main = document.getElementsByTagName("main")[0];
  const footer = document.getElementsByTagName("footer")[0];

  loader.classList.add("animate__animated", "animate__fadeOut");
  loader.addEventListener("animationend", () => {
    loader.classList.add("hidden");
    main.classList.remove("hidden");
    footer.classList.remove("hidden");
    main.classList.add("animate__fadeIn", "animate__animated");
  });
});
document.addEventListener("turbo:before-fetch-response", (event) => {
  const element = document.getElementById(event.target.id);
  element.classList.add("animate__fadeIn", "animate__animated", "animate__delay");
  element.addEventListener("animationend", () => {
    element.classList.remove("animate__fadeIn", "animate__animated", "animate__delay");
  });
});

document.addEventListener("turbo:frame-load", () => {
  initElems();
});
