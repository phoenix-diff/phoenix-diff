// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import scss from "../css/app.scss";

import DiffLoader from "./components/diff-loader";

Vue.component("diff-loader", DiffLoader);

window.app = new Vue({ el: "main" });
