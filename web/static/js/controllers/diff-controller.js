@Inject("$scope", "$http")
export default class DiffController {
  constructor() {
    this.$scope.sourceVersion = "1.1.0";
    this.$scope.targetVersion = "1.2.0";

    this._showDiff();
  }

  _showDiff() {
    this._getDiff().then(diff => {
      var diff2htmlUi = new Diff2HtmlUI({diff: diff});

      diff2htmlUi.draw('#diff-results-container', {inputFormat: 'json', outputFormat: 'line-by-line', showFiles: true, matching: 'lines'});
      diff2htmlUi.fileListCloseable('#diff-results-container', false);
      // diff2htmlUi.highlightCode('#diff-results-container');
    });
  }

  _getDiff() {
    return this.$http.get(`/diffs/${this.$scope.sourceVersion}/${this.$scope.targetVersion}`).then(response => response.data);
  }
}
