// ═══════════════════════════════════════════════════════════════
//  SECURITY LAYER — QuickFix Admin Panel v3.1
//  Priority 1 Security Hardening (2026-07-15)
// ═══════════════════════════════════════════════════════════════

// ── ENVIRONMENT DETECTION ─────────────────────────────────────
const IS_DEV = (
  location.hostname === 'localhost' ||
  location.hostname === '127.0.0.1' ||
  location.hostname.includes('.local') ||
  location.protocol === 'file:'
);

// ── HTML ESCAPE / SANITIZER ───────────────────────────────────
// Use this for ALL user-controlled or API-controlled values
// before inserting them into innerHTML.
const _escEl = document.createElement('textarea');
function esc(str) {
  if (str === null || str === undefined) return '';
  _escEl.textContent = String(str);
  return _escEl.innerHTML;
}

// ── PRODUCTION-SAFE LOGGER ────────────────────────────────────
// console.error only in development. Silent in production.
function logError(context, err) {
  if (IS_DEV) {
    console.error(`[QuickFix Admin] ${context}`, err);
  }
  // Future hook: send to a logging service in production
  // e.g. Sentry.captureException(err, { extra: { context } });
}

// ── KYC MASKING UTILITIES ─────────────────────────────────────
// Masks sensitive fields by default; reveals on controlled click.
function maskKyc(value, keepLast = 4, label = '') {
  if (!value || value === 'N/A') return `<span class="kyc-masked text-muted">N/A</span>`;
  const s = String(value).replace(/\s/g, '');
  if (s.length <= keepLast) return `<span class="kyc-masked">${esc(value)}</span>`;
  const masked = '•'.repeat(s.length - keepLast) + s.slice(-keepLast);
  const safeVal = esc(value);
  return `<span class="kyc-field" data-real="${safeVal}" data-masked="${esc(masked)}">${esc(masked)} <button class="btn-kyc-reveal" onclick="revealKyc(this)" title="Reveal ${esc(label)}"><i class="fa-solid fa-eye fs-11"></i></button></span>`;
}

function revealKyc(btn) {
  const span = btn.parentElement;
  const real = span.getAttribute('data-real');
  const masked = span.getAttribute('data-masked');
  const isRevealed = btn.querySelector('i').className.includes('eye-slash');
  if (isRevealed) {
    span.childNodes[0].textContent = masked + ' ';
    btn.querySelector('i').className = 'fa-solid fa-eye fs-11';
  } else {
    span.childNodes[0].textContent = real + ' ';
    btn.querySelector('i').className = 'fa-solid fa-eye-slash fs-11';
  }
}

// ── TOKEN READY-FOR-MIGRATION ACCESSOR ────────────────────────
// Centralised read/write so we can swap to cookies in one place.
// DO NOT change auth strategy here — just the storage location.
const TokenStore = {
  get()    { return localStorage.getItem('admin_token'); },
  set(val) {
    localStorage.setItem('admin_token', val);
    localStorage.setItem('admin_token_issued', Date.now().toString());
  },
  clear()  {
    localStorage.removeItem('admin_token');
    localStorage.removeItem('admin_token_issued');
  },
  issuedAt() {
    return parseInt(localStorage.getItem('admin_token_issued') || '0', 10);
  }
};

// ── SESSION MANAGEMENT ────────────────────────────────────────
const SESSION_MAX_MS   = 8 * 60 * 60 * 1000; // 8 hours
const SESSION_IDLE_MS  = 30 * 60 * 1000;      // 30 minutes

let _idleTimer = null;
let _refreshInterval = null;

function checkSessionExpiry() {
  const token   = TokenStore.get();
  const issued  = TokenStore.issuedAt();
  if (!token) return;
  if (Date.now() - issued > SESSION_MAX_MS) {
    TokenStore.clear();
    showAdminLoginScreen();
    showToast('Session expired after 8 hours. Please log in again.', 'warning');
  }
}

function resetIdleTimer() {
  clearTimeout(_idleTimer);
  _idleTimer = setTimeout(() => {
    if (!TokenStore.get()) return;
    TokenStore.clear();
    stopPolling();
    showAdminLoginScreen();
    showToast('Auto-logged out due to 30 minutes of inactivity.', 'warning');
  }, SESSION_IDLE_MS);
}

function startSessionWatchdog() {
  // Idle events
  ['mousemove', 'keydown', 'click', 'scroll', 'touchstart'].forEach(evt => {
    document.addEventListener(evt, resetIdleTimer, { passive: true });
  });
  resetIdleTimer();

  // Periodic expiry check (every 2 minutes)
  setInterval(checkSessionExpiry, 2 * 60 * 1000);

  // Recheck on tab focus (covers sleep/wake cycles)
  document.addEventListener('visibilitychange', () => {
    if (!document.hidden) checkSessionExpiry();
  });
}

// ── POLLING CONTROL ───────────────────────────────────────────
function startPolling() {
  if (_refreshInterval) return;
  _refreshInterval = setInterval(() => {
    if (!TokenStore.get()) { stopPolling(); return; }
    if (document.hidden) return; // Pause on hidden tab
    refreshAllData();
  }, 15000);
}

function stopPolling() {
  clearInterval(_refreshInterval);
  _refreshInterval = null;
}
