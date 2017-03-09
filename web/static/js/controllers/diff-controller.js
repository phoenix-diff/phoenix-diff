@Inject("$scope", "$http", "$location")
export default class DiffController {
  init(sourceVersion, targetVersion) {
    this.$scope.sourceVersion = sourceVersion;
    this.$scope.targetVersion = targetVersion;

    this.show();
  }

  show() {
    this.$location.search({source_version: this.$scope.sourceVersion, target_version: this.$scope.targetVersion});

    this.$scope.loading = true;
    this.$scope.showNoChangesMessage = false;

    this._clearContent();

    this._getDiff().then(diff => {
      this.$scope.loading = false;

      if (diff) {
        this._showDiff(diff);
      } else {
        this.$scope.showNoChangesMessage = true;
      }
    });
  }

  _showDiff(diff) {
    var diff2htmlUi = new Diff2HtmlUI({diff: diff});

    diff2htmlUi.draw(this._diffContainerSelector, {inputFormat: 'json', outputFormat: 'line-by-line', showFiles: true, matching: 'lines'});
    diff2htmlUi.fileListCloseable(this._diffContainerSelector, false);
    // diff2htmlUi.highlightCode(this._diffContainerSelector);
  }

  _clearContent() {
    angular.element(this._diffContainerSelector).empty();
  }

  get _diffContainerSelector() {
    return "#diff-results-container"
  }

  _getDiff() {
    return this.$http.get(`/diffs/${this.$scope.sourceVersion}/${this.$scope.targetVersion}`).then(response => response.data);
  }
}
