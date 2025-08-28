const OpenUrlHook = {
  mounted() {
    this.handleEvent("open_url", ({ url }) => {
      window.open(url, '_blank');
    });
  }
};

export default OpenUrlHook;
