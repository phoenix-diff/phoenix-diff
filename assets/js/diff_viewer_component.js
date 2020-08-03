const DiffViewerComponent = {
  mounted() {
    this._renderDiff();
  },
  updated() {
    this._renderDiff();
  },
  _renderDiff() {
    const diff2htmlUi = new Diff2HtmlUI({ diff: this.el.getAttribute("data-diff") });

    diff2htmlUi.draw($(this.el), {
        inputFormat: "diff",
        outputFormat: this.el.getAttribute("data-view-type"),
        showFiles: true,
        matching: "lines"
    });

    diff2htmlUi.fileListCloseable($(this.el), false);

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
