export const Collapse = {
  mounted() {
    const title = this.el.querySelector(".collapse-title");

    title?.addEventListener("click", () => {
      this.el.classList.toggle("collapse-open");
      this.el.classList.toggle("collapse-close");
    });
  },
  beforeUpdate() {
    this.isOpen = this.el.classList.contains("collapse-open");
  },
  updated() {
    if (this.isOpen) {
      this.el.classList.add("collapse-open");
      this.el.classList.remove("collapse-close");
    } else {
      this.el.classList.add("collapse-close");
      this.el.classList.remove("collapse-open");
    }
  },
};
