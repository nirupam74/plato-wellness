# Widgets (home & lock screen) — setup needed before implementation

Task tmr9jjmvr asks for home/lock-screen widgets to log water and surface app
data. Widgets in iOS **must live in their own Widget Extension target** and
share data with the app through an **App Group**. Neither a new target nor an
App Group can be added safely by editing the project file by hand — doing it
wrong corrupts the Xcode project. These are a few clicks in Xcode, and then the
widget code can be dropped in.

## One-time setup (in Xcode)

1. **Add the widget target**
   - File → New → Target… → **Widget Extension**.
   - Product name: `PlatoWidgets`. Uncheck "Include Live Activity" unless you
     want Live Activities too. Finish, and let Xcode create the scheme.

2. **Add an App Group to BOTH targets** (the app and `PlatoWidgets`)
   - Select the target → Signing & Capabilities → **+ Capability → App Groups**.
   - Add the same group id to both, e.g. `group.com.platowellness.app`.

3. Tell me the App Group id you used and that the target exists.

## What I'll build once the target + group exist

- A tiny shared store (`WidgetData`) that writes today's snapshot (water ml and
  goal, calories vs target, steps, next reminder) to the App Group
  `UserDefaults`, updated whenever the app foregrounds or logs.
- Widgets in `PlatoWidgets`:
  - **Water widget** with a tappable quick-add (App Intent) to log a glass
    straight from the home/lock screen.
  - **Today summary** widget (calories, steps, water) for the home screen.
  - **Lock-screen** accessory widgets (circular water ring, inline calories).
- Deep links so tapping a widget opens the relevant tab.

## Why it isn't done yet

The widget code compiles only inside the extension target, and quick-add from a
widget needs the App Group to share the data. Shipping widget source into the
main app target would not build. So this is blocked on the two Xcode steps
above; everything after that I can implement.
