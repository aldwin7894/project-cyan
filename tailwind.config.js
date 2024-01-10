/** @type {import('tailwindcss').Config} */
import defaultTheme from "tailwindcss/defaultTheme";
import plugin from "tailwindcss/plugin";
import typographyPlugin from "@tailwindcss/typography";
import formsPlugin from "@tailwindcss/forms";
import aspectRatioPlugin from "@tailwindcss/aspect-ratio";
import animatecssPlugin from "tailwindcss-animatecss";

export default {
  content: ["./public/**/*.html", "./app/**/*.{html,js,erb,rb}"],
  darkMode: "media", // or 'class'
  theme: {
    extend: {
      animation: {
        "spin-reduce": "spin 1.5s linear infinite",
      },
      backgroundColor: {
        white: "#fafafa",
        black: "#202020",
      },
      backgroundImage: {
        "gradient-radial": "radial-gradient(var(--tw-gradient-stops))",
      },
      borderWidth: {
        16: "16px",
      },
      colors: {
        "bg--dark": "#0B1622",
        "fg--dark": "#151F2E",
        "bg--light": "#E5EBF1",
        "fg--light": "#FBFBFB",
        "text--dark": "#9FADBD",
        "text--light": "#26343F",
      },
      textShadow: {
        sm: "0 1px 2px var(--tw-shadow-color)",
        DEFAULT: "0 0 20px var(--tw-shadow-color)",
        lg: "0 8px 16px var(--tw-shadow-color)",
      },
      screens: {
        xs: { min: "320px", max: "639px" },
        phone: "320px",
        tablet: "576px",
        laptop: "768px",
        desktop: "1200px",
        "desktop-lg": "1536px",
      },
    },
    screens: {
      sm: { min: "640px", max: "767px" },
      md: { min: "768px", max: "1023px" },
      lg: { min: "1024px", max: "1279px" },
      xl: { min: "1280px", max: "1535px" },
      "2xl": { min: "1536px", max: "1791px" },
    },
    container: {
      center: true,
    },
    fontFamily: {
      sans: ['"Source Sans Pro"', "Inter", ...defaultTheme.fontFamily.sans],
      serif: defaultTheme.fontFamily.serif,
      mono: defaultTheme.fontFamily.mono,
    },
    animatedSettings: {
      animatedSpeed: 500,
      animationDelaySpeed: 500,
      classes: ["fadeIn", "fadeOut", "delay"],
    },
  },
  plugins: [
    typographyPlugin,
    formsPlugin,
    aspectRatioPlugin,
    animatecssPlugin,
    plugin(({ matchUtilities, theme }) => {
      matchUtilities(
        {
          "text-shadow": value => ({
            textShadow: value,
          }),
        },
        { values: theme("textShadow") },
      );
    }),
  ],
};
