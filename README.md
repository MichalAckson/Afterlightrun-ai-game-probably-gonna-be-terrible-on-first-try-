# AFTERLIGHT: FIVE RUNS

A fully 3D, mobile-first driving adventure. The first playable slice is **First Light**: a dusk city route, a physics-driven sedan, touchscreen controls, three signal gates, a finish marker, five graphics presets and original generated audio.

## Prototype features
- Godot 4.7.2 stable, GDScript, Compatibility renderer.
- Procedural 3D road, city blocks, streetlights, trees, signal gates and car.
- Physics-driven 1,280 kg vehicle with suspension forces, acceleration, braking, steering, collision response and body-condition feedback.
- Landscape Android layout with touch controls and keyboard controls.
- Very Low, Low, Medium, High and Ultra graphics presets.
- Genuine KTX1 RGBA8 atlas with 10 mip levels generated from a 512×512 source image.
- Generated engine loop and temporary synthesized dispatcher voice line.

## Build
GitHub Actions generates the original atlas and WAV assets, validates the Godot project, and exports an ARM64 Android debug APK. Download the APK from the successful workflow run's **Artifacts** section. Engine: Godot 4.7.2 stable. The workflow uses matching export templates, Java 17 and Android SDK platform 35.

## Controls
W / Up: accelerate. S / Down: brake. A / Left: steer left. D / Right: steer right. Android: use the on-screen driving buttons.

## Five-run story
1. **First Light**: reconnect three city signal relays. Playable in this prototype.
2. **Night Shift**: deliver replacement parts by motorcycle along the waterfront.
3. **Dead Signal**: take a utility vehicle up a mountain pass to help a stranded maintenance crew.
4. **Crosswind**: guide a small convoy through a storm corridor.
5. **Last Run**: follow the coast and climb into the valley at sunrise.

This is an early vertical slice, not the complete five-mission game. Additional vehicles, characters, animation, mission scripting, environmental art and voice performances are later milestones.

## Visual target
Ultra aims for a PS3-era visual ceiling using efficient mobile techniques: atlas materials, mipmaps, static shadow treatment, selective dynamic shadows, fog/glow and scalable rendering resolution. The initial KTX is an uncompressed RGBA fallback; ASTC/ETC2 GPU-compressed variants remain a future optimization.
