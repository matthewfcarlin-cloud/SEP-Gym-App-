# RepQ

A gym app that tells you which machine to use next, so you never wait.

You enter your weekly split. The app reads which machines are actually free — fed by QR
scan-ins on the equipment — and routes you through your session, coordinating with
everyone else training at the same time so two people are never sent to the same station.

## Where things are

| Path | What it is | Owner |
|---|---|---|
| `ios/` | **The app.** SwiftUI, opens in Xcode. Scheduling, routing, all three screens. | Matthew |
| `web/` | Browser prototype of the same idea. Superseded by `ios/` — kept for reference. | — |
| `outputs/Borrow/` | Unrelated earlier equipment-rental demo. Not part of RepQ. | — |

Start here: [`ios/README.md`](ios/README.md).

## The two halves

**Scanning** (QR codes on machines) produces occupancy. **Scheduling** consumes it and
produces a route. They meet at one interface and nothing else:

```swift
store.scanOn(machineID: "squat-rack", station: 2)
store.scanOff(machineID: "squat-rack", station: 2)
```

Keep that contract stable and both halves can change freely underneath it.

## Run it

```bash
open ios/repQ.xcodeproj
```
