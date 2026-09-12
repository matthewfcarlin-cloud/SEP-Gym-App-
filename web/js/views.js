/* Rendering. Each view takes state and returns an HTML string. */

const escapeHtml = (value) => String(value).replace(/[&<>"']/g,
  (char) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[char]));

function clockAt(minutesFromNow) {
  const when = new Date(Date.now() + minutesFromNow * 60000);
  return when.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' });
}

function waitLabel(wait) {
  if (wait < 1) return 'Open now · walk straight over';
  return `Free in ${Math.round(wait)} min · finish your rest here`;
}

function freeStationCount(state, machineId) {
  return (state.occupancy[machineId] || []).filter((minutes) => minutes === 0).length;
}

/* ---------- today ---------- */

function renderToday(state) {
  const split = todaysSplit(state);
  if (split.exercises.length === 0) return renderRestDay();

  const plan = currentPlan(state);
  const [next, ...rest] = plan.steps;
  if (!next) return renderSessionComplete(plan);

  return `
    <p class="eyebrow">${escapeHtml(DAYS.find((d) => d.id === state.today).name)} · ${escapeHtml(split.name)} day</p>
    <h2 class="screen-title">Your route</h2>
    <p class="sub">Ordered around ${plan.othersRouted} other members training right now, so you never queue.</p>

    ${renderHero(state, next, plan)}

    <div class="stats">
      <div class="stat"><b>${plan.finishesAt}<small style="font-size:11px"> min</small></b><small>Session length</small></div>
      <div class="stat"><b>${plan.totalWait} min</b><small>Total waiting</small></div>
      <div class="stat win"><b>−${plan.minutesSaved} min</b><small>Queue saved</small></div>
    </div>

    <p class="section-label">Then, in order</p>
    <div class="queue">
      ${rest.map((step, i) => renderStep(step, i + 1)).join('')}
      ${state.completed.map((id) => renderCompleted(id)).join('')}
    </div>`;
}

function renderHero(state, step, plan) {
  const moved = step.plannedIndex > 0;
  return `
    <div class="hero">
      <p class="eyebrow">Next up${moved ? ' · reordered to skip a queue' : ''}</p>
      <div class="hero-row">
        <span class="hero-icon">${step.machine.icon}</span>
        <div>
          <h2>${escapeHtml(step.machine.name)}</h2>
          <p class="hero-meta">${waitLabel(step.wait)}</p>
        </div>
      </div>
      <div class="hero-stats">
        <div class="chip"><b>#${step.station}</b><small>Station</small></div>
        <div class="chip"><b>${step.machine.minutes} min</b><small>On machine</small></div>
        <div class="chip"><b>${clockAt(step.endsAt)}</b><small>Done by</small></div>
      </div>
      <button class="btn" data-done="${step.machineId}">Finished — what's next?</button>
    </div>`;
}

function renderStep(step, position) {
  const moved = step.plannedIndex > position;
  return `
    <div class="step">
      <span class="step-time">${Math.round(step.startsAt)}m</span>
      <div class="step-body">
        <p class="step-name">${escapeHtml(step.machine.name)}${moved ? '<span class="badge-moved">moved up</span>' : ''}</p>
        <p class="step-sub">${step.wait < 1 ? 'No wait' : `${Math.round(step.wait)} min wait`} · ${step.machine.minutes} min · ${clockAt(step.startsAt)}</p>
      </div>
      <span class="step-icon">${step.machine.icon}</span>
    </div>`;
}

function renderCompleted(machineId) {
  const machine = MACHINE_BY_ID[machineId];
  return `
    <div class="step done">
      <span class="step-time">✓</span>
      <div class="step-body">
        <p class="step-name">${escapeHtml(machine.name)}</p>
        <p class="step-sub">Completed</p>
      </div>
      <span class="step-icon">${machine.icon}</span>
    </div>`;
}

function renderRestDay() {
  return `<div class="empty"><span class="big">\u{1F634}</span>
    Rest day. Nothing scheduled — go eat.
    <br><br><button class="btn btn-ghost" data-tab="schedule" style="max-width:220px;margin:0 auto">Edit my week</button></div>`;
}

function renderSessionComplete(plan) {
  return `<div class="empty"><span class="big">\u{1F525}</span>
    Session done. You waited ${plan.totalWait} minutes total.
    <br><br><button class="btn btn-ghost" data-reset="1" style="max-width:220px;margin:0 auto">Start over</button></div>`;
}

/* ---------- schedule ---------- */

function renderSchedule(state) {
  return `
    <p class="eyebrow">Step 1</p>
    <h2 class="screen-title">Your week</h2>
    <p class="sub">Tap a day to set what you're training. We handle the machine order.</p>
    ${DAYS.map((day) => renderDay(state, day)).join('')}`;
}

function renderDay(state, day) {
  const split = SPLIT_BY_ID[state.schedule[day.id]] || SPLIT_BY_ID.rest;
  const isEditing = state.editingDay === day.id;
  const isToday = state.today === day.id;
  return `
    <div class="day${split.id === 'rest' ? '' : ' active'}" data-day="${day.id}">
      <div class="day-abbr" style="${split.id === 'rest' ? '' : `background:${split.color}`}">${day.short.toUpperCase()}</div>
      <div class="day-body">
        <p class="day-split">${escapeHtml(split.name)}${isToday ? '<span class="badge-moved">today</span>' : ''}</p>
        <p class="day-tag">${escapeHtml(split.tag)}</p>
      </div>
      <span class="day-arrow">${isEditing ? '✕' : '›'}</span>
    </div>
    ${isEditing ? renderPicker(state, day) : ''}`;
}

function renderPicker(state, day) {
  return `<div class="picker" style="margin:-2px 0 12px">
    ${SPLITS.map((split) => `
      <button class="pick${state.schedule[day.id] === split.id ? ' on' : ''}"
              data-day="${day.id}" data-split="${split.id}">
        <b>${escapeHtml(split.name)}</b><small>${escapeHtml(split.tag)}</small>
      </button>`).join('')}
  </div>`;
}

/* ---------- floor ---------- */

function renderFloor(state) {
  const totalFree = MACHINES.reduce((sum, m) => sum + freeStationCount(state, m.id), 0);
  const totalStations = MACHINES.reduce((sum, m) => sum + m.stations, 0);
  return `
    <p class="eyebrow">Live floor</p>
    <h2 class="screen-title">${totalFree} of ${totalStations} open</h2>
    <p class="sub">Fed by QR scan-ins at each machine. Tap a station to simulate a member scanning on or off — your route reorders instantly.</p>
    ${MACHINES.map((machine) => renderMachine(state, machine)).join('')}`;
}

function renderMachine(state, machine) {
  const stations = state.occupancy[machine.id] || [];
  const free = stations.filter((m) => m === 0).length;
  return `
    <div class="machine">
      <span style="font-size:20px">${machine.icon}</span>
      <div>
        <p class="machine-name">${escapeHtml(machine.name)}</p>
        <p class="machine-sub">${free === 0
          ? `All busy · free in ~${Math.min(...stations)} min`
          : `${free} of ${machine.stations} open`}</p>
      </div>
      <div class="stations">
        ${stations.map((minutes, i) => `
          <span class="station${minutes > 0 ? ' busy' : ''}"
                data-machine="${machine.id}" data-station="${i}"
                title="${minutes > 0 ? `${minutes} min left` : 'Open'}"></span>`).join('')}
      </div>
    </div>`;
}

/* ---------- shell ---------- */

const TABS = [
  { id: 'today', icon: '\u{1F3AF}', label: 'TODAY' },
  { id: 'schedule', icon: '\u{1F4C5}', label: 'MY WEEK' },
  { id: 'floor', icon: '\u{1F4CD}', label: 'FLOOR' },
];

function renderApp(state) {
  const body = state.tab === 'schedule' ? renderSchedule(state)
    : state.tab === 'floor' ? renderFloor(state)
    : renderToday(state);

  return `
    <div class="topbar">
      <div class="brand"><h1>Next<span>Up</span></h1></div>
      <div class="live"><span class="dot"></span>${state.others.length + 1} in gym</div>
    </div>
    ${body}
    <nav class="tabs">
      ${TABS.map((tab) => `
        <button class="tab${state.tab === tab.id ? ' on' : ''}" data-tab="${tab.id}">
          <i>${tab.icon}</i>${tab.label}
        </button>`).join('')}
    </nav>`;
}
