/*
 * Session router.
 *
 * The gym is modelled as a reservation ledger: every machine owns N stations,
 * and each station carries the minute-offset at which it next becomes free.
 * Live QR scans (from the scan-in feature) seed that ledger with real occupancy.
 *
 * Routing is greedy with lookahead cost:
 *   at each step pick the remaining exercise that minimises
 *       wait_minutes + (training_priority_index * PRIORITY_WEIGHT)
 * so we only reorder a session when skipping ahead saves more time than the
 * training cost of pushing a heavy compound later in the workout.
 *
 * Every member in the gym is routed through the same shared ledger, so one
 * person's reservation is another person's blocked slot. Nobody double-books.
 */

const PRIORITY_WEIGHT = 2.2;   // minutes of waiting we'll accept to keep the planned order
const MAX_REORDER_DRIFT = 3;   // an exercise can only jump this many places forward

/* ---------- ledger ---------- */

/** Build a fresh ledger. `occupancy` maps machineId -> array of minutes-remaining. */
function createLedger(machines, occupancy = {}) {
  return machines.reduce((ledger, machine) => {
    const busy = occupancy[machine.id] || [];
    const stations = Array.from({ length: machine.stations }, (_, i) => busy[i] || 0);
    return { ...ledger, [machine.id]: stations };
  }, {});
}

/** Earliest minute-offset at which `machineId` has a free station. */
function earliestFree(ledger, machineId) {
  const stations = ledger[machineId];
  if (!stations || stations.length === 0) return Infinity;
  return Math.min(...stations);
}

/** Index of the station that frees up first. */
function firstFreeStation(ledger, machineId) {
  const stations = ledger[machineId];
  return stations.indexOf(Math.min(...stations));
}

/** Immutably reserve a machine from `startAt` for `duration` minutes. */
function reserve(ledger, machineId, startAt, duration) {
  const stations = ledger[machineId];
  const slot = firstFreeStation(ledger, machineId);
  const next = stations.map((free, i) => (i === slot ? startAt + duration : free));
  return { ...ledger, [machineId]: next };
}

/* ---------- routing ---------- */

function candidateCost(wait, plannedIndex, stepIndex) {
  const drift = plannedIndex - stepIndex;
  if (drift > MAX_REORDER_DRIFT) return Infinity; // don't strand a lift at the end
  return wait + plannedIndex * PRIORITY_WEIGHT;
}

/**
 * Route one member's exercises through the shared ledger.
 * Returns { steps, ledger, totalWait, finishesAt }.
 */
function routeSession(exerciseIds, machineById, ledger, startMinute = 0) {
  const initial = exerciseIds.map((id, plannedIndex) => ({ id, plannedIndex }));

  return initial.reduce((state, _unused, stepIndex) => {
    const best = state.remaining.reduce((winner, item) => {
      const machine = machineById[item.id];
      const availableAt = Math.max(state.clock, earliestFree(state.ledger, item.id));
      const wait = availableAt - state.clock;
      const cost = candidateCost(wait, item.plannedIndex, stepIndex);
      if (!winner || cost < winner.cost) return { ...item, availableAt, wait, cost, machine };
      return winner;
    }, null);

    if (!best || best.cost === Infinity) {
      // Everything is drift-locked: fall back to the next planned exercise.
      const fallback = state.remaining[0];
      const machine = machineById[fallback.id];
      const availableAt = Math.max(state.clock, earliestFree(state.ledger, fallback.id));
      return commit(state, { ...fallback, machine, availableAt, wait: availableAt - state.clock });
    }
    return commit(state, best);
  }, { remaining: initial, ledger, clock: startMinute, steps: [], totalWait: 0 });
}

function commit(state, choice) {
  const endsAt = choice.availableAt + choice.machine.minutes;
  const step = {
    machineId: choice.id,
    machine: choice.machine,
    station: firstFreeStation(state.ledger, choice.id) + 1,
    startsAt: choice.availableAt,
    endsAt,
    wait: choice.wait,
    plannedIndex: choice.plannedIndex,
  };
  return {
    remaining: state.remaining.filter((item) => item.id !== choice.id),
    ledger: reserve(state.ledger, choice.id, choice.availableAt, choice.machine.minutes),
    clock: endsAt,
    steps: [...state.steps, step],
    totalWait: state.totalWait + choice.wait,
  };
}

/** Cost of just doing the list top-to-bottom, for the "we saved you X" number. */
function naiveWait(exerciseIds, machineById, ledger, startMinute = 0) {
  return exerciseIds.reduce((state, id) => {
    const machine = machineById[id];
    const availableAt = Math.max(state.clock, earliestFree(state.ledger, id));
    return {
      ledger: reserve(state.ledger, id, availableAt, machine.minutes),
      clock: availableAt + machine.minutes,
      wait: state.wait + (availableAt - state.clock),
    };
  }, { ledger, clock: startMinute, wait: 0 }).wait;
}

/**
 * Plan the whole floor: route every other member first (they arrived before
 * you), then route the user around the reservations that leaves behind.
 */
function planFloor({ machines, machineById, occupancy, others, userExercises }) {
  const base = createLedger(machines, occupancy);

  const afterOthers = others.reduce((acc, member) => {
    const routed = routeSession(member.exercises, machineById, acc.ledger, member.arrivesIn);
    return {
      ledger: routed.ledger,
      members: [...acc.members, { ...member, steps: routed.steps }],
    };
  }, { ledger: base, members: [] });

  const user = routeSession(userExercises, machineById, afterOthers.ledger, 0);
  const naive = naiveWait(userExercises, machineById, afterOthers.ledger, 0);

  return {
    steps: user.steps,
    ledger: user.ledger,
    totalWait: Math.round(user.totalWait),
    minutesSaved: Math.max(0, Math.round(naive - user.totalWait)),
    finishesAt: Math.round(user.clock),
    othersRouted: afterOthers.members.length,
  };
}
