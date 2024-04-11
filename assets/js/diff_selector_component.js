const DiffSelectorComponent = {
  mounted() {
    this.el.addEventListener("submit", () => {
      const event = new CustomEvent("phx-diff:diff-loading-start", {bubbles: true, cancelable: true});
      window.dispatchEvent(event);
    });
  }
};

export default DiffSelectorComponent;
