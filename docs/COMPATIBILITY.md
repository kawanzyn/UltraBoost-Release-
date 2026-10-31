# Compatibility notes

## Design target

The standalone script is built around standard client-side Roblox/Luau APIs: `Players.LocalPlayer`, `PlayerGui`, `Instance.new`, `Workspace`, `Lighting`, `DescendantAdded`, `RenderStepped`, and ordinary instance properties.

It deliberately does not depend on executor-specific APIs, HTTP fetching, remote script loaders, filesystem functions, hidden UI containers, debug hooks, or anti-cheat bypasses.

## Status

| Environment | Status |
|---|---|
| Roblox Studio, in an experience you control | Reference environment; test the modular source in Studio |
| Delta on Android | Not yet device-verified |
| Delta on iOS | Not yet device-verified |
| Other executors | Not guaranteed |

A script that uses standard APIs can still fail in a particular executor because injection context, permissions, client updates, or platform behavior may differ. The name “Delta” alone does not identify a fixed runtime version.

## Known limitations

- The script runs only on the local client. It cannot improve server frame time, replication, ping, or other players' clients.
- A local property change may reduce rendering work, but does not guarantee that the underlying assets are unloaded or that RAM usage drops.
- Some experiences rely on particles, lights, post effects, decals, or textures to communicate gameplay information.
- The FPS display counts client render frames. It is a rough observation, not a performance profiler.
- Roblox updates and executor updates can change runtime behavior. Re-test after either changes.

## Release gate

Do not mark Delta compatibility as “verified” until the exact Delta build and device have passed the functional and performance checks in [TESTING.md](TESTING.md), including restoration after profile switching and closing.
