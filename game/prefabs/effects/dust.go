components {
  id: "dust"
  component: "/game/prefabs/effects/dust.script"
}
embedded_components {
  id: "model"
  type: "model"
  data: "mesh: \"/assets/models/kenney_platformer/dust.glb\"\n"
  "name: \"{{NAME}}\"\n"
  "materials {\n"
  "  name: \"colormap\"\n"
  "  material: \"/shadow_mapping/materials/mid/diffuse.material\"\n"
  "  textures {\n"
  "    sampler: \"tex0\"\n"
  "    texture: \"/assets/models/kenney_platformer/Textures/colormap.png\"\n"
  "  }\n"
  "}\n"
  ""
}
