# Family Controls (Distribution) request — Plato Wellness

The Focus Lock feature uses Apple's **Family Controls** entitlement
(`com.apple.developer.family-controls`) to shield the user's own distracting
apps via a `ManagedSettingsStore`. The **Development** form of this entitlement
works automatically on your own devices, which is why building shows only a
warning. To ship to **TestFlight or the App Store**, Apple must grant the
**Distribution** form of the entitlement. This is an approval step, not a code
change — nothing in the entitlements file or the code needs to change.

## Facts for the form

- App name: **Plato Wellness**
- Bundle ID: **com.platowellness.app**
- Platforms: iPhone and iPad
- Frameworks used: FamilyControls, ManagedSettings, DeviceActivity
- Use case type: **Individual / self-monitoring** (the person shields their own
  apps). NOT parental controls, NOT managing another person's device.

## Steps

1. Go to: https://developer.apple.com/contact/request/family-controls-distribution
2. Sign in with the Apple Developer account that owns com.platowellness.app.
3. Fill in the app name and bundle ID above.
4. For the use case, paste the justification below.
5. Submit. Approval typically takes from a few days to a few weeks; Apple
   replies by email.
6. After approval, rebuild with your distribution provisioning profile. The
   profile now carries the granted entitlement and the warning clears. No code
   change is required.

Development and on-device debug builds keep working the entire time.

## Draft justification (paste into the form)

Plato Wellness is a personal wellness app. Its Focus Lock feature helps a person
reduce their own screen-time distractions during focus or rest periods.

Using Family Controls and ManagedSettings, the user selects their own
distracting apps (for example social media or video apps) with the system
FamilyActivityPicker, chooses a duration, and the app applies a Screen Time
shield to that selection for the chosen time. This is entirely self-directed
digital wellbeing: the user is shielding their own device for themselves. The
app does not implement parental controls and does not manage or monitor any
other person's device.

We request the distribution entitlement so this self-monitoring focus feature
can ship to TestFlight and the App Store. All Family Controls usage is gated
behind the user's explicit authorization via AuthorizationCenter, and the app
functions normally (Focus Lock simply unavailable) if authorization is denied.

## Notes

- The entitlement key is the same for development and distribution
  (`com.apple.developer.family-controls`); only Apple's grant differs.
- If launch is time-sensitive and approval is slow, the alternative is to defer
  Focus Lock: remove the entitlement and gate the Focus Lock entry, then
  re-enable once the distribution entitlement is granted.
