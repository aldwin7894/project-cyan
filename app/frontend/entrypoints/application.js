/* global Turbo */

import "iconify-icon";
import "@hotwired/turbo-rails";
import PromisePolyfill from "promise-polyfill";
import Alpine from "alpinejs";
import { Chart, PieController, ArcElement, Tooltip } from "chart.js";
import Tippy, { followCursor } from "tippy.js";
import Swiper from "swiper";
import {
  Autoplay,
  Navigation,
  EffectFade,
  EffectCoverflow,
} from "swiper/modules";
import smartcrop from "smartcrop";
smartcrop.Promise = PromisePolyfill;

import "tippy.js/dist/tippy.css";
import "tippy.js/themes/light.css";
import "tippy.js/animations/perspective-subtle.css";
import "tippy.js/animations/shift-away-subtle.css";

import "swiper/css";
import "swiper/css/autoplay";
import "swiper/css/navigation";
import "swiper/css/effect-fade";
import "swiper/css/effect-coverflow";

import "~/stylesheets/application.css.scss";

const initElems = (parent = null) => {
  // popover
  const tippyPopoverList = [].slice.call(
    (parent || document).querySelectorAll("[data-tippy=popover]"),
  );
  Tippy(tippyPopoverList, {
    theme: "light",
    trigger: "click",
    animation: "shift-away-subtle",
    placement: "bottom",
    interactive: true,
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
  Tippy(tippyTooltipList, {
    theme: "light",
    placement: "top",
    followCursor: "horizontal",
    animation: "perspective-subtle",
    plugins: [followCursor],
    allowHTML: true,
  });
};

const fadeIn = id =>
  new Promise((resolve, _reject) => {
    const element = document.getElementById(id);
    element.style.willChange = "opacity";
    element.classList.add("animate__fadeIn", "animate__animated");

    function handleAnimationEnd(event) {
      event.stopPropagation();
      initElems(element);
      element.classList.remove("animate__fadeIn", "animate__animated");
      element.style.willChange = "auto";
      resolve("Animation ended");
    }

    element.addEventListener("animationend", handleAnimationEnd, {
      once: true,
    });
  });

const fadeOut = id =>
  new Promise((resolve, _reject) => {
    const element = document.getElementById(id);
    element.style.willChange = "opacity";
    element.classList.add("animate__fadeOut", "animate__animated");

    function handleAnimationEnd(event) {
      event.stopPropagation();
      element.classList.remove("animate__fadeOut", "animate__animated");
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
document.addEventListener("turbo:before-frame-render", event => {
  const id = event.target.getAttribute("data-turbo-frame")
    ? event.target.getAttribute("data-turbo-frame")
    : event.target.id;

  if (id.includes("last_watched")) {
    event.preventDefault();
    fadeOut(id).then(async () => {
      event.detail.resume();
    });
    return;
  }

  event.preventDefault();
  fadeOut(id)
    .then(async () => {
      event.detail.resume();
      await fadeIn(id);
    })
    .catch(() => {});
});
document.addEventListener("turbo:before-stream-render", event => {
  const id = event.target.target;
  const element = event.target.templateElement.content.firstElementChild;
  if (
    event.target.action === "update" &&
    event.target.firstElementChild instanceof HTMLTemplateElement
  ) {
    event.preventDefault();
    fadeOut(id)
      .then(async () => {
        element.style.willChange = "opacity";
        element.classList.add("animate__fadeIn", "animate__animated");

        element.addEventListener(
          "animationend",
          ev => {
            ev.stopPropagation();
            element.classList.remove("animate__fadeOut", "animate__animated");
            element.style.willChange = "auto";
          },
          {
            once: true,
          },
        );

        event.target.performAction();
      })
      .catch(() => {});
  }
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

Chart.register(PieController, ArcElement, Tooltip);

const CropImage = (imgSrc, canvasId, divElement, width, height) => {
  return new Promise((resolve, reject) => {
    const div = document.getElementById(divElement);
    const showDiv = () => {
      setTimeout(() => {
        div.style.opacity = 100;
        resolve();
      }, 200);
    };

    if (!imgSrc) {
      showDiv();
    }

    /**
     * @type {HTMLCanvasElement}
     */
    const canvas = document.getElementById(canvasId);
    const ctx = canvas.getContext("2d");
    const image = new Image();
    image.onerror = reject;
    image.onload = function () {
      canvas.width = image.width;
      canvas.height = image.height;
      ctx.drawImage(image, 0, 0, image.width, image.height);
      smartcrop
        .crop(canvas, {
          width,
          height,
          ruleOfThirds: false,
        })
        .then(crop => {
          canvas.width = width;
          canvas.height = height;
          ctx.clearRect(0, 0, canvas.width, canvas.height);
          ctx.drawImage(
            image,
            crop.topCrop.x,
            crop.topCrop.y,
            crop.topCrop.width,
            crop.topCrop.height,
            0,
            0,
            width,
            height,
          );
          const url = canvas.toDataURL("image/png");
          div.style.background = `no-repeat center/cover url(${url})`;
          canvas.parentNode.removeChild(canvas);
          showDiv();
        })
        .catch(reject);
    };

    image.src = imgSrc;
  });
};

Object.assign(window, {
  Alpine,
  Chart,
  Tippy,
  Swiper,
  Autoplay,
  Navigation,
  EffectFade,
  EffectCoverflow,
  CropImage,
});
Alpine.start();
