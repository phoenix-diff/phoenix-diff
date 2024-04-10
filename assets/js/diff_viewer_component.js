import { Diff2HtmlUI } from 'diff2html/lib/ui/js/diff2html-ui-slim';

const DiffViewerComponent = {
  mounted() {
    this._renderDiff();
  },
  updated() {
    this._renderDiff();
  },
  _renderDiff() {
    const diff2htmlUi = new Diff2HtmlUI(this.el, this.el.getAttribute("data-diff"),{
        drawFileList: false,
        outputFormat: this.el.getAttribute("data-view-type"),
        highlight: true,
        matching: 'words'
    });

    diff2htmlUi.draw();

    const event = new CustomEvent("phx-diff:diff-loading-stop", {bubbles: true, cancelable: true});
    window.dispatchEvent(event);
  },
};

export default DiffViewerComponent;
