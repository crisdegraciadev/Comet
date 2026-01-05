export const PreserveScroll = {
  mounted() {
    window.scrollTo(0, this.scrollY);
  },
  destroyed() {
    this.scrollY = window.scrollY;
  },
};
