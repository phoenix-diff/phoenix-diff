const plugin = require("tailwindcss/plugin")
const fs = require("fs")
const path = require("path")

module.exports = plugin(function({matchComponents, theme}) {
  let iconsDir = path.join(__dirname, "../../deps/font_awesome/svgs")
  let values = {}
  let icons = [
    ["", "regular"],
    ["-solid", "/solid"],
    ["-brand", "/brands"],
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
      content = encodeURIComponent(content)
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