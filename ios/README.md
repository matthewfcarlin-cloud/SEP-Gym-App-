# RepQ — iOS app

The scheduling half of RepQ, in SwiftUI. You set your weekly split; the app reads live
machine occupancy and tells you **which machine to walk to next**, ordered so you never
queue and so your route doesn't collide with anyone else's.

## Open it in Xcode

```bash
open ios/repQ.xcodeproj
```

Pick an iPhone simulator and hit Run. Requires iOS 17+.

The project file is generated, not hand-edited — `generate_project.py` builds
`repQ.xcodeproj` from whatever `.swift` files are in `ios/repQ/`. **If you add a new
Swift file, re-run it** or Xcode won't compile your file:

```bash
python3 ios/generate_project.py
```

## Screens

| Screen | What it does |
|---|---|
| **Today** | Your routed session: next machine, which station to use, wait time, the full ordered queue, and how many minutes of queueing the routing saved you. |
| **My Week** | Assign a split to each day. Persists to `UserDefaults`. |
| **Floor** | Live occupancy per machine. Tap a station to simulate a scan on/off — the route re-plans instantly. |

## How the routing works

`repQ/Scheduler.swift` is the whole algorithm. Pure functions, no SwiftUI import, so it
can be unit tested or run from a command-line harness.

The gym is a **reservation ledger**: every machine owns N stations, each carrying the
minute-offset at which it next becomes free. Live QR scan-ins seed that ledger.

Routing is greedy with a training-priority cost. At each step it picks the remaining
exercise that minimises:

```
cost = wait_minutes + (planned_position × priorityWeight)
```

So it only reorders your session when skipping ahead saves more time than the training
cost of pushing a heavy compound later. `maxReorderDrift` stops a big lift from being
stranded at the end of the workout.

Crucially, **every member is routed through the same ledger**. Other members are routed
first, and their reservations become blocked slots for you — so two people are never sent
to the same station at the same time.

`planFloor()` also routes your session a second time in naive top-to-bottom order and
reports the difference. That's the "queue saved" figure on the Today screen.

### Tuning note

The floor load is deliberately calibrated. Other members are modelled as **mid-workout**
(1–6 exercises left), not starting fresh — routing nine full sessions ahead of the user
gridlocks the gym and leaves the user permanently last in every queue. A parameter sweep
over 400 seeded gyms per configuration put the current settings at roughly 5 minutes of
average waiting with a meaningful saving in about half of sessions.

## Hooking up the QR scanner

`GymStore` exposes exactly two methods for the scanner. That's the whole contract:

```swift
store.scanOn(machineID: "squat-rack", station: 2)   // member started using rack 2
store.scanOff(machineID: "squat-rack", station: 2)  // they finished, or timed out
```

Machine IDs live in `repQ/Models.swift` and are what the QR codes should encode —
e.g. `repq://machine/squat-rack/2`.

Everything downstream is automatic: `GymStore` is `@Observable`, and `plan` recomputes
from scratch on read, so the route re-renders the moment occupancy changes. The scanner
never needs to know the algorithm exists.

The camera permission string is already set in `generate_project.py`
(`INFOPLIST_KEY_NSCameraUsageDescription`), so `AVCaptureSession` will prompt correctly.

## Brand assets

The app icon and the launch logo are both generated from the master logo at
`brand/logo-source.png`, so there is one source of truth:

```bash
swift brand/make_icon.swift brand/logo-source.png \
  ios/repQ/Assets.xcassets/AppIcon.appiconset/icon-1024.png 188 205 480 253 0.11
```

The arguments are the crop rect in the source image plus a percentage inset.
The icon uses the barbell mark alone (the wordmark is illegible at 60px); the
splash uses the full lockup including the tagline.

Palette values in `Design.swift` are sampled from the logo itself — lime
`#DFF86C` from the plates, white `#F7F7F7` from the wordmark.

## Files

```
ios/
├── generate_project.py     regenerates repQ.xcodeproj — re-run after adding files
└── repQ/
    ├── repQApp.swift       app entry, tab shell
    ├── Models.swift        machine catalog, splits, weekdays
    ├── Scheduler.swift     the routing algorithm (pure, testable)
    ├── GymStore.swift      observable state + the scanOn/scanOff hooks
    ├── Design.swift        colours and shared components
    ├── TodayView.swift
    ├── ScheduleView.swift
    └── FloorView.swift
```

## Still to build

- Replace simulated members with real routed sessions from a backend
- Unit tests for `Scheduler.swift`
- Per-exercise sets/reps and weight logging
- Push notification when your next machine frees up early
