/* Wiring: one state object, one render pass, delegated click handling. */

let state = createState();
const root = document.getElementById('app');

function render() {
  root.innerHTML = renderApp(state);
}

function update(next) {
  state = next;
  render();
}

function handleClick(event) {
  const target = event.target.closest('[data-tab],[data-done],[data-reset],[data-split],[data-day],[data-station]');
  if (!target) return;

  const { tab, done, reset, split, day, machine, station } = target.dataset;

  if (station !== undefined) return update(toggleStation(state, machine, Number(station)));
  if (split) return update(assignSplit(state, day, split));
  if (day) return update(openDayEditor(state, day));
  if (done) return update(completeStep(state, done));
  if (reset) return update({ ...state, completed: [], occupancy: createState().occupancy });
  if (tab) return update(setTab(state, tab));
}

root.addEventListener('click', handleClick);
render();

/* The floor keeps moving: tick occupancy down so waits feel live. */
setInterval(() => {
  if (state.tab === 'schedule') return; // don't yank the UI mid-edit
  const occupancy = Object.entries(state.occupancy).reduce((acc, [id, stations]) => ({
    ...acc,
    [id]: stations.map((minutes) => Math.max(0, minutes - 1)),
  }), {});
  update({ ...state, occupancy });
}, 15000);
