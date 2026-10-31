# Testing checklist

## Functional checks

- [ ] Run the standalone file in a private test experience where client-side scripts are permitted.
- [ ] Confirm the panel appears and all controls respond to touch.
- [ ] Apply Ultra; confirm particles, trails, beams, post effects, legacy effects, and shadows are reduced.
- [ ] Apply Balanced; confirm disabled properties return to their captured original values except post effects.
- [ ] Enable texture hiding; confirm Decal and Texture transparency changes locally.
- [ ] Disable texture hiding; confirm the original transparency values return.
- [ ] Use Restore; verify all changed properties return to their original values.
- [ ] Close with ×; verify restoration and panel removal.
- [ ] Add new effects while a profile is active; confirm they are handled.
- [ ] Change CurrentCamera and add camera post effects; confirm they are handled.
- [ ] Re-run the script after closing; verify there is no duplicate panel or stale connection.

## Performance checks

- [ ] Measure the same scene and camera angle before and after each profile.
- [ ] Repeat each measurement several times; record median FPS or frame time rather than relying on one sample.
- [ ] Compare low, medium, and high graphics quality where available.
- [ ] Test on a real low-end Android device and on the intended iOS/Delta setup separately.
- [ ] Check memory usage separately from FPS. Hiding a texture does not guarantee that its asset memory is unloaded.
- [ ] Use Roblox MicroProfiler/Performance Stats when available to identify whether rendering is actually the bottleneck.

## Safety/regression checks

- [ ] Confirm collision, player movement, UI, objectives, and gameplay remain unchanged.
- [ ] Confirm no objects are destroyed and no RemoteEvents or server state are modified.
- [ ] Check that optional texture hiding does not remove important signs or clues.
- [ ] Confirm Restore works after switching profiles multiple times.

FPS samples are approximate. Record device model, OS, Roblox build, executor build, experience, graphics level, and test scene with every result. Do not claim a guaranteed performance improvement from a single run.
