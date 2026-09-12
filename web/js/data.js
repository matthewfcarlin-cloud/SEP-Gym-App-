/* Static catalog: gym machines, training splits, and the exercises in each. */

const MINUTES_PER_EXERCISE = 8; // one person's full occupancy of a machine (sets + rest)

const MACHINES = [
  // group: which training splits this machine serves
  { id: 'squat-rack',   name: 'Squat Rack',        group: 'legs',  stations: 3, minutes: 12, icon: '\u{1F3CB}' },
  { id: 'leg-press',    name: 'Leg Press',         group: 'legs',  stations: 2, minutes: 10, icon: '\u{1F9B5}' },
  { id: 'hack-squat',   name: 'Hack Squat',        group: 'legs',  stations: 1, minutes: 10, icon: '\u{26A1}' },
  { id: 'leg-ext',      name: 'Leg Extension',     group: 'legs',  stations: 2, minutes: 7,  icon: '\u{1F9BF}' },
  { id: 'leg-curl',     name: 'Seated Leg Curl',   group: 'legs',  stations: 2, minutes: 7,  icon: '\u{1F503}' },
  { id: 'hip-thrust',   name: 'Hip Thrust',        group: 'legs',  stations: 1, minutes: 9,  icon: '\u{1F345}' },
  { id: 'calf-raise',   name: 'Calf Raise',        group: 'legs',  stations: 2, minutes: 6,  icon: '\u{1F463}' },

  { id: 'bench',        name: 'Bench Press',       group: 'push',  stations: 3, minutes: 12, icon: '\u{1F6CF}' },
  { id: 'incline-db',   name: 'Incline Dumbbell',  group: 'push',  stations: 4, minutes: 10, icon: '\u{1F4AA}' },
  { id: 'chest-press',  name: 'Chest Press',       group: 'push',  stations: 2, minutes: 8,  icon: '\u{1F9F1}' },
  { id: 'shoulder-press', name: 'Shoulder Press',  group: 'push',  stations: 2, minutes: 8,  icon: '\u{1F3AF}' },
  { id: 'cable-fly',    name: 'Cable Fly',         group: 'push',  stations: 2, minutes: 7,  icon: '\u{1F54A}' },
  { id: 'tricep-push',  name: 'Tricep Pushdown',   group: 'push',  stations: 2, minutes: 6,  icon: '\u{1F53B}' },

  { id: 'pullup',       name: 'Pull-Up Bar',       group: 'pull',  stations: 2, minutes: 8,  icon: '\u{1F6A1}' },
  { id: 'lat-pulldown', name: 'Lat Pulldown',      group: 'pull',  stations: 2, minutes: 9,  icon: '\u{1F3D7}' },
  { id: 'seated-row',   name: 'Seated Cable Row',  group: 'pull',  stations: 2, minutes: 9,  icon: '\u{1F6A3}' },
  { id: 'chest-row',    name: 'Chest-Supported Row', group: 'pull', stations: 1, minutes: 9, icon: '\u{2694}' },
  { id: 'face-pull',    name: 'Face Pull',         group: 'pull',  stations: 2, minutes: 6,  icon: '\u{1F3A3}' },
  { id: 'cable-curl',   name: 'Cable Curl',        group: 'pull',  stations: 2, minutes: 7,  icon: '\u{1F4A5}' },
  { id: 'preacher',     name: 'Preacher Curl',     group: 'pull',  stations: 1, minutes: 7,  icon: '\u{1F64F}' },

  { id: 'cable-crunch', name: 'Cable Crunch',      group: 'core',  stations: 2, minutes: 6,  icon: '\u{1F9FF}' },
  { id: 'ab-machine',   name: 'Ab Machine',        group: 'core',  stations: 1, minutes: 6,  icon: '\u{1F535}' },
];

const MACHINE_BY_ID = Object.freeze(
  MACHINES.reduce((acc, machine) => ({ ...acc, [machine.id]: machine }), {})
);

/* A split is a named day type. Exercises are ordered by training priority:
   index 0 is the heaviest compound and should stay early if at all possible. */
const SPLITS = [
  {
    id: 'push', name: 'Push', tag: 'Chest · Shoulders · Triceps', color: '#ff6b4a',
    exercises: ['bench', 'incline-db', 'shoulder-press', 'chest-press', 'cable-fly', 'tricep-push'],
  },
  {
    id: 'pull', name: 'Pull', tag: 'Back · Biceps', color: '#4ac8ff',
    exercises: ['pullup', 'lat-pulldown', 'seated-row', 'chest-row', 'face-pull', 'cable-curl'],
  },
  {
    id: 'legs', name: 'Legs', tag: 'Quads · Hams · Glutes', color: '#c6f24e',
    exercises: ['squat-rack', 'leg-press', 'hack-squat', 'leg-curl', 'leg-ext', 'calf-raise'],
  },
  {
    id: 'upper', name: 'Upper Body', tag: 'Full upper', color: '#b07bff',
    exercises: ['bench', 'lat-pulldown', 'shoulder-press', 'seated-row', 'cable-curl', 'tricep-push'],
  },
  {
    id: 'lower', name: 'Lower Body', tag: 'Legs · Glutes · Core', color: '#ffd24a',
    exercises: ['squat-rack', 'hip-thrust', 'leg-press', 'leg-curl', 'calf-raise', 'cable-crunch'],
  },
  {
    id: 'full', name: 'Full Body', tag: 'Everything', color: '#4affc0',
    exercises: ['squat-rack', 'bench', 'lat-pulldown', 'leg-press', 'shoulder-press', 'ab-machine'],
  },
  { id: 'rest', name: 'Rest', tag: 'Recovery day', color: '#5a6472', exercises: [] },
];

const SPLIT_BY_ID = Object.freeze(
  SPLITS.reduce((acc, split) => ({ ...acc, [split.id]: split }), {})
);

const DAYS = [
  { id: 'mon', short: 'Mon', name: 'Monday' },
  { id: 'tue', short: 'Tue', name: 'Tuesday' },
  { id: 'wed', short: 'Wed', name: 'Wednesday' },
  { id: 'thu', short: 'Thu', name: 'Thursday' },
  { id: 'fri', short: 'Fri', name: 'Friday' },
  { id: 'sat', short: 'Sat', name: 'Saturday' },
  { id: 'sun', short: 'Sun', name: 'Sunday' },
];
