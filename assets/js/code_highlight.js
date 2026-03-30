import hljs from "highlight.js";

function addLineNumbers(codeEl) {
  const pre = codeEl.parentElement;

  const existing = pre.querySelector('.line-numbers-gutter');
  if (existing) existing.remove();

  const text = codeEl.textContent;
  const lines = text.split('\n');
  const lineCount = lines[lines.length - 1] === '' ? lines.length - 1 : lines.length;

  const gutter = document.createElement('span');
  gutter.className = 'line-numbers-gutter flex flex-col px-3 py-4 text-right select-none text-base-content/60 border-r border-base-content/20 text-sm leading-5 shrink-0 min-w-10';
  gutter.setAttribute('aria-hidden', 'true');

  const numbers = [];
  for (let i = 1; i <= lineCount; i++) {
    numbers.push(`<span class="block leading-5">${i}</span>`);
  }
  gutter.innerHTML = numbers.join('');

  pre.insertBefore(gutter, codeEl);
  pre.classList.add('flex', 'items-start', '!p-0');
  codeEl.classList.add('flex-1', '!p-4', 'min-w-0');
  codeEl.style.lineHeight = '1.25rem';
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
