# Dynamic Island Demo

A Flutter app that drives a real iOS **Live Activity** — ride tracking that updates live on the Lock Screen and in the Dynamic Island, with the driver's photo shared from Flutter to the widget through an App Group.

📖 Full write-up: [Dynamic Island in Flutter](https://medium.com/@ami.b_7192/9cfbc782e740)

<!-- Add a screen recording here and it will show up in the README:
     record on a Dynamic Island device, save as docs/demo.gif, then uncomment:
![Demo](docs/demo.gif)
-->

## Requirements

| | |
|---|---|
| Flutter | 3.38+ |
| Xcode | 16 or newer |
| iOS | **16.2+** — Live Activities won't start below this |
| Device | Dynamic Island hardware (iPhone 14 Pro and later) for the island itself; the Lock Screen activity works on any iOS 16.2+ device |

> Live Activities do **not** appear in the iOS Simulator's Dynamic Island. Run on a real device to see it.

## Run it

```bash
git clone https://github.com/ami-b-simform/dynamic_island_blog_demo.git
cd dynamic_island_blog_demo
flutter pub get
open ios/Runner.xcworkspace
```

### Sign it

No development team is committed, so you sign with your own. This demo needs an
**App Group**, which Apple only lets you register with a paid Apple Developer
Program membership — a free Personal Team can run apps on-device but cannot
create App Groups, and without one the driver photo never reaches the widget.

In Xcode, Signing & Capabilities, for **both** targets:

| Target | Set |
|---|---|
| `Runner` | Team → your account |
| `RideTrackerWidgetExtension` | Team → the same account |

Both targets must use the **same** team, or the widget won't provision alongside
the app. If `com.example.*` is already taken under your account, change both
bundle identifiers (e.g. `com.yourname.dynamicIsland` and
`com.yourname.dynamicIsland.RideTrackerWidget` — the widget's must stay nested
under the app's) and update the App Group to match, as below.

Then:

```bash
flutter run
```

Tap a ride, and the Live Activity starts. Lock the phone or swipe up to see the island update through the `preparing → pickedup → arriving → delivered` stages.

Sanity-check the Dart side without a device:

```bash
flutter test
```

## The App Group ID

The app writes the driver photo into a shared container; the widget reads it
back. That only works if **one identifier matches in three places**:

```
group.com.example.dynamicIslandFlutter
```

| Where | What to check |
|---|---|
| `Runner` target | Signing & Capabilities → App Groups |
| `RideTrackerWidgetExtension` target | Signing & Capabilities → App Groups |
| [`ios/Shared/ImageHelper.swift`](ios/Shared/ImageHelper.swift) | the `appGroupID` constant |

Change it in all three, or none. A mismatch is silent — the activity still
runs, the photo just never appears.

> **If you followed the blog post:** it says this identifier lives in *four*
> places — two capability screens and two Swift files. That was true when the
> app and the widget each carried their own copy of the App Group path. This
> repo now keeps one copy in `ios/Shared/ImageHelper.swift`, compiled into both
> targets, so there are three places, not four. One fewer thing to get wrong.

## How it's put together

```
test/widget_test.dart             # smoke test: `flutter test`

lib/
  models/driver.dart              # the ride shown on the home screen
  channel/live_activity_channel.dart  # Dart → Swift MethodChannel
  home_screen.dart                # pick a ride
  tracking_screen.dart            # drives the stage updates

ios/
  Shared/                         # ← compiled into BOTH targets
    RideAttributes.swift          #   the app/widget data contract
    ImageHelper.swift             #   App Group read + write
  Runner/
    AppDelegate.swift             # start / update / end the activity
  Runner/RideTrackerWidget/
    RideTrackerWidget.swift       # the Live Activity UI
    RideTrackerWidgetBundle.swift # extension entry point
```

`ios/Shared/` is an Xcode *synchronized folder* attached to the `Runner` **and** `RideTrackerWidgetExtension` targets. That's the important bit: `RideAttributes` is the contract the two sides agree on, and there is exactly one copy of it. Add a field and both sides see it on the next build — they cannot drift apart.

## How data flows

1. You tap a ride. Flutter calls `saveImageToAppGroup`, which copies the driver photo out of the asset bundle into the shared container.
2. Flutter calls `startActivity` with the driver details and the saved photo path.
3. `AppDelegate` builds a `RideAttributes` and requests the `Activity`.
4. `TrackingScreen` calls `updateActivity` as the ride progresses; each call pushes a new `ContentState` and the island re-renders.
5. `endActivity` shows the closing line for five seconds, then dismisses.


## Following the blog post?

The [article](https://medium.com/@ami.b_7192/9cfbc782e740) walks through this
same app, but the repo has been tidied since it was written. Three snippets
differ on purpose:

**`ContentState` has no `finalMessage`.** The blog's `RideAttributes` carries a
`finalMessage` field alongside `status`. It was only ever set to the same string
as `status`, and the widget only reads `status` — so it did nothing. The closing
line now goes straight into `status` when the ride ends. `finalMessage` is still
the argument name Dart sends to `endActivity`; it just no longer needs its own
field in the state.

**`RideAttributes.swift` and `ImageHelper.swift` live in `ios/Shared/`.** The
blog has you add `RideAttributes.swift` to both targets via Target Membership.
This project's widget uses an Xcode *synchronized folder*, where every file in
the folder is a target member automatically and there are no per-file
checkboxes. `ios/Shared/` is one such folder attached to both targets — same
guarantee, nothing to tick.

**The Flutter asset lookup is different.** `saveImageToAppGroup` resolves the
driver photo from `App.framework` as well as the main bundle. Flutter packages
assets inside `App.framework`, so a `Bundle.main`-only lookup finds nothing and
the photo silently never reaches the App Group.

Everything else — the channel name, `startRide`, the `Activity.request` call,
the `DynamicIsland` builder, the stage strings — matches the article as written.

## License

MIT — use it however you like.
