components {
  id: "player"
  component: "/game/prefabs/player/player.script"
}
embedded_components {
  id: "collisionobject"
  type: "collisionobject"
  data: "type: COLLISION_OBJECT_TYPE_KINEMATIC\n"
  "mass: 0.0\n"
  "friction: 0.0\n"
  "restitution: 0.0\n"
  "group: \"player\"\n"
  "mask: \"platform\"\n"
  "mask: \"coin\"\n"
  "mask: \"flag\"\n"
  "embedded_collision_shape {\n"
  "  shapes {\n"
  "    shape_type: TYPE_SPHERE\n"
  "    position {\n"
  "      y: 0.5\n"
  "    }\n"
  "    rotation {\n"
  "    }\n"
  "    index: 0\n"
  "    count: 1\n"
  "  }\n"
  "  data: 0.5\n"
  "}\n"
  ""
}
embedded_components {
  id: "dust_factory"
  type: "factory"
  data: "prototype: \"/game/prefabs/effects/dust.go\"\n"
  ""
}
embedded_components {
  id: "objectinterpolation"
  type: "objectinterpolation"
  data: "apply_transform: APPLY_TRANSFORM_NONE\n"
  ""
}
