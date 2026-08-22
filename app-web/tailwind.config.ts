import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  darkMode: "class",
  theme: {
    extend: {
      colors: {
        "on-tertiary-container": "#2e3b77",
        "secondary-fixed-dim": "#d8c594",
        "status-shipped": "#EAB308",
        "surface-container-highest": "#38342d",
        "surface-card": "var(--color-surface-card)",
        "surface-container": "#221f19",
        "on-error": "#690005",
        "surface-container-lowest": "#100e08",
        "inverse-on-surface": "#343029",
        "on-primary-container": "#503d00",
        "tertiary": "#b9c4ff",
        "secondary-fixed": "#f5e1ae",
        "surface-variant": "#38342d",
        "on-primary-fixed-variant": "#584400",
        "error": "#ffb4ab",
        "tertiary-fixed": "#dde1ff",
        "outline-variant": "#4d4637",
        "error-container": "#93000a",
        "on-primary": "#3d2e00",
        "surface-dim": "#16130d",
        "on-surface-variant": "#d0c5b2",
        "on-secondary-container": "#c5b484",
        "tertiary-container": "#9ba8eb",
        "secondary": "#d8c594",
        "surface-container-high": "#2d2a23",
        "on-background": "#e9e1d7",
        "border-subtle": "var(--color-border-subtle)",
        "secondary-container": "#524620",
        "inverse-primary": "#755b00",
        "surface-tint": "#e6c364",
        "on-error-container": "#ffdad6",
        "on-surface": "#e9e1d7",
        "background": "#16130d",
        "on-secondary": "#3a2f0b",
        "on-secondary-fixed": "#231b00",
        "tertiary-fixed-dim": "#b9c3ff",
        "bg-primary": "var(--color-bg-primary)",
        "text-primary": "var(--color-text-primary)",
        "on-tertiary": "#1e2b66",
        "primary-fixed-dim": "#e6c364",
        "on-tertiary-fixed": "#041451",
        "status-confirmed": "#3B82F6",
        "surface-bright": "#3d3931",
        "primary": "#e6c364",
        "on-secondary-fixed-variant": "#524620",
        "status-cancelled": "#EF4444",
        "on-primary-fixed": "#241a00",
        "status-delivered": "#22C55E",
        "primary-fixed": "#ffe08f",
        "status-pending": "#A0A0A0",
        "outline": "#99907e",
        "inverse-surface": "#e9e1d7",
        "on-tertiary-fixed-variant": "#35437e",
        "surface-container-low": "#1e1b15",
        "primary-container": "#c9a84c",
        "text-secondary": "var(--color-text-secondary)",
        "surface": "#16130d"
      },
      borderRadius: {
        "DEFAULT": "0.125rem",
        "lg": "0.25rem",
        "xl": "0.5rem",
        "full": "0.75rem"
      },
      spacing: {
        "card-gap": "20px",
        "section-padding": "80px",
        "gutter": "24px",
        "container-max": "1280px"
      },
      fontFamily: {
        "headline-xl": ["Noto Serif"],
        "headline-lg": ["Noto Serif"],
        "body-lg": ["Manrope"],
        "label-accent": ["Space Grotesk"],
        "body-md": ["Manrope"],
        "headline-md": ["Noto Serif"]
      },
      fontSize: {
        "headline-xl": ["3.5rem", { lineHeight: "1.1", letterSpacing: "-0.02em", fontWeight: "400" }],
        "headline-lg": ["2.25rem", { lineHeight: "1.2", fontWeight: "400" }],
        "body-lg": ["1.125rem", { lineHeight: "1.6", fontWeight: "400" }],
        "label-accent": ["0.75rem", { lineHeight: "1", letterSpacing: "0.05em", fontWeight: "600" }],
        "body-md": ["1rem", { lineHeight: "1.6", fontWeight: "400" }],
        "headline-md": ["1.5rem", { lineHeight: "1.4", fontWeight: "400" }]
      }
    }
  },
  plugins: [
    require("@tailwindcss/forms"),
    require("@tailwindcss/container-queries")
  ],
};
export default config;
