# Fighter Jet Sim (Godot 4)

A lightweight, Chromebook-friendly 3D fighter jet flight simulator built in **Godot 4** using pure GDScript and the **Compatibility** renderer.

## Features
- **3D Flight Physics:** Pitch, roll, yaw, throttle acceleration, and speed-based lift/gravity balance.
- **Live Cockpit HUD:** Real-time throttle percentage, airspeed (knots), and altitude (feet) readout.
- **Lightweight Compatibility Mode:** Configured with `gl_compatibility` so it runs smoothly on Chromebooks and integrated graphics without heavy shaders.

## Flight Controls

| Action | Key(s) |
| :--- | :--- |
| **Pitch Up / Down** | `S` / `W` or `Down` / `Up` Arrow |
| **Roll Left / Right** | `A` / `D` or `Left` / `Right` Arrow |
| **Yaw Left / Right** | `Q` / `E` |
| **Throttle Up** | `Shift` |
| **Throttle Down** | `Ctrl` |

## How to Run
1. Download this repository (`<> Code` → **Download ZIP**) and extract the folder.
2. Open **Godot 4.3+** (compatible with Godot 4.7).
3. Click **Import**, select the `project.godot` file inside the extracted folder, and click **Import & Edit**.
4. Press **F5** (or click the **Play** button in the top-right corner) to fly.

## Project Structure
- `project.godot` — Engine configuration, input map bindings, and Compatibility renderer settings.
- `main.tscn` — Main 3D scene containing the fighter jet mesh, chase camera, sky environment, ground terrain, and HUD overlay.
- `jet.gd` — GDScript controller handling flight physics, rotation, lift, and HUD updates.

## License
Free to use, modify, and build upon as your own project.
