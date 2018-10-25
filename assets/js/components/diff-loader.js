export default {
  data() {
    return {
      sourceVersion: null,
      targetVersion: null
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
  }
}
