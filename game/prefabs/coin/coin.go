components {
  id: "coinsparkle"
  component: "/game/prefabs/coin/coinsparkle.particlefx"
}
components {
  id: "coincollect"
  component: "/game/prefabs/coin/coincollect.particlefx"
}
components {
  id: "coin"
  component: "/game/prefabs/coin/coin.script"
}
embedded_components {
  id: "model"
  type: "model"
  data: "mesh: \"/assets/models/kenney_platformer/coin.glb\"\n"
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
embedded_components {
  id: "collisionobject"
  type: "collisionobject"
  data: "type: COLLISION_OBJECT_TYPE_KINEMATIC\n"
  "mass: 0.0\n"
  "friction: 0.1\n"
  "restitution: 0.5\n"
  "group: \"coin\"\n"
  "mask: \"player\"\n"
  "embedded_collision_shape {\n"
  "  shapes {\n"
  "    shape_type: TYPE_SPHERE\n"
  "    position {\n"
  "      y: 0.2\n"
  "    }\n"
  "    rotation {\n"
  "    }\n"
  "    index: 0\n"
  "    count: 1\n"
  "  }\n"
  "  data: 0.2\n"
  "}\n"
  ""
}
