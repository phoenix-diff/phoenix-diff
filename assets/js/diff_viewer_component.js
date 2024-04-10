import { Diff2HtmlUI } from 'diff2html/lib/ui/js/diff2html-ui-slim';

const DiffViewerComponent = {
  mounted() {
    this._renderDiff();
  },
  updated() {
    this._renderDiff();
  },
  _renderDiff() {
    const sourceUrl = this.el.getAttribute("data-target-github-url");
    const diff2htmlUi = new Diff2HtmlUI(this.el, this.el.getAttribute("data-diff"),{
        drawFileList: false,
        outputFormat: this.el.getAttribute("data-view-type"),
        highlight: true,
        fileContentToggle: false,
        matching: 'words',
        rawTemplates: {'generic-file-path': this._genericFilePathTemplate(sourceUrl)}
    });

    diff2htmlUi.draw();

    const event = new CustomEvent("phx-diff:diff-loading-stop", {bubbles: true, cancelable: true});
    window.dispatchEvent(event);
  },
  // https://github.com/rtfpessoa/diff2html/blob/master/src/templates/generic-file-path.mustache
  _genericFilePathTemplate(sourceUrl) {
    return `
        <span class="d2h-file-name-wrapper">
          {{>fileIcon}}
          <a class="hover:underline" href="${sourceUrl}/{{fileDiffName}}">
            <span class="d2h-file-name">
              {{fileDiffName}}
            </span>
          </a>
          {{>fileTag}}
        </span>
        <label class="d2h-file-collapse">
          <input class="d2h-file-collapse-input" type="checkbox" name="viewed" value="viewed">
          Viewed
        </label>
    `;
  }
};

export default DiffViewerComponent;
