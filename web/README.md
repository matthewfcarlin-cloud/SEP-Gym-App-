# repQ — gym session router

The scheduling half of the gym app. You set your weekly split; the app reads live
machine occupancy and tells you **which machine to walk to next**, ordered so you
never stand in a queue — and so your route doesn't collide with anyone else's.

## Run it

```bash
cd web && python3 -m http.server 4173
```

Open <http://localhost:4173>. No build step, no dependencies — plain HTML/CSS/JS.

## The three screens

| Screen | What it does |
|---|---|
| **My Week** | Assign a split (Push / Pull / Legs / Upper / Lower / Full / Rest) to each day. Saved to `localStorage`. |
| **Today** | Your routed session: next machine + station number, wait time, full ordered queue, and how many minutes of queueing the routing saved you. |
| **Floor** | Live occupancy per machine. Tap a station to simulate a scan-on / scan-off — the route re-plans instantly. |

## How the routing works

`js/scheduler.js` is the whole algorithm and has no DOM dependencies.

The gym is a **reservation ledger**: every machine owns N stations, each carrying the
minute-offset at which it next becomes free. Live QR scan-ins seed that ledger.

Routing is greedy with a training-priority cost. At each step it picks the remaining
exercise that minimises:

```
cost = wait_minutes + (planned_position × PRIORITY_WEIGHT)
```

So it only reorders your session when skipping ahead saves more time than the training
cost of pushing a heavy compound later. `MAX_REORDER_DRIFT` stops a big lift from being
stranded at the end of the workout.

Crucially, **every member is routed through the same ledger**. Other members are routed
first (they arrived first), and their reservations become blocked slots for you. One
person's booking is another person's wall, so two people are never sent to the same
station at the same time.

`planFloor()` also routes your session a second time in naive top-to-bottom order and
reports the difference — that's the "queue saved" number on the Today screen.

## Hooking up the QR scanner

The scanner only needs to produce one thing: **occupancy**.

```js
// machineId -> array of minutes-remaining, one entry per station.
// 0 means that station is open right now.
const occupancy = {
  'squat-rack': [0, 9, 0],   // 3 racks, the middle one is busy for 9 more minutes
  'leg-press':  [4, 0],
};
```

On a scan-on, set that station to the machine's `minutes` value from `js/data.js`.
On a scan-off, set it to `0`. Drop the object into `state.occupancy` and re-render —
`currentPlan()` re-routes from scratch every render, so nothing else needs to change.

Machine IDs live in `js/data.js` and are what the QR codes should encode
(e.g. `repq://machine/squat-rack/2` for station 2).

## Files

```
web/
├── index.html
├── styles.css
└── js/
    ├── data.js       machine catalog + split definitions
    ├── scheduler.js  the routing algorithm (pure, testable)
    ├── store.js      state + localStorage + simulated gym traffic
    ├── views.js      rendering
    └── app.js        event wiring
```

## Still to build

- Replace simulated members with real routed sessions from the backend
- Real clock times instead of minute offsets from "now"
- Per-exercise sets/reps and weight logging
- Push notification when your next machine frees up early
