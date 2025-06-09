// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin")
const fs = require("fs")
const path = require("path")
const defaultTheme = require("tailwindcss/defaultTheme")

module.exports = {
    content: [
        "./js/**/*.js",
        "../lib/phx_diff_web.ex",
        "../lib/phx_diff_web/**/*.*ex"
    ],
    theme: {
        extend: {
            colors: {
                brand: "#FD4F00",
                // From https://uicolors.app
                'international-orange': {
                  '50': '#fff6ec',
                  '100': '#ffecd3',
                  '200': '#ffd4a5',
                  '300': '#ffb66d',
                  '400': '#ff8b32',
                  '500': '#ff6a0a',
                  '600': '#fd4f00',
                  '700': '#cc3702',
                  '800': '#a12b0b',
                  '900': '#82260c',
                  '950': '#461004',
                }

            },
            fontFamily: {
                'sans': ['Open Sans', ...defaultTheme.fontFamily.sans]
            },
            backgroundImage: {
                'gradient-radial': 'radial-gradient(circle, var(--tw-gradient-stops))'
            },
            animation: {
                'spin-slow': 'spin 2s linear infinite'
            }
        },
    },
    plugins: [
        require("@tailwindcss/forms"),
        // Allows prefixing tailwind classes with LiveView classes to add rules
        // only when LiveView classes are applied, for example:
        //
        //     <div class="phx-click-loading:animate-ping">
        //
        plugin(({addVariant}) => addVariant("phx-click-loading", [".phx-click-loading&", ".phx-click-loading &"])),
        plugin(({addVariant}) => addVariant("phx-submit-loading", [".phx-submit-loading&", ".phx-submit-loading &"])),
        plugin(({addVariant}) => addVariant("phx-change-loading", [".phx-change-loading&", ".phx-change-loading &"])),

        // Embeds Heroicons (https://heroicons.com) into your app.css bundle
        // See your `CoreComponents.icon/1` for more information.
        //
        plugin(function({matchComponents, theme}) {
        let iconsDir = path.join(__dirname, "../deps/heroicons/optimized")
        let values = {}
        let icons = [
            ["", "/24/outline"],
            ["-solid", "/24/solid"],
            ["-mini", "/20/solid"],
            ["-micro", "/20/solid"]
        ]
        icons.forEach(([suffix, dir]) => {
            fs.readdirSync(path.join(iconsDir, dir)).map(file => {
            let name = path.basename(file, ".svg") + suffix
            values[name] = {name, fullPath: path.join(iconsDir, dir, file)}
            })
        })
        matchComponents({
            "hero": ({name, fullPath}) => {
            let content = fs.readFileSync(fullPath).toString().replace(/\r?\n|\r/g, "")
            let size = theme("spacing.6")
            if (name.endsWith("-mini")) {
              size = theme("spacing.5")
            } else if (name.endsWith("-micro")) {
              size = theme("spacing.4")
            }
            return {
                [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
                "-webkit-mask": `var(--hero-${name})`,
                "mask": `var(--hero-${name})`,
                "background-color": "currentColor",
                "vertical-align": "middle",
                "display": "inline-block",
                "width": size,
                "height": size
            }
            }
        }, {values})
        }),

        // Embeds Font-Awesome (https://fonta) into your app.css bundle
        // See your `CoreComponents.icon/1` for more information.
        //
        plugin(function({matchComponents, theme}) {
        let iconsDir = path.join(__dirname, "../deps/font_awesome/svgs")
        let values = {}
        let icons = [
            ["", "/regular"],
            ["-solid", "/solid"],
            ["-brand", "/brands"]
        ]
        icons.forEach(([suffix, dir]) => {
            fs.readdirSync(path.join(iconsDir, dir)).forEach(file => {
            let name = path.basename(file, ".svg") + suffix
            values[name] = {name, fullPath: path.join(iconsDir, dir, file)}
            })
        })
        matchComponents({
            "fa": ({name, fullPath}) => {
            let content = fs.readFileSync(fullPath).toString().replace(/\r?\n|\r/g, "")
            return {
                [`--fa-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
                "-webkit-mask": `var(--fa-${name})`,
                "mask": `var(--fa-${name}) no-repeat`,
                "background-color": "currentColor",
                "vertical-align": "middle",
                "display": "inline-block",
                "width": theme("spacing.5"),
                "height": theme("spacing.5")
            }
            }
        }, {values})
        })
    ]
}
