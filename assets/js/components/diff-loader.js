export default {
  data() {
    return {
      sourceVersion: null,
      targetVersion: null,
      loading: false,
      noChanges: false,
      diffOutputFormat: "line-by-line"
    };
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

    this.diffResultsContainer = jQuery("#diff-results-container");

    this.loadDiff();
  },
  methods: {
    loadDiff() {
      this.loading = true;
      this.noChanges = false;

      this._clearDiffContainer();
      this._updateLocationParams();

      this._fetchDiff().then(diff => {
        this.loading = false;

        if (diff) {
          this._showDiff(diff);
        } else {
          this.noChanges = true;
        }
      });
    },
    showLineByLine() {
      this._changeDisplayFormat("line-by-line");
    },
    showSideBySide() {
      this._changeDisplayFormat("side-by-side");
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
      const diff2htmlUi = new Diff2HtmlUI({ diff: diff });

      diff2htmlUi.draw(this.diffResultsContainer, {
        inputFormat: "diff",
        outputFormat: this.diffOutputFormat,
        showFiles: true,
        matching: "lines"
      });

      diff2htmlUi.fileListCloseable(this.diffResultsContainer, false);

      this._updateDiffFileLinks();
    },
    _updateDiffFileLinks() {
      const pageURL = this._getPageURLWithQuery();

      $("a.d2h-file-name").each((index, el) => {
        const element = $(el);

        const hash = element.attr("href");
        element.attr("href", pageURL + hash);
      });
    },
    _changeDisplayFormat(format) {
      this.diffOutputFormat = format;

      setTimeout(this.loadDiff, 100);
    },
    _updateLocationParams() {
      if (!history.pushState) {
        return;
      }

      const newURL = this._getPageURLWithQuery();
      window.history.pushState({ path: newURL }, "", newURL);

      document.title = this._getPageTitle();
    },
    _getPageURLWithQuery() {
      const queryString = `?source=${this.sourceVersion}&target=${
        this.targetVersion
      }`;

      return (
        window.location.protocol +
        "//" +
        window.location.host +
        window.location.pathname +
        queryString
      );
    },
    _getPageTitle() {
      return `PhoenixDiff · v${this.sourceVersion} to v${this.targetVersion}`;
    }
  }
};
