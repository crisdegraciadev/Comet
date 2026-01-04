const plugin = require("tailwindcss/plugin");
const fs = require("fs");
const path = require("path");

module.exports = plugin(function ({ matchComponents, theme }) {
  let baseDir = path.join(__dirname, "../../deps/lucide/icons");

  let values = {};
  let icons = fs
    .readdirSync(baseDir, { withFileTypes: true })
    .filter(dirent => dirent.isFile() && dirent.name.endsWith(".svg"))
    .map(dirent => dirent.name);

  icons.forEach(file => {
    let name = path.basename(file, ".svg");
    values[name] = { name, fullPath: path.join(baseDir, file) };
  });

  matchComponents(
    {
      lucide: ({ name, fullPath }) => {
        let content = fs.readFileSync(fullPath).toString();

        content = content.replace(/\r?\n|\r/g, "");

        return {
          [`--lucide-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
          "-webkit-mask": `var(--lucide-${name})`,
          mask: `var(--lucide-${name})`,
          "mask-size": "contain",
          "-webkit-mask-size": "contain",
          "background-color": "currentColor",
          "vertical-align": "middle",
          display: "inline-block",
          width: theme("spacing.10"),
          height: theme("spacing.10"),
        };
      },
    },
    { values }
  );
});
