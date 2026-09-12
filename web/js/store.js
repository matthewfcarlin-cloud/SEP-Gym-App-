/* App state. Every update returns a new state object; nothing is mutated in place. */

const STORAGE_KEY = 'repq.mvp.v1';
const OTHER_MEMBER_COUNT = 6;

const DEFAULT_SCHEDULE = {
  mon: 'push', tue: 'pull', wed: 'legs', thu: 'rest',
  fri: 'upper', sat: 'lower', sun: 'rest',
};

function todayId() {
  return DAYS[(new Date().getDay() + 6) % 7].id; // JS weeks start Sunday; ours start Monday
}

/* Deterministic pseudo-random so a reload doesn't reshuffle the whole gym. */
function seededRandom(seed) {
  let value = seed;
  return () => {
    value = (value * 1103515245 + 12345) % 2147483648;
    return value / 2147483648;
  };
}

function generateOccupancy(machines, seed) {
  const random = seededRandom(seed);
  return machines.reduce((acc, machine) => {
    const busy = Array.from({ length: machine.stations }, () =>
      (random() < 0.34 ? Math.round(random() * machine.minutes) : 0));
    return { ...acc, [machine.id]: busy };
  }, {});
}

function generateOtherMembers(seed) {
  const random = seededRandom(seed + 7);
  const trainable = SPLITS.filter((split) => split.exercises.length > 0);
  return Array.from({ length: OTHER_MEMBER_COUNT }, (_, i) => {
    const split = trainable[Math.floor(random() * trainable.length)];
    return {
      id: `member-${i}`,
      exercises: split.exercises,
      arrivesIn: Math.round(random() * 34),
    };
  });
}

function loadSchedule() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return DEFAULT_SCHEDULE;
    const saved = JSON.parse(raw);
    return { ...DEFAULT_SCHEDULE, ...(saved.schedule || {}) };
  } catch (error) {
    console.warn('Could not read saved schedule, using defaults.', error);
    return DEFAULT_SCHEDULE;
  }
}

function saveSchedule(schedule) {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify({ schedule }));
  } catch (error) {
    console.warn('Could not save schedule; it will reset on reload.', error);
  }
}

function createState() {
  const seed = 20260912;
  return {
    tab: 'today',
    schedule: loadSchedule(),
    editingDay: null,
    today: todayId(),
    occupancy: generateOccupancy(MACHINES, seed),
    others: generateOtherMembers(seed),
    completed: [],
  };
}

/* ---------- updates (all pure) ---------- */

function setTab(state, tab) {
  return { ...state, tab, editingDay: null };
}

function openDayEditor(state, dayId) {
  return { ...state, editingDay: state.editingDay === dayId ? null : dayId };
}

function assignSplit(state, dayId, splitId) {
  const schedule = { ...state.schedule, [dayId]: splitId };
  saveSchedule(schedule);
  return { ...state, schedule, editingDay: null, completed: [] };
}

function completeStep(state, machineId) {
  if (state.completed.includes(machineId)) return state;
  return {
    ...state,
    completed: [...state.completed, machineId],
    // Finishing on a machine frees the station you were using.
    occupancy: { ...state.occupancy, [machineId]: (state.occupancy[machineId] || []).map(() => 0) },
  };
}

function toggleStation(state, machineId, index) {
  const machine = MACHINE_BY_ID[machineId];
  const current = state.occupancy[machineId] || [];
  const next = current.map((minutes, i) =>
    (i === index ? (minutes > 0 ? 0 : machine.minutes) : minutes));
  return { ...state, occupancy: { ...state.occupancy, [machineId]: next } };
}

/* ---------- derived ---------- */

function todaysSplit(state) {
  return SPLIT_BY_ID[state.schedule[state.today]] || SPLIT_BY_ID.rest;
}

function remainingExercises(state) {
  return todaysSplit(state).exercises.filter((id) => !state.completed.includes(id));
}

function currentPlan(state) {
  return planFloor({
    machines: MACHINES,
    machineById: MACHINE_BY_ID,
    occupancy: state.occupancy,
    others: state.others,
    userExercises: remainingExercises(state),
  });
}
