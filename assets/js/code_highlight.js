import hljs from "highlight.js";

export default {
  mounted() {
    hljs.highlightElement(this.el);
  },
  updated() {
    delete this.el.dataset.highlighted;
    hljs.highlightElement(this.el);
  }
};
