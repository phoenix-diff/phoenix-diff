export default {
  data() {
    return {
      sourceVersion: null,
      targetVersion: null,
      loading: false,
      noChanges: false
    }
  },
  props: {
    source: {
      type: String,
      required: true
    },
    target: {
      type: String,
      required: true
    }
  },
  mounted() {
    this.sourceVersion = this.source;
    this.targetVersion = this.target;

    this.diffResultsContainer = jQuery('#diff-results-container');

    this.loadDiff();
  },
  methods: {
    loadDiff() {
      this.loading = true;
      this.noChanges = false;

      this._clearDiffContainer();

      this._fetchDiff()
        .then(diff => {
          this.loading = false;

          if (diff) {
            this._showDiff(diff);
          } else {
            this.noChanges = true;
          }
        });
    },
    _clearDiffContainer() {
      this.diffResultsContainer.empty();
    },
    _fetchDiff() {
      return axios
              .get(`/diffs?source=${this.sourceVersion}&target=${this.targetVersion}`)
              .then(response => response.data);
    },
    _showDiff(diff) {
      var diff2htmlUi = new Diff2HtmlUI({diff: diff});

      diff2htmlUi.draw(
        this.diffResultsContainer,
        {
          inputFormat: 'diff',
          outputFormat: 'line-by-line',
          showFiles: true,
          matching: 'lines'
        }
      );

      diff2htmlUi.fileListCloseable(this.diffResultsContainer, false);
    }
  }
}
