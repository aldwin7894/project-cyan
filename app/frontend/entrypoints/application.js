/* global Turbo */

import "iconify-icon";
import "@hotwired/turbo-rails";
import * as ActiveStorage from "@rails/activestorage";
import Alpine from "alpinejs";
import Chart from "chart.js/auto";
import "tw-elements";
import tippy, { followCursor } from "tippy.js";
import "../channels";
import "tippy.js/dist/tippy.css";
import "tippy.js/themes/light.css";
import "tippy.js/animations/perspective-subtle.css";
import "tippy.js/animations/shift-away-subtle.css";
import "~/stylesheets/application.css.scss";

const initElems = (parent = null) => {
  // popover
  const tippyPopoverList = [].slice.call(
    (parent || document).querySelectorAll("[data-tippy=popover]"),
  );
  tippy(tippyPopoverList, {
    theme: "light",
    trigger: "click",
    animation: "shift-away-subtle",
    placement: "bottom",
    content(reference) {
      const id = reference.getAttribute("data-tippy-template");
      const template = document.getElementById(id);
      return template.innerHTML;
    },
    allowHTML: true,
  });

  // tooltip
  const tippyTooltipList = [].slice.call(
    (parent || document).querySelectorAll("[data-tippy=tooltip]"),
  );
  tippy(tippyTooltipList, {
    theme: "light",
    placement: "top",
    followCursor: "horizontal",
    animation: "perspective-subtle",
    plugins: [followCursor],
  });
};

const fadeIn = id =>
  new Promise((resolve, _reject) => {
    const element = document.getElementById(id);
    element.style.willChange = "opacity";
    element.classList.add(
      "animate__fadeIn",
      "animate__animated",
      "animate__delay",
    );

    function handleAnimationEnd(event) {
      event.stopPropagation();
      initElems(element);
      element.classList.remove(
        "animate__fadeIn",
        "animate__animated",
        "animate__delay",
      );
      element.style.willChange = "auto";
      resolve("Animation ended");
    }

    element.addEventListener("animationend", handleAnimationEnd, {
      once: true,
    });
  });

// fade animations
window.addEventListener("load", () => {
  const loader = document.getElementById("loader");
  const main = document.getElementById("main");
  const footer = document.getElementById("footer");

  loader.classList.add("animate__animated", "animate__fadeOut");
  loader.addEventListener("animationend", () => {
    loader.classList.remove("animate__animated", "animate__fadeOut");
    loader.classList.add("hidden");
    main.classList.remove("hidden");
    footer.classList.remove("hidden");
    main.classList.add("animate__fadeIn", "animate__animated");
    initElems();
  });
});
document.addEventListener("turbo:before-fetch-response", event => {
  const id = event.target.getAttribute("data-turbo-frame")
    ? event.target.getAttribute("data-turbo-frame")
    : event.target.id;
  fadeIn(id);
});

// FORCE PROGRSS BAR FOR TURBO
document.addEventListener("turbo:before-fetch-request", () => {
  Turbo.navigator.delegate.adapter.showProgressBar();
});
document.addEventListener("turbo:frame-render", () => {
  Turbo.navigator.delegate.adapter.progressBar.hide();
});
document.addEventListener("turbo:before-stream-render", () => {
  Turbo.navigator.delegate.adapter.progressBar.hide();
});

ActiveStorage.start();

window.Alpine = Alpine;
window.Chart = Chart;
window.tippy = tippy;
Alpine.start();
