# Graphics and performance

## Visual target
Ultra targets a PS3-era presentation: strong silhouettes, deliberate art direction, atmospheric distance, detailed vehicle/environment materials and selective dynamic lighting. This is not modern photorealistic AAA rendering.

## Asset rules
- 512×512 is the standard atlas tile size for environment, vehicle, character and prop materials.
- KTX is a real texture container. The initial atlas is KTX1 RGBA8 with 10 mip levels; its PNG is the editable source.
- ASTC/ETC2 variants should be generated from the source art when device-specific packaging is introduced.
- Prefer LOD meshes, distance culling, simple collision meshes and instanced repeated props.

## Lighting
Static world lighting and contact shadows should be baked or represented by precomputed geometry. Static city meshes avoid expensive real-time shadows. Dynamic shadows and local lights are reserved for moving vehicles, characters and nearby gameplay objects. Reflections, glow, fog and shadow distance scale with the quality preset.

## Presets
| Preset | Initial target |
|---|---|
| Very Low | 70% render scale, no dynamic shadows, minimal post-processing |
| Low | 80% render scale, no dynamic shadows, restrained effects |
| Medium | 90% render scale, distance fog, minimal glow |
| High | Full render scale, selective dynamic shadows and glow |
| Ultra | Full render scale, longer shadow distance and cinematic post-processing |

These are initial quality switches, not final device-specific tuning.
