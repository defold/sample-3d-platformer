# Platformer Manual

This manual covers the 3D platformer sample game movement, camera, animation, effects, and rendering.

Project setup and a beginner-friendly map of the files are documented in [README.md](README.md).

## Goal and controls

Collect 15 coins and reach the flag.

- Use <kbd>W</kbd><kbd>A</kbd><kbd>S</kbd><kbd>D</kbd>, a gamepad's <kbd>left stick</kbd>, or the <kbd>D-pad</kbd> to move the character relative to the camera.
- Press <kbd>Space</kbd> or a gamepad's <kbd>south face button</kbd> (for example, <kbd>A</kbd> on an Xbox controller) to jump or double-jump.
- Move the mouse, use the arrow keys, or use a gamepad's right stick to rotate the camera around the character.
- Use the mouse wheel or gamepad shoulder buttons to change the camera distance.
- Press <kbd>Escape</kbd> to release captured mouse input. Click inside the game window to capture it again.

## How the game starts

`game.project` loads `game/game.collection` as the bootstrap collection. The collection contains the example level, camera, interface, sounds, lighting, and factories.

When the collection starts, `game/game.script` creates the player at the spawn position. The same script validates the goal, presents the win state, and resets the player and score for the next round.

Files worth opening first:

- `game/game.collection` — the complete example scene
- `game/game.script` — player spawning and the win/reset loop
- `game/prefabs/player/player.go` — the reusable player game object
- `game/prefabs/player/player.script` — movement, jumping, animation, and collision handling

## Player

The player game object holds:

- a collision object with a sphere shape,
- `dust_factory` for creating 3D dust particles,
- an `objectinterpolation` component for interpolating the position,
- a player script that handles input, collisions, movement, score, and presentation state.

![Player game object](img/player.png)

The player's visuals (3D models) are managed by a separate `player_visual_factories` game object, which holds:

- a `player_visuals_factories` script responsible for spawning the selected model,
- five factories containing different models.

![Player visual factories and game objects](img/player_visuals.png)

## Character movement

The player script (`game/prefabs/player/player.script`) contains a kinematic 3D character controller. It stores the velocity and transform used by Fusion. Movement and gravity handling run in `fixed_update()` at the project's 60 Hz physics rate. Each fixed step produces a new simulation position, and the interpolation component blends the model between those positions while frames are rendered.

Contact messages resolve penetration and determine whether a contacted surface is walkable. An additional short downward ray cast keeps the grounded state stable when collision shapes are touching but the current step produces no useful contact.

Input is gathered and processed to rotate the camera and calculate the character's velocity. Ground movement is designed to respond quickly, whereas air movement is less direct. The character gradually turns towards the movement direction.

Jumping code also covers:

- **Jump buffering**, which remembers a jump pressed shortly before landing.
- **Coyote time**, which permits a jump briefly after leaving a ledge.
- **Variable jump height**, which makes an early button release shorten the jump.
- **Double jump**, which provides one additional jump in the air.

The easiest values to experiment with are grouped near the top of `player.script`, e.g.: `MOVEMENT_SPEED`, `JUMP_SPEED`, and `GRAVITY`.

Read more in the Defold manuals about the [fixed update lifecycle](https://defold.com/manuals/application-lifecycle/), [3D physics](https://defold.com/manuals/physics/), [kinematic collision resolution](https://defold.com/manuals/physics-resolving-collisions/), and [ray casts](https://defold.com/manuals/physics-ray-casts/).

## Visual interpolation

The player's animated model is created as a separate visual object and assigned as the target of the [object-interpolation component](https://github.com/indiesoftby/defold-object-interpolation), which is part of a community native extension developed by Indiesoft LLC.

Collisions and networking use the player root position.

Respawning updates the player root and the interpolation component's stored position together. This prevents the model from moving across the level while interpolating from the previous location to the spawn point.

## Camera

The camera uses a small game object hierarchy in the lobby collection (the bootstrap collection):

![Camera game object hierarchy in the lobby collection](img/camera.png)

```text
camera_operator       follow target position and horizontal rotation
└── camera_offset     vertical orbit rotation
    └── camera        distance from the target and camera component (zoom)
```

`game/camera_follow.script` updates the operator in `late_update()`, after simulation and object interpolation have supplied the latest target position. The camera uses the smoothed visual position of the interpolated object and also smooths its rotation and zoom through linear interpolation when handling input.

This parent-child setup lets Defold resolve the transforms automatically. Horizontal rotation is handled by `camera_operator`, vertical rotation by `camera_offset`, and zoom by changing the `camera` object's local distance.

The [Orbit Camera example](https://defold.com/examples/render/orbit_camera/) and [Camera manual](https://defold.com/manuals/camera/) cover a similar approach to handling cameras in Defold and provide more detailed explanations.

## Coins, platforms, and the flag

Each interactive object keeps its own behavior in a reusable game object:

- `game/prefabs/coin/` hides a collected coin, updates the player's score, and restores the coin after a delay.
- `game/prefabs/platform-falling/` shakes when stepped on, falls, and returns to its starting position.
- `game/prefabs/flag/` tells the main game script when the player reaches the goal.

Collision groups are defined in `game/groups.lua`. Shared message identifiers live in `game/messages.lua`, keeping senders and receivers on one documented protocol.

## Interface and sound

The interface is defined in `game/game_ui.gui` and controlled by `game/game_ui.gui_script`. Gameplay scripts send it messages when the score or win state changes, so the interface remains independent of player and coin implementation details.

Sounds use the same pattern: gameplay scripts send messages to `game/sounds.script`, which plays the appropriate Sound component.

The [Message passing manual](https://defold.com/manuals/message-passing/) explains Defold object and component addresses in more detail.

## Animation and effects

The controller chooses between idle, walk, and jump animations; the jump animation is also used while double-jumping and falling. To make movement feel more responsive, jumping and landing briefly stretch and squash the visual model. These actions also spawn short-lived dust objects built from 3D models, creating an effect that is also used while walking on a surface.

Remote players reproduce these effects when their replicated animation state changes.

Read more about the underlying setup in the [Model component](https://defold.com/manuals/model/), [Model animation](https://defold.com/manuals/model-animation/), and [Factory](https://defold.com/manuals/factory/) manuals. See [GPU Skinning](https://defold.com/examples/model/skinning/) for animated model setup and [Particle FX](https://defold.com/manuals/particlefx/) for effects.

## Rendering

The sample uses animated 3D models, one directional light, real-time shadow mapping, a skybox, particle effects, and billboarded artwork.

The skybox is based on Defold's [Skybox example](https://defold.com/examples/model/skybox/) and uses a custom material to produce a simple gradient between the bottom and top colors with the `mix` and `smoothstep` functions. It uses a normalized screen height (`var_screen_height`) passed from the vertex program to the fragment program.

The camera-facing visuals (the star particle effects around coins) follow the [Billboarding example](https://defold.com/examples/material/billboarding/).

![Particles using the billboarding material](img/particles.png)

### Directional lighting and shadows

The custom pipeline under `shadow_mapping/` first renders a depth map from the directional light, then samples it while drawing static and GPU-skinned models. Both model types cast and receive shadows.

![Shadow camera and level setup](img/shadow_camera.png)

The orthographic `shadow_camera` component on the `shadows` game object is used to supply the light-space view and projection matrices. Its **Orthographic Zoom**, **Near Z**, and **Far Z** values are the runtime source of truth for the shadow volume. `shadow_setup.script` follows the local player's interpolated visual, centers it between the near and far planes, and snaps the camera position to the active shadow map's texel grid. Shadow-map resolutions, PCF, polygon offset, and receiver bias remain properties of that script.

At startup, `tier_service.script` measures frame times and selects a global rendering tier:

- **Low** disables shadow rendering and uses unshadowed model materials.
- **Mid** uses a 2048 x 2048 shadow map and a single hard depth comparison.
- **High** uses a 4096 x 4096 shadow map and 3 x 3 PCF filtering.
- **Ultra** uses an 8192 x 8192 shadow map and 5 x 5 PCF filtering, provided that the graphics adapter supports a render target of that size.

The render script applies tier materials centrally. The depth texture uses nearest filtering. Explicit PCF, polygon offset, and a normal-dependent receiver bias keep edges soft and reduce shadow acne. Shadows affect directional diffuse light but not ambient or other lights.

The sampler order in every skinned material must remain `tex0`, `pose_matrix_cache`, `shadow_map`. Defold assigns the pose matrix cache to the first free model texture slot at runtime. Placing `shadow_map` before it causes the shadow shader to sample the pose texture instead, producing a fixed-looking dark region on animated models.

The pipeline uses one finite directional shadow map. Geometry outside it is lit, and point and spot lights do not cast shadows. See Defold's [Directional Light Shadows example](https://defold.com/examples/render/directional_light_shadows/) and the [Render](https://defold.com/manuals/render/), [Material](https://defold.com/manuals/material/), and [Shader](https://defold.com/manuals/shader/) manuals for more information.

## Editing the example level

Open `game/game.collection` and use the Scene Editor to inspect the level. A simple exercise could be to:

1. Find a platform or coin in the `Outline` pane.
2. Copy and paste it to create another instance.
3. Give the copy a clear, unique id.
4. Move it with the transform tools or edit its position in the `Properties` pane.
5. Build the project and test the change.

## Good first experiments

Try one change at a time and build after each one:

- Increase `MOVEMENT_SPEED` in the player script.
- Change `JUMP_SPEED` and compare short and long button presses.
- Change `MIN_COINS_TO_WIN` in the main game script. Keep it no higher than the number of coins in the level.
- Adjust the coin's `RESPAWN_DELAY`.
- Change camera properties in the collection's Properties pane.
- Duplicate and reposition a platform or coin in the level.

If a build fails, open the **Build Errors** tab and start with the first error. If the game runs but behaves unexpectedly, use `print()` and read the **Console** tab.
