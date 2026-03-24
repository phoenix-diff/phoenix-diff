import hljs from "highlight.js";

function addLineNumbers(codeEl) {
  const pre = codeEl.parentElement;

  const existing = pre.querySelector('.line-numbers-gutter');
  if (existing) existing.remove();

  const text = codeEl.textContent;
  const lines = text.split('\n');
  const lineCount = lines[lines.length - 1] === '' ? lines.length - 1 : lines.length;

  const gutter = document.createElement('span');
  gutter.className = 'line-numbers-gutter';
  gutter.setAttribute('aria-hidden', 'true');

  const numbers = [];
  for (let i = 1; i <= lineCount; i++) {
    numbers.push(`<span>${i}</span>`);
  }
  gutter.innerHTML = numbers.join('');

  pre.insertBefore(gutter, codeEl);
  pre.classList.add('code-with-line-numbers');
}

export default {
  mounted() {
    hljs.highlightElement(this.el);
    addLineNumbers(this.el);
  },
  updated() {
    delete this.el.dataset.highlighted;
    hljs.highlightElement(this.el);
    addLineNumbers(this.el);
  }
};
