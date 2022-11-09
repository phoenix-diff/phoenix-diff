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
        drawFileList: true,
        outputFormat: this.el.getAttribute("data-view-type"),
        highlight: true,
        fileContentToggle: false,
        matching: 'words'
    });

    diff2htmlUi.draw();

    this._updateDiffFileLinks();

    const event = new CustomEvent("phx-diff:diff-loading-stop", {bubbles: true, cancelable: true});
    window.dispatchEvent(event);
  },
  _updateDiffFileLinks() {
    Array.from(this.el.getElementsByClassName("d2h-file-name")).forEach((element) => {
      const hash = element.getAttribute("href");
      const updatedURL = `${document.location.pathname}${document.location.search}${hash}`;

      element.setAttribute("href", updatedURL);
    });
  }
};

export default DiffViewerComponent;
