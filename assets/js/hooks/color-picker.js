import Alwan from "alwan";

export const ColorPicker = {
  mounted() {
    const { target, value } = this.el.dataset;

    const picker = new Alwan(this.el, {
      parent: "dialog",
      format: "hex",
      classname: "!size-[32px] !border-2",
      color: value,
    });

    picker.on("change", event => {
      const { hex } = event;
      const input = document.getElementById(target);

      input.value = hex;
      input.dispatchEvent(new Event("change", { bubbles: true }));
    });
  },
};
