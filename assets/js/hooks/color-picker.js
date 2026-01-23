import Alwan from "alwan";

export const ColorPicker = {
  mounted() {
    const { targets, value } = this.el.dataset;

    const targetsToColor = JSON.parse(targets);

    const picker = new Alwan(this.el, {
      parent: "dialog",
      format: "hex",
      classname: "!size-[32px] !border-2",
      color: value,
    });

    picker.on("color", event => {
      const { hex } = event;

      targetsToColor.forEach(target => {
        const { type, id } = target;
        const el = document.getElementById(id);

        if (type == "input") el.value = hex;
        if (type == "preview") target.styleProps.forEach(prop => el.style.setProperty(prop, hex));
      });
    });
  },
};
