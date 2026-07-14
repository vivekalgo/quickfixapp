const API_URL = 'https://quickfixapp-production.up.railway.app/api';

// Global fetch interceptor for Admin Auth Token
const originalFetch = window.fetch;
window.fetch = function (url, options = {}) {
  const token = localStorage.getItem('admin_token');
  if (token) {
    options.headers = options.headers || {};
    if (!(options.headers instanceof Headers)) {
      options.headers['Authorization'] = `Bearer ${token}`;
    } else {
      options.headers.set('Authorization', `Bearer ${token}`);
    }
  }
  return originalFetch(url, options).then(response => {
    if ((response.status === 401 || response.status === 403) && !url.includes('/admin/login')) {
      localStorage.removeItem('admin_token');
      showAdminLoginScreen();
    }
    return response;
  });
};

function showAdminLoginScreen() {
  const overlay = document.getElementById('admin-login-overlay');
  if (overlay) {
    overlay.style.display = 'flex';
  }
}

function hideAdminLoginScreen() {
  const overlay = document.getElementById('admin-login-overlay');
  if (overlay) {
    overlay.style.display = 'none';
  }
}

// Setup Admin Login Event Listeners
document.addEventListener('DOMContentLoaded', () => {
  const loginForm = document.getElementById('admin-login-form');
  const passwordInput = document.getElementById('admin-login-password');
  const errorDiv = document.getElementById('admin-login-error');

  if (loginForm) {
    loginForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      const password = passwordInput.value;
      
      try {
        const response = await originalFetch(`${API_URL}/admin/login`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ password })
        });
        
        const data = await response.json();
        if (response.ok && data.token) {
          localStorage.setItem('admin_token', data.token);
          errorDiv.style.display = 'none';
          passwordInput.value = '';
          hideAdminLoginScreen();
          refreshAllData().then(() => {
            renderShopCategoriesCheckbox();
          });
        } else {
          errorDiv.textContent = data.error || 'Incorrect password. Please try again.';
          errorDiv.style.display = 'block';
        }
      } catch (err) {
        errorDiv.textContent = 'Connection to authentication server failed.';
        errorDiv.style.display = 'block';
      }
    });
  }

  // Check auth state immediately
  const token = localStorage.getItem('admin_token');
  if (!token) {
    showAdminLoginScreen();
  }
});

// State variables
let shops = [];
let bookings = [];
let banners = [];
let offers = [];
let alerts = [];
let users = [];
let categories = [];
let settings = {};
let auditLogs = [];
let demands = [];

// DOM Elements
const navItems = document.querySelectorAll('.nav-item');
const tabPanes = document.querySelectorAll('.tab-pane');
const tabTitle = document.getElementById('tab-title');
const themeToggle = document.getElementById('theme-toggle');

// Initial Load
document.addEventListener('DOMContentLoaded', () => {
  setupTabs();
  setupModals();
  setupForms();
  setupServicesEvents();
  setupTheme();
  setupSubtabs();
  setupCmsEvents();
  setupCmsForms();
  setupCategoryImageUpload();
  setupBannerImageUpload();
  
  // Custom Filters & Dropdowns
  const statusFilter = document.getElementById('booking-filter-status');
  if (statusFilter) {
    statusFilter.addEventListener('change', renderManageBookingsTable);
  }

  // Shop filter tabs
  const shopFilters = document.querySelectorAll('.tab-filter');
  shopFilters.forEach(btn => {
    btn.addEventListener('click', () => {
      shopFilters.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      renderShopsList();
    });
  });
  
  // Initial loading sequence
  const token = localStorage.getItem('admin_token');
  if (token) {
    refreshAllData().then(() => {
      renderShopCategoriesCheckbox();
    });
  }
  
  // Refresh loop every 10 seconds to keep stats and live stream up to date
  setInterval(() => {
    if (localStorage.getItem('admin_token')) {
      refreshAllData();
    }
  }, 10000);
});

// Toast notification helper
function showToast(message, type = 'success') {
  const container = document.getElementById('toast-container');
  if (!container) return;

  const toast = document.createElement('div');
  toast.className = `toast toast-${type}`;
  
  let icon = 'fa-circle-check';
  if (type === 'error') icon = 'fa-circle-xmark';
  if (type === 'warning') icon = 'fa-triangle-exclamation';
  
  toast.innerHTML = `
    <i class="fa-solid ${icon}"></i>
    <span>${message}</span>
  `;
  container.appendChild(toast);
  
  setTimeout(() => {
    toast.style.opacity = '0';
    toast.style.transform = 'translateY(10px)';
    toast.style.transition = 'all 0.3s ease-out';
    setTimeout(() => toast.remove(), 300);
  }, 4000);
}

// Write operational Audit Log to backend
async function logAdminActivity(action, target, details) {
  try {
    await fetch(`${API_URL}/audit-logs`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ action, target, details })
    });
  } catch (e) {
    console.error('Audit logging failed:', e);
  }
}

// Theme setup & toggle
function setupTheme() {
  const currentTheme = localStorage.getItem('theme') || 'dark';
  document.documentElement.setAttribute('data-theme', currentTheme);
  updateThemeIcon(currentTheme);

  themeToggle.addEventListener('click', () => {
    const theme = document.documentElement.getAttribute('data-theme') === 'dark' ? 'light' : 'dark';
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem('theme', theme);
    updateThemeIcon(theme);
    showToast(`Switched to ${theme} mode`, 'success');
    renderCharts(); // Redraw charts with correct theme colors
  });
}

function updateThemeIcon(theme) {
  const icon = themeToggle.querySelector('i');
  if (theme === 'dark') {
    icon.className = 'fa-solid fa-sun';
  } else {
    icon.className = 'fa-solid fa-moon';
  }
}

// Setup tab switches
function setupTabs() {
  navItems.forEach(item => {
    item.addEventListener('click', (e) => {
      e.preventDefault();
      const tabId = item.getAttribute('data-tab');
      
      navItems.forEach(i => i.classList.remove('active'));
      tabPanes.forEach(pane => pane.classList.remove('active'));
      
      item.classList.add('active');
      document.getElementById(tabId).classList.add('active');
      tabTitle.textContent = item.textContent.trim();

      // Hook tab-specific fetch sequences
      if (tabId === 'demand-tab') loadDemands();
      if (tabId === 'customers-tab') loadCustomers();
      if (tabId === 'payments-tab') loadPaymentStats();
      if (tabId === 'categories-tab') loadCategories();
      if (tabId === 'reports-tab') loadReports();
      if (tabId === 'settings-tab') loadSettings();
      if (tabId === 'audit-logs-tab') loadAuditLogs();
      if (tabId === 'cms-tab') loadCmsData();
    });
  });
}

// Setup modals opening/closing
function setupModals() {
  // Banner modal
  document.getElementById('btn-add-banner-modal').addEventListener('click', () => {
    document.getElementById('banner-modal-title').textContent = "Create Carousel Banner";
    document.getElementById('edit-banner-id').value = "";
    document.getElementById('banner-form').reset();
    
    // Clear banner file input and preview
    const fileInput = document.getElementById('banner-image-file');
    if (fileInput) fileInput.value = '';
    const fileNameSpan = document.getElementById('banner-image-file-name');
    if (fileNameSpan) fileNameSpan.textContent = 'No file chosen';
    const previewImg = document.getElementById('banner-image-preview');
    if (previewImg) previewImg.src = '';
    const previewContainer = document.getElementById('banner-image-preview-container');
    if (previewContainer) previewContainer.style.display = 'none';
    
    document.getElementById('banner-modal').classList.add('active');
  });
  
  // Offer modal
  document.getElementById('btn-add-offer-modal').addEventListener('click', () => {
    document.getElementById('offer-modal-title').textContent = "Create Promo Coupon";
    document.getElementById('edit-offer-mode').value = "create";
    document.getElementById('offer-code').disabled = false;
    document.getElementById('offer-form').reset();
    document.getElementById('offer-modal').classList.add('active');
  });
  
  // Close triggers
  document.querySelectorAll('.close-modal').forEach(btn => {
    btn.addEventListener('click', () => {
      const modalId = btn.getAttribute('data-modal');
      document.getElementById(modalId).classList.remove('active');
    });
  });
}

// Refresh all primary data collections
async function refreshAllData() {
  await Promise.all([
    fetchShops(),
    fetchBookings(),
    fetchBanners(),
    fetchOffers(),
    fetchAlerts(),
    fetchCategories()
  ]);
  
  updateDashboardStats();
  renderBookingsTable();
  renderManageBookingsTable();
  renderShopsList();
  renderBannersGrid();
  renderOffersGrid();
  renderAlertsHistory();
}

// Fetch helper functions
async function fetchShops() {
  try {
    const res = await fetch(`${API_URL}/shops/all`);
    shops = await res.json();
  } catch (e) {
    console.error('Error fetching shops:', e);
  }
}

async function fetchBookings() {
  try {
    const res = await fetch(`${API_URL}/bookings`);
    bookings = await res.json();
  } catch (e) {
    console.error('Error fetching bookings:', e);
  }
}

async function fetchBanners() {
  try {
    const res = await fetch(`${API_URL}/banners`);
    banners = await res.json();
  } catch (e) {
    console.error('Error fetching banners:', e);
  }
}

async function fetchOffers() {
  try {
    const res = await fetch(`${API_URL}/offers`);
    offers = await res.json();
  } catch (e) {
    console.error('Error fetching offers:', e);
  }
}

async function fetchAlerts() {
  try {
    const res = await fetch(`${API_URL}/notifications`);
    alerts = await res.json();
  } catch (e) {
    console.error('Error fetching alerts:', e);
  }
}

async function fetchCategories() {
  try {
    const res = await fetch(`${API_URL}/categories`);
    categories = await res.json();
  } catch (e) {
    console.error('Error fetching categories:', e);
  }
}

// Render categories checkbox inside Register Shop form
function renderShopCategoriesCheckbox() {
  const container = document.getElementById('shop-form-categories');
  if (!container) return;
  container.innerHTML = '';
  if (categories.length === 0) {
    container.innerHTML = '<p style="font-size:11px;color:var(--text-muted);">No categories available. Please add categories first.</p>';
    return;
  }
  categories.forEach(c => {
    const label = document.createElement('label');
    label.innerHTML = `<input type="checkbox" name="categories" value="${c.id}"> ${c.name}`;
    container.appendChild(label);
  });
}

// Update dashboard stats cards dynamically
async function updateDashboardStats() {
  try {
    const res = await fetch(`${API_URL}/admin/stats`);
    const stats = await res.json();

    document.getElementById('stat-customers').textContent = stats.totalCustomers;
    document.getElementById('stat-shops').textContent = stats.totalShops;
    document.getElementById('stat-providers').textContent = stats.totalProviders;
    document.getElementById('stat-active-b').textContent = stats.activeBookings;
    document.getElementById('stat-pending-b').textContent = stats.pendingBookings;
    document.getElementById('stat-completed-b').textContent = stats.completedBookings;
    document.getElementById('stat-cancelled-b').textContent = stats.cancelledBookings;
    document.getElementById('stat-revenue').textContent = `₹${stats.revenue.toLocaleString()}`;
    document.getElementById('stat-wallet').textContent = `₹${stats.walletBalance.toLocaleString()}`;
    document.getElementById('stat-online-s').textContent = stats.onlineShops;
    document.getElementById('stat-offline-s').textContent = stats.offlineShops;
    document.getElementById('stat-services').textContent = stats.totalServices;
    document.getElementById('stat-coupons').textContent = stats.activeCoupons;
    document.getElementById('stat-notifications').textContent = stats.notificationsSent;
    document.getElementById('stat-today-orders').textContent = stats.todaysOrders;
    
    // Weekly and Monthly estimates from completed bookings
    document.getElementById('stat-weekly-reports').textContent = `₹${(stats.revenue * 0.25).toFixed(0).toLocaleString()}`;
    document.getElementById('stat-monthly-reports').textContent = `₹${stats.revenue.toLocaleString()}`;
  } catch (e) {
    console.error('Error updating dashboard stats:', e);
  }
}

// Render dynamic tables
function renderBookingsTable() {
  const tbody = document.getElementById('bookings-tbody');
  if (!tbody) return;
  tbody.innerHTML = '';
  
  if (bookings.length === 0) {
    tbody.innerHTML = '<tr><td colspan="6" style="text-align:center;color:var(--text-secondary);">No active bookings streaming...</td></tr>';
    return;
  }
  
  bookings.slice(0, 10).forEach(b => {
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td>${b.id}</td>
      <td>${b.customerName}</td>
      <td>${b.providerName}</td>
      <td style="color:var(--primary-solid); font-weight: 600;">₹${b.amount}</td>
      <td>${new Date(b.date).toLocaleDateString('en-GB')} • ${b.slot}</td>
      <td><span class="badge badge-${b.status}">${b.status.replace('_', ' ')}</span></td>
    `;
    tbody.appendChild(tr);
  });
}

// Render active registered shops list with admin features
function renderShopsList() {
  const container = document.getElementById('shops-list');
  if (!container) return;
  
  const activeFilterBtn = document.querySelector('.tab-filter.active');
  const filterVal = activeFilterBtn ? activeFilterBtn.getAttribute('data-filter') : 'all';
  
  container.innerHTML = '';
  
  const filteredShops = shops.filter(s => {
    if (filterVal === 'all') return true;
    if (filterVal === 'approved') return s.verificationStatus === 'approved';
    if (filterVal === 'pending') return s.verificationStatus === 'pending';
    if (filterVal === 'suspended') return s.status === 'suspended';
    return true;
  });
  
  if (filteredShops.length === 0) {
    container.innerHTML = '<p style="text-align:center;color:var(--text-secondary);padding:20px;">No matching shops found.</p>';
    return;
  }
  
  filteredShops.forEach(s => {
    const div = document.createElement('div');
    div.className = 'shop-list-item';
    
    // Checkboxes & labels
    const isOnlineChecked = s.isOnline ? 'checked' : '';
    const isLoginDisabled = s.loginDisabled ? 'checked' : '';
    
    // Badges
    let verifyBadge = '';
    if (s.verificationStatus === 'approved') verifyBadge = '<span class="badge badge-active">Approved</span>';
    else if (s.verificationStatus === 'pending') verifyBadge = '<span class="badge badge-pending">Pending Approval</span>';
    else verifyBadge = '<span class="badge badge-suspended">Rejected</span>';

    let suspendBadge = s.status === 'suspended' ? '<span class="badge badge-suspended" style="margin-left: 5px;">Suspended</span>' : '';

    div.innerHTML = `
      <div class="shop-info" style="flex-grow: 1;">
        <h4 style="display:flex; align-items:center; gap:8px;">${s.name} <span style="font-size:11px;color:var(--text-muted);">(${s.shopDisplayId || 'No ID'})</span> ${verifyBadge} ${suspendBadge}</h4>
        <p>Owner: ${s.ownerName} • Phone: ${s.phone} • Email: ${s.email || 'N/A'}</p>
        <p style="font-size:11px;color:var(--primary-solid);margin-top:4px;">Coords: ${s.latitude}, ${s.longitude} • Radius: ${s.serviceRadius}km • Visiting Charges: ₹${s.visitingCharges}</p>
        <p style="font-size:11px;color:var(--text-muted);margin-top:2px;">GST: ${s.gst || 'N/A'} • PAN: ${s.pan || 'N/A'} • Aadhaar: ${s.aadhaar || 'N/A'}</p>
        <p style="font-size:11px;color:var(--text-secondary);margin-top:2px;">Bank Acc: ${s.bankAccountNumber || 'N/A'} • IFSC: ${s.ifscCode || 'N/A'} • UPI ID: ${s.upiId || 'N/A'}</p>
        <p style="font-size:11px;color:var(--text-secondary);margin-top:2px;">Owner Phone: ${s.ownerPhone || 'N/A'} • Owner Email: ${s.ownerEmail || 'N/A'}</p>
        <p style="font-size:11px;color:var(--text-primary);margin-top:2px;font-weight:600;">Wallet: ₹${(s.walletBalance || 0).toFixed(2)} • Commission: ${s.commissionRate !== undefined ? s.commissionRate : 15}% • Onboarding: ${s.isFirstLogin === false ? '✅ Completed' : '⏳ Pending'}</p>
        <p style="font-size:11px;color:var(--warning);margin-top:2px; font-family: monospace;">Login ID: ${s.shopDisplayId || 'N/A'} • Password: ${s.tempPassword || 'N/A'}</p>
        <p style="font-size:12px;color:var(--accent);margin-top:4px;font-weight:600;">⭐ ${(s.rating || 5.0).toFixed(1)} <span style="font-weight:400;color:var(--text-muted);">(${ (s.reviewsCount || 0)} reviews)</span></p>
      </div>
      <div class="shop-actions">
        <div style="display:flex; gap:12px; align-items:center; font-size:11px;">
          <div style="display:flex; align-items:center; gap:4px;">
            <span>Online</span>
            <label class="switch">
              <input type="checkbox" ${isOnlineChecked} onchange="toggleShopOnline('${s.id}', ${!s.isOnline})">
              <span class="slider"></span>
            </label>
          </div>
          <div style="display:flex; align-items:center; gap:4px;">
            <span>Disable Login</span>
            <label class="switch">
              <input type="checkbox" ${isLoginDisabled} onchange="toggleShopLogin('${s.id}', ${!s.loginDisabled})">
              <span class="slider"></span>
            </label>
          </div>
        </div>
        <div style="display:flex; gap:6px; margin-top:8px;">
          ${s.verificationStatus === 'pending' ? `<button class="btn btn-primary btn-sm" onclick="approveShop('${s.id}', 'approved')"><i class="fa-solid fa-check"></i> Approve</button>` : ''}
          ${s.verificationStatus === 'pending' ? `<button class="btn btn-danger btn-sm" onclick="approveShop('${s.id}', 'rejected')"><i class="fa-solid fa-xmark"></i> Reject</button>` : ''}
          ${s.status === 'active' ? `<button class="btn btn-danger btn-sm" onclick="suspendShop('${s.id}', true)"><i class="fa-solid fa-ban"></i> Suspend</button>` : `<button class="btn btn-secondary btn-sm" onclick="suspendShop('${s.id}', false)"><i class="fa-solid fa-unlock"></i> Unsuspend</button>`}
          <button class="btn btn-secondary btn-sm" onclick="resetShopPassword('${s.id}')"><i class="fa-solid fa-key"></i> Pass Reset</button>
          <button class="btn btn-secondary btn-sm" onclick="openServicesModal('${s.id}')"><i class="fa-solid fa-gears"></i> Services</button>
          <button class="btn btn-secondary btn-sm" onclick="editShop('${s.id}')"><i class="fa-solid fa-pen"></i></button>
          <button class="btn btn-danger btn-sm btn-icon" onclick="deleteShop('${s.id}')" title="Delete Shop"><i class="fa-solid fa-trash-can"></i></button>
        </div>
      </div>
    `;
    container.appendChild(div);
  });
}

// Render banners grid with edit/delete functions
function renderBannersGrid() {
  const grid = document.getElementById('banners-grid');
  if (!grid) return;
  grid.innerHTML = '';
  
  if (banners.length === 0) {
    grid.innerHTML = '<p style="color:var(--text-secondary);grid-column:1/-1;text-align:center;padding:20px;">No custom banners created.</p>';
    return;
  }
  
  banners.forEach(b => {
    const div = document.createElement('div');
    div.className = 'banner-item';
    div.innerHTML = `
      <img src="${b.imageUrl}" alt="${b.title}">
      <div class="banner-details">
        <h4>${b.title}</h4>
        <p>Code: ${b.code} • Tag: ${b.percent}</p>
        <p style="font-size:11px;color:var(--text-muted);margin-top:4px;">Redirect: ${b.redirectUrl || 'None'} • Order: ${b.priority || 0}</p>
        <p style="font-size:11px;color:var(--text-muted);">Expires: ${b.expiryDate || 'Never'}</p>
      </div>
      <div class="toggle-switch">
        <div style="display:flex; align-items:center; gap:8px;">
          <span>Active State</span>
          <label class="switch">
            <input type="checkbox" ${b.isActive ? 'checked' : ''} onchange="toggleBanner('${b.id}')">
            <span class="slider"></span>
          </label>
        </div>
        <div>
          <button class="btn btn-icon" onclick="editBanner('${b.id}')" title="Edit Banner" style="padding: 4px; font-size:12px; color:var(--primary-solid);"><i class="fa-solid fa-pen"></i></button>
          <button class="btn btn-icon btn-delete" onclick="deleteBanner('${b.id}')" title="Delete Banner" style="padding: 4px; font-size:12px; color:var(--danger);"><i class="fa-solid fa-trash-can"></i></button>
        </div>
      </div>
    `;
    grid.appendChild(div);
  });
}

// Render offers coupons grid
function renderOffersGrid() {
  const grid = document.getElementById('offers-grid');
  if (!grid) return;
  grid.innerHTML = '';
  
  if (offers.length === 0) {
    grid.innerHTML = '<p style="color:var(--text-secondary);grid-column:1/-1;text-align:center;padding:20px;">No promo offers created.</p>';
    return;
  }
  
  offers.forEach(o => {
    const div = document.createElement('div');
    div.className = 'offer-item';
    div.innerHTML = `
      <div class="offer-details">
        <h4 style="color:var(--primary-solid); font-weight:700;">Code: ${o.code}</h4>
        <p><strong>${o.title}</strong></p>
        <p>${o.description}</p>
        <p style="font-size:11px;color:var(--text-muted);margin-top:6px;">Min Order: ₹${o.minOrderAmount || 0} • Max Discount: ₹${o.maxDiscount || 0}</p>
        <p style="font-size:11px;color:var(--text-muted);">Expiry: ${o.expiryDate || 'N/A'} • Limit: ${o.usageLimit || 0} (Used: ${o.usedCount || 0})</p>
      </div>
      <div class="toggle-switch">
        <div style="display:flex; align-items:center; gap:8px;">
          <span>Active State</span>
          <label class="switch">
            <input type="checkbox" ${o.isActive ? 'checked' : ''} onchange="toggleOffer('${o.code}')">
            <span class="slider"></span>
          </label>
        </div>
        <div>
          <button class="btn btn-icon" onclick="editOffer('${o.code}')" title="Edit Coupon" style="padding: 4px; font-size:12px; color:var(--primary-solid);"><i class="fa-solid fa-pen"></i></button>
          <button class="btn btn-icon btn-delete" onclick="deleteOffer('${o.code}')" title="Delete Offer" style="padding: 4px; font-size:12px; color:var(--danger);"><i class="fa-solid fa-trash-can"></i></button>
        </div>
      </div>
    `;
    grid.appendChild(div);
  });
}

// Render alerts notifications history
function renderAlertsHistory() {
  const container = document.getElementById('alerts-history');
  if (!container) return;
  container.innerHTML = '';
  
  if (alerts.length === 0) {
    container.innerHTML = '<p style="text-align:center;color:var(--text-secondary);padding:20px;">No notifications broadcasted yet.</p>';
    return;
  }
  
  alerts.forEach(a => {
    const div = document.createElement('div');
    div.className = 'alert-history-item';
    div.style = "border-bottom:1px solid var(--border); padding: 12px 0;";
    div.innerHTML = `
      <h4 style="display:flex; justify-content:space-between; font-size:13px;">${a.title} <span style="font-size:10px; color:var(--text-muted);">${new Date(a.createdAt || Date.now()).toLocaleString()}</span></h4>
      <p style="font-size:12px; color:var(--text-secondary); margin-top:4px;">${a.body}</p>
    `;
    container.appendChild(div);
  });
}

// Toggle banner status
async function toggleBanner(id) {
  try {
    await fetch(`${API_URL}/banners/toggle`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id })
    });
    showToast('Banner visibility toggled', 'success');
    refreshAllData();
  } catch (e) {
    console.error('Error toggling banner:', e);
  }
}

// Toggle offer status
async function toggleOffer(code) {
  try {
    await fetch(`${API_URL}/offers/toggle`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ code })
    });
    showToast('Coupon status updated', 'success');
    refreshAllData();
  } catch (e) {
    console.error('Error toggling offer:', e);
  }
}

// Setup Form Submissions
function setupForms() {
  // 1. Register Shop Form
  document.getElementById('shop-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    
    // Get checked categories
    const checkedCats = [];
    document.querySelectorAll('input[name="categories"]:checked').forEach(cb => {
      checkedCats.push(cb.value);
    });
    
    const shopIdVal = document.getElementById('edit-shop-id').value;
    
    const bodyData = {
      name: document.getElementById('shop-name').value,
      ownerName: document.getElementById('owner-name').value,
      phone: document.getElementById('shop-phone').value,
      email: document.getElementById('shop-email').value,
      latitude: parseFloat(document.getElementById('shop-lat').value),
      longitude: parseFloat(document.getElementById('shop-lng').value),
      address: document.getElementById('shop-address').value,
      serviceRadius: parseFloat(document.getElementById('shop-radius').value) || 5.0,
      visitingCharges: parseFloat(document.getElementById('shop-visiting-charges').value) || 150,
      timings: document.getElementById('shop-timings').value,
      verificationStatus: document.getElementById('shop-verification').value,
      gst: document.getElementById('shop-gst').value,
      pan: document.getElementById('shop-pan').value,
      aadhaar: document.getElementById('shop-aadhaar').value,
      verificationDocs: document.getElementById('shop-docs').value.split('\n').filter(d => d.trim().length > 0),
      categories: checkedCats,
      estimatedServiceTime: document.getElementById('shop-estimated-time').value,
      priceRange: document.getElementById('shop-price-range').value,
      rating: parseFloat(document.getElementById('shop-rating').value) || 5.0,
      reviewsCount: parseInt(document.getElementById('shop-reviews-count').value) || 0,
      ownerPhone: document.getElementById('shop-owner-phone').value,
      ownerEmail: document.getElementById('shop-owner-email').value,
      bankAccountNumber: document.getElementById('shop-bank-number').value,
      ifscCode: document.getElementById('shop-ifsc').value,
      upiId: document.getElementById('shop-upi-id').value,
      commissionRate: parseFloat(document.getElementById('shop-commission-rate').value) || 15.0,
      walletBalance: parseFloat(document.getElementById('shop-wallet-balance').value) || 0.0
    };
    
    try {
      let res, data;
      if (shopIdVal) {
        // Edit Shop mode
        bodyData.id = shopIdVal;
        res = await fetch(`${API_URL}/shops/update`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(bodyData)
        });
        data = await res.json();
        if (data.success) {
          showToast(`Shop "${bodyData.name}" details updated successfully!`, 'success');
          await logAdminActivity('Update Shop', shopIdVal, `Updated details for ${bodyData.name}`);
        }
      } else {
        // Create Shop mode
        res = await fetch(`${API_URL}/shops/register`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(bodyData)
        });
        data = await res.json();
        if (data.success) {
          showToast(`Shop "${bodyData.name}" registered successfully!`, 'success');
          await logAdminActivity('Register Shop', data.shop.shopDisplayId, `Registered new shop ${bodyData.name}`);
          
          // Display credentials copy dialog
          alert(`Shop Partner Credentials Generated!\n\nShop ID: ${data.shop.shopDisplayId}\nTemporary Password: ${data.shop.tempPassword}\n\nPlease share these credentials securely with the provider.`);
        } else {
          showToast(data.error || 'Failed to create shop', 'error');
        }
      }
      
      document.getElementById('shop-form').reset();
      document.getElementById('edit-shop-id').value = "";
      document.getElementById('btn-submit-shop').innerHTML = '<i class="fa-solid fa-store"></i> Register Shop';
      document.getElementById('btn-cancel-shop-edit').style.display = 'none';
      
      refreshAllData();
    } catch (err) {
      console.error('Error registering shop:', err);
      showToast('Backend connection failed', 'error');
    }
  });

  document.getElementById('btn-cancel-shop-edit').addEventListener('click', () => {
    document.getElementById('shop-form').reset();
    document.getElementById('edit-shop-id').value = "";
    document.getElementById('btn-submit-shop').innerHTML = '<i class="fa-solid fa-store"></i> Register Shop';
    document.getElementById('btn-cancel-shop-edit').style.display = 'none';
  });
  
  // 2. Add/Edit Banner Form
  document.getElementById('banner-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const bannerIdVal = document.getElementById('edit-banner-id').value;
    
    const fileInput = document.getElementById('banner-image-file');
    let imageUrl = document.getElementById('banner-image').value.trim();
    
    const hasFile = fileInput && fileInput.files && fileInput.files[0];
    if (!hasFile && !imageUrl) {
      showToast('Please upload a banner image file or provide an image URL', 'error');
      return;
    }
    
    if (hasFile) {
      const file = fileInput.files[0];
      showToast('Uploading banner image...', 'warning');
      try {
        const base64Data = await convertFileToBase64(file);
        const uploadRes = await fetch(`${API_URL}/banners/upload-image`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            base64Image: base64Data.base64,
            mimeType: file.type
          })
        });
        const uploadData = await uploadRes.json();
        if (uploadData.success) {
          imageUrl = uploadData.imageUrl;
          document.getElementById('banner-image').value = imageUrl;
          showToast('Banner image uploaded successfully', 'success');
        } else {
          showToast('Failed to upload banner image: ' + (uploadData.error || 'Unknown error'), 'error');
          return;
        }
      } catch (uploadErr) {
        console.error('Banner image upload failed:', uploadErr);
        showToast('Image upload failed', 'error');
        return;
      }
    }
    
    const bodyData = {
      title: document.getElementById('banner-title').value,
      code: document.getElementById('banner-code').value,
      percent: document.getElementById('banner-percent').value,
      imageUrl: imageUrl,
      redirectUrl: document.getElementById('banner-redirect').value,
      priority: parseInt(document.getElementById('banner-priority').value) || 0,
      expiryDate: document.getElementById('banner-expiry').value
    };
    
    try {
      let res, data;
      if (bannerIdVal) {
        bodyData.id = bannerIdVal;
        res = await fetch(`${API_URL}/banners/update`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(bodyData)
        });
        data = await res.json();
        if (data.success) {
          showToast('Banner details updated', 'success');
          await logAdminActivity('Update Banner', bannerIdVal, `Updated banner: ${bodyData.title}`);
        } else {
          showToast('Failed to update banner: ' + (data.error || 'Unknown error'), 'error');
          return;
        }
      } else {
        res = await fetch(`${API_URL}/banners`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(bodyData)
        });
        data = await res.json();
        if (data.success) {
          showToast('New Carousel Banner added', 'success');
          await logAdminActivity('Create Banner', data.banner.id, `Created banner: ${bodyData.title}`);
        } else {
          showToast('Failed to create banner: ' + (data.error || 'Unknown error'), 'error');
          return;
        }
      }
      
      document.getElementById('banner-modal').classList.remove('active');
      document.getElementById('banner-form').reset();
      
      // Clear file inputs & previews
      const fileInputObj = document.getElementById('banner-image-file');
      if (fileInputObj) fileInputObj.value = '';
      const fileNameSpan = document.getElementById('banner-image-file-name');
      if (fileNameSpan) fileNameSpan.textContent = 'No file chosen';
      const previewImg = document.getElementById('banner-image-preview');
      if (previewImg) previewImg.src = '';
      const previewContainer = document.getElementById('banner-image-preview-container');
      if (previewContainer) previewContainer.style.display = 'none';
      
      refreshAllData();
    } catch (err) {
      console.error('Error saving banner:', err);
      showToast('Failed to save banner', 'error');
    }
  });

  // 3. Add/Edit Offer Form
  document.getElementById('offer-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const mode = document.getElementById('edit-offer-mode').value;
    
    const bodyData = {
      code: document.getElementById('offer-code').value,
      title: document.getElementById('offer-title').value,
      description: document.getElementById('offer-desc').value,
      minOrderAmount: parseFloat(document.getElementById('offer-min-order').value) || 0,
      maxDiscount: parseFloat(document.getElementById('offer-max-discount').value) || 0,
      expiryDate: document.getElementById('offer-expiry').value,
      usageLimit: parseInt(document.getElementById('offer-usage-limit').value) || 1
    };
    
    try {
      let res, data;
      if (mode === 'edit') {
        res = await fetch(`${API_URL}/offers/update`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(bodyData)
        });
        data = await res.json();
        if (data.success) {
          showToast('Coupon details updated', 'success');
          await logAdminActivity('Update Offer', bodyData.code, `Updated coupon: ${bodyData.code}`);
        }
      } else {
        res = await fetch(`${API_URL}/offers`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(bodyData)
        });
        data = await res.json();
        if (data.success) {
          showToast('New Promo Coupon created', 'success');
          await logAdminActivity('Create Offer', bodyData.code, `Created coupon: ${bodyData.code}`);
        }
      }
      
      document.getElementById('offer-modal').classList.remove('active');
      document.getElementById('offer-form').reset();
      refreshAllData();
    } catch (err) {
      console.error('Error saving offer:', err);
      showToast('Failed to save coupon', 'error');
    }
  });

  // 4. Send Broadcast Form
  document.getElementById('broadcast-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const bodyData = {
      title: document.getElementById('alert-title').value,
      body: document.getElementById('alert-body').value,
      icon: document.getElementById('alert-icon').value,
      channel: document.getElementById('alert-channel').value,
      audience: document.getElementById('alert-audience').value
    };
    
    try {
      await fetch(`${API_URL}/notifications/send`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(bodyData)
      });
      document.getElementById('broadcast-form').reset();
      showToast('Broadcast notifications successfully sent!', 'success');
      await logAdminActivity('Broadcast Alert', 'ALL', `Alert: ${bodyData.title}`);
      refreshAllData();
    } catch (err) {
      console.error('Error sending broadcast:', err);
    }
  });

  // 5. Category Creation Form
  const categoryForm = document.getElementById('category-form');
  if (categoryForm) {
    categoryForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      
      const fileInput = document.getElementById('cat-icon-file');
      let iconUrl = document.getElementById('cat-icon-url').value;
      
      // If a new file is chosen, we upload it first
      if (fileInput && fileInput.files && fileInput.files[0]) {
        const file = fileInput.files[0];
        showToast('Uploading category icon...', 'warning');
        try {
          const base64Data = await convertFileToBase64(file);
          const uploadRes = await fetch(`${API_URL}/categories/upload-image`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              base64Image: base64Data.base64,
              mimeType: file.type
            })
          });
          const uploadData = await uploadRes.json();
          if (uploadData.success) {
            iconUrl = uploadData.imageUrl;
            document.getElementById('cat-icon-url').value = iconUrl;
            showToast('Category icon uploaded successfully', 'success');
          } else {
            showToast('Failed to upload category icon: ' + (uploadData.error || 'Unknown error'), 'error');
            return;
          }
        } catch (uploadErr) {
          console.error('Category icon upload failed:', uploadErr);
          showToast('Image upload failed', 'error');
          return;
        }
      }
      
      const isEdit = document.getElementById('cat-id').disabled;
      const bodyData = {
        id: document.getElementById('cat-id').value,
        name: document.getElementById('cat-name').value,
        iconUrl: iconUrl
      };
      const endpoint = isEdit ? `${API_URL}/categories/update` : `${API_URL}/categories/create`;
      try {
        const res = await fetch(endpoint, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(bodyData)
        });
        const data = await res.json();
        if (data.success) {
          showToast(isEdit ? 'Category updated successfully' : 'Category created successfully', 'success');
          await logAdminActivity(isEdit ? 'Update Category' : 'Create Category', bodyData.id, `${isEdit ? 'Updated' : 'Created'} category: ${bodyData.name}`);
          resetCategoryForm();
          loadCategories();
          refreshAllData().then(() => {
            renderShopCategoriesCheckbox();
          });
        } else {
          showToast(data.error || 'Failed to process category request', 'error');
        }
      } catch (err) {
        console.error(err);
      }
    });
  }

  // 6. Wallet Adjustment Form
  const walletForm = document.getElementById('wallet-adjust-form');
  if (walletForm) {
    walletForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      const bodyData = {
        userId: document.getElementById('wallet-user-id').value,
        amount: parseFloat(document.getElementById('wallet-amount').value),
        type: document.getElementById('wallet-type').value,
        title: document.getElementById('wallet-reason').value
      };
      try {
        const res = await fetch(`${API_URL}/users/wallet-adjust`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(bodyData)
        });
        const data = await res.json();
        if (data.success) {
          showToast('Wallet balance adjusted successfully', 'success');
          await logAdminActivity('Adjust Wallet', bodyData.userId, `${bodyData.type} ₹${bodyData.amount} for ${bodyData.title}`);
          document.getElementById('wallet-modal').classList.remove('active');
          loadCustomers();
        }
      } catch (err) {
        console.error(err);
      }
    });
  }

  // 7. Global settings form
  const settingsForm = document.getElementById('settings-form');
  if (settingsForm) {
    settingsForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      const bodyData = {
        taxRate: parseFloat(document.getElementById('set-tax').value),
        commission: parseFloat(document.getElementById('set-commission').value),
        visitingCharges: parseFloat(document.getElementById('set-visiting').value),
        supportNumber: document.getElementById('set-support').value,
        emergencyContact: document.getElementById('set-emergency').value,
        appVersion: document.getElementById('set-version').value,
        terms: document.getElementById('set-terms').value,
        privacy: document.getElementById('set-privacy').value,
        maintenanceMode: document.getElementById('set-maintenance').checked
      };
      try {
        const res = await fetch(`${API_URL}/settings`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(bodyData)
        });
        const data = await res.json();
        if (data.success) {
          showToast('Global settings updated successfully', 'success');
          await logAdminActivity('Update Settings', 'SYSTEM', 'Saved platform variables');
        }
      } catch (err) {
        console.error(err);
      }
    });
  }
}

// Delete Shop partner
async function deleteShop(id) {
  const shop = shops.find(s => s.id === id);
  if (!shop) return;
  if (confirm(`Are you sure you want to delete the shop "${shop.name}"? This action cannot be undone.`)) {
    try {
      const res = await fetch(`${API_URL}/shops/${id}`, { method: 'DELETE' });
      const data = await res.json();
      if (data.success) {
        showToast('Shop deleted successfully', 'success');
        await logAdminActivity('Delete Shop', id, `Deleted shop: ${shop.name}`);
        refreshAllData();
      }
    } catch (e) {
      console.error(e);
    }
  }
}

// Approve / Reject Shop
async function approveShop(id, status) {
  try {
    const res = await fetch(`${API_URL}/shops/approve`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id, verificationStatus: status })
    });
    const data = await res.json();
    if (data.success) {
      showToast(`Shop status updated to: ${status}`, 'success');
      await logAdminActivity('Shop Approval Status', id, `Verification status set to: ${status}`);
      refreshAllData();
    }
  } catch (e) {
    console.error(e);
  }
}

// Suspend Shop
async function suspendShop(id, suspend) {
  try {
    const res = await fetch(`${API_URL}/shops/suspend`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id, suspend })
    });
    const data = await res.json();
    if (data.success) {
      showToast(`Shop suspended state set to: ${suspend}`, 'success');
      await logAdminActivity('Shop Suspend Toggle', id, `Shop suspend state set to: ${suspend}`);
      refreshAllData();
    }
  } catch (e) {
    console.error(e);
  }
}

// Disable Login
async function toggleShopLogin(id, disabled) {
  try {
    const res = await fetch(`${API_URL}/shops/toggle-login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id, loginDisabled: disabled })
    });
    const data = await res.json();
    if (data.success) {
      showToast(`Shop Login Enabled state updated`, 'success');
      await logAdminActivity('Shop Login Toggle', id, `Login disabled set to: ${disabled}`);
      refreshAllData();
    }
  } catch (e) {
    console.error(e);
  }
}

// Reset Shop password
async function resetShopPassword(id) {
  if (confirm('Are you sure you want to reset password and generate new credentials for this provider?')) {
    try {
      const res = await fetch(`${API_URL}/shops/reset-password`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id })
      });
      const data = await res.json();
      if (data.success) {
        showToast('Password credentials generated!', 'success');
        await logAdminActivity('Reset Shop Password', id, 'Regenerated credentials');
        alert(`New Shop Credentials Generated!\n\nShop ID: ${data.shop.shopDisplayId}\nTemporary Password: ${data.tempPassword}\n\nPlease share this immediately with the provider.`);
        refreshAllData();
      }
    } catch (e) {
      console.error(e);
    }
  }
}

// Load shop data into form for editing
function editShop(id) {
  const shop = shops.find(s => s.id === id);
  if (!shop) return;
  
  document.getElementById('edit-shop-id').value = shop.id;
  document.getElementById('shop-name').value = shop.name;
  document.getElementById('owner-name').value = shop.ownerName;
  document.getElementById('shop-phone').value = shop.phone;
  document.getElementById('shop-email').value = shop.email || '';
  document.getElementById('shop-lat').value = shop.latitude;
  document.getElementById('shop-lng').value = shop.longitude;
  document.getElementById('shop-address').value = shop.address || '';
  document.getElementById('shop-radius').value = shop.serviceRadius || 5.0;
  document.getElementById('shop-visiting-charges').value = shop.visitingCharges || 150;
  document.getElementById('shop-timings').value = shop.timings || '09:00 AM - 09:00 PM';
  document.getElementById('shop-verification').value = shop.verificationStatus || 'approved';
  document.getElementById('shop-gst').value = shop.gst || '';
  document.getElementById('shop-pan').value = shop.pan || '';
  document.getElementById('shop-aadhaar').value = shop.aadhaar || '';
  document.getElementById('shop-owner-phone').value = shop.ownerPhone || '';
  document.getElementById('shop-owner-email').value = shop.ownerEmail || '';
  document.getElementById('shop-bank-number').value = shop.bankAccountNumber || '';
  document.getElementById('shop-ifsc').value = shop.ifscCode || '';
  document.getElementById('shop-upi-id').value = shop.upiId || '';
  document.getElementById('shop-commission-rate').value = shop.commissionRate !== undefined ? shop.commissionRate : 15.0;
  document.getElementById('shop-wallet-balance').value = shop.walletBalance !== undefined ? shop.walletBalance : 0.0;
  document.getElementById('shop-docs').value = (shop.verificationDocs || []).join('\n');
  document.getElementById('shop-estimated-time').value = shop.estimatedServiceTime || '20 mins';
  document.getElementById('shop-price-range').value = shop.priceRange || '₹₹';
  document.getElementById('shop-rating').value = (shop.rating || 5.0).toFixed(1);
  document.getElementById('shop-reviews-count').value = shop.reviewsCount || 0;
  
  // Set categories checkboxes
  document.querySelectorAll('input[name="categories"]').forEach(cb => {
    cb.checked = (shop.categories || []).includes(cb.value);
  });
  
  document.getElementById('btn-submit-shop').innerHTML = '<i class="fa-solid fa-save"></i> Save Shop Details';
  document.getElementById('btn-cancel-shop-edit').style.display = 'inline-flex';
  
  showToast('Shop data loaded into form', 'warning');
}

// Toggle Online Status
async function toggleShopOnline(id, nextState) {
  try {
    const res = await fetch(`${API_URL}/shops/update`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id, isOnline: nextState })
    });
    const data = await res.json();
    if (data.success) {
      showToast('Shop Online/Offline status toggled', 'success');
      refreshAllData();
    }
  } catch (e) {
    console.error('Error toggling shop online:', e);
  }
}

// Edit Banner
function editBanner(id) {
  const banner = banners.find(b => b.id === id);
  if (!banner) return;
  
  document.getElementById('banner-modal-title').textContent = "Edit Carousel Banner";
  document.getElementById('edit-banner-id').value = banner.id;
  document.getElementById('banner-title').value = banner.title;
  document.getElementById('banner-code').value = banner.code;
  document.getElementById('banner-percent').value = banner.percent;
  document.getElementById('banner-image').value = banner.imageUrl;
  document.getElementById('banner-redirect').value = banner.redirectUrl || '';
  document.getElementById('banner-priority').value = banner.priority || 0;
  document.getElementById('banner-expiry').value = banner.expiryDate || '';
  
  // Set preview for existing image
  const previewImg = document.getElementById('banner-image-preview');
  const previewContainer = document.getElementById('banner-image-preview-container');
  const fileNameSpan = document.getElementById('banner-image-file-name');
  
  if (banner.imageUrl) {
    previewImg.src = banner.imageUrl;
    previewContainer.style.display = 'flex';
    fileNameSpan.textContent = 'Existing image';
  } else {
    previewImg.src = '';
    previewContainer.style.display = 'none';
    fileNameSpan.textContent = 'No file chosen';
  }
  
  document.getElementById('banner-modal').classList.add('active');
}

// Delete Banner
async function deleteBanner(id) {
  if (confirm('Are you sure you want to delete this banner?')) {
    try {
      const res = await fetch(`${API_URL}/banners/${id}`, { method: 'DELETE' });
      const data = await res.json();
      if (data.success) {
        showToast('Banner removed', 'success');
        await logAdminActivity('Delete Banner', id, 'Deleted banner resource');
        refreshAllData();
      }
    } catch (e) {
      console.error(e);
    }
  }
}

// Edit Coupon code
function editOffer(code) {
  const offer = offers.find(o => o.code === code);
  if (!offer) return;
  
  document.getElementById('offer-modal-title').textContent = "Edit Promo Coupon";
  document.getElementById('edit-offer-mode').value = "edit";
  document.getElementById('offer-code').value = offer.code;
  document.getElementById('offer-code').disabled = true;
  document.getElementById('offer-title').value = offer.title;
  document.getElementById('offer-desc').value = offer.description;
  document.getElementById('offer-min-order').value = offer.minOrderAmount || 0;
  document.getElementById('offer-max-discount').value = offer.maxDiscount || 0;
  document.getElementById('offer-expiry').value = offer.expiryDate || '';
  document.getElementById('offer-usage-limit').value = offer.usageLimit || 1;
  
  document.getElementById('offer-modal').classList.add('active');
}

// Delete Offer
async function deleteOffer(code) {
  if (confirm(`Are you sure you want to delete coupon code "${code}"?`)) {
    try {
      const res = await fetch(`${API_URL}/offers/${code}`, { method: 'DELETE' });
      const data = await res.json();
      if (data.success) {
        showToast('Coupon code deleted', 'success');
        await logAdminActivity('Delete Coupon', code, 'Removed promotional coupon');
        refreshAllData();
      }
    } catch (e) {
      console.error('Error deleting offer:', e);
    }
  }
}

// Render detailed booking management table
function renderManageBookingsTable() {
  const tbody = document.getElementById('manage-bookings-tbody');
  if (!tbody) return;
  const filterVal = document.getElementById('booking-filter-status').value;
  tbody.innerHTML = '';
  
  const filteredBookings = bookings.filter(b => {
    if (filterVal === 'all') return true;
    return b.status === filterVal;
  });
  
  if (filteredBookings.length === 0) {
    tbody.innerHTML = '<tr><td colspan="8" style="text-align:center;color:var(--text-secondary);padding:20px;">No bookings match the filter criteria.</td></tr>';
    return;
  }
  
  filteredBookings.forEach(b => {
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td>${b.id}</td>
      <td>
        <div style="font-weight:600;">${b.customerName}</div>
        <div style="font-size:11px;color:var(--text-muted);">${b.customerPhone} • ${b.customerAddress}</div>
      </td>
      <td>
        <div style="font-weight:600;">${b.providerName}</div>
        <div style="font-size:11px;color:var(--text-muted);">Shop ID: ${b.shopId}</div>
      </td>
      <td style="color:var(--primary-solid);font-weight:600;">₹${b.amount}</td>
      <td>${new Date(b.date).toLocaleDateString('en-GB')} • ${b.slot}</td>
      <td><span class="badge badge-${b.status}">${b.status.replace('_', ' ')}</span></td>
      <td>
        <input type="text" value="${b.providerName}" class="form-group" style="margin-bottom:0; padding:4px 8px; font-size:12px; width:130px;" onchange="updateProviderName('${b.id}', this.value)">
      </td>
      <td>
        <select class="table-action-select" onchange="changeBookingStatus('${b.id}', this.value)">
          <option value="pending" ${b.status === 'pending' ? 'selected' : ''}>Pending</option>
          <option value="accepted" ${b.status === 'accepted' ? 'selected' : ''}>Accept</option>
          <option value="on_the_way" ${b.status === 'on_the_way' ? 'selected' : ''}>On The Way</option>
          <option value="completed" ${b.status === 'completed' ? 'selected' : ''}>Complete</option>
          <option value="cancelled" ${b.status === 'cancelled' ? 'selected' : ''}>Cancel</option>
        </select>
      </td>
    `;
    tbody.appendChild(tr);
  });
}

// Change booking status from dropdown
async function changeBookingStatus(bookingId, newStatus) {
  try {
    let endpoint = `${API_URL}/bookings/update-status`;
    let body = { id: bookingId, status: newStatus };
    if (newStatus === 'cancelled') {
      endpoint = `${API_URL}/bookings/cancel`;
    }
    
    const res = await fetch(endpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    });
    const data = await res.json();
    if (data.success) {
      showToast('Booking status synchronized with database', 'success');
      await logAdminActivity('Update Booking Status', bookingId, `Status updated to ${newStatus}`);
      refreshAllData();
    } else {
      showToast('Failed to update booking status: ' + (data.error || 'Server error'), 'error');
      refreshAllData();
    }
  } catch (e) {
    console.error('Error changing booking status:', e);
    refreshAllData();
  }
}

// Update Provider Name dynamically
async function updateProviderName(bookingId, providerName) {
  try {
    const res = await fetch(`${API_URL}/bookings/update-status`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id: bookingId, status: bookings.find(b => b.id === bookingId).status, providerName })
    });
    const data = await res.json();
    if (data.success) {
      showToast('Provider assigned successfully', 'success');
      await logAdminActivity('Assign Provider', bookingId, `Assigned expert name: ${providerName}`);
      refreshAllData();
    }
  } catch (e) {
    console.error(e);
  }
}

// --- SERVICE MANAGEMENT MODAL LOGIC (PRESERVED) ---
let activeServicesShopId = null;
let tempServicesList = [];

function openServicesModal(shopId) {
  const shop = shops.find(s => s.id === shopId);
  if (!shop) return;
  
  activeServicesShopId = shopId;
  tempServicesList = JSON.parse(JSON.stringify(shop.services || []));
  
  document.getElementById('services-modal-title').textContent = `Manage Services: ${shop.name}`;
  resetServiceForm();
  renderModalServicesList();
  
  document.getElementById('services-modal').classList.add('active');
}

function renderModalServicesList() {
  const container = document.getElementById('modal-services-list');
  if (!container) return;
  container.innerHTML = '';
  
  if (tempServicesList.length === 0) {
    container.innerHTML = '<p style="text-align:center;color:var(--text-secondary);padding:20px;font-size:13px;">No services added yet. Create one on the right!</p>';
    return;
  }
  
  tempServicesList.forEach((srv, idx) => {
    const div = document.createElement('div');
    div.className = 'service-item-row';
    
    const imgUrl = srv.imageUrl || 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=300';
    
    let priceDisplay = '';
    let badgeHtml = '';
    const type = srv.pricingType || 'fixed';
    
    if (type === 'fixed') {
      priceDisplay = `₹${srv.price} <span style="text-decoration:line-through;color:var(--text-secondary);font-size:10px;margin-left:4px;">₹${srv.originalPrice || ''}</span>`;
      badgeHtml = `<span class="badge" style="background-color:rgba(76, 175, 80, 0.15); color:#4CAF50; font-size:10px; padding:2px 6px; border-radius:4px; font-weight:bold; margin-right:6px;">🟢 Fixed Price</span>`;
    } else if (type === 'starting') {
      priceDisplay = `Starting from ₹${srv.price}`;
      badgeHtml = `<span class="badge" style="background-color:rgba(251, 192, 45, 0.15); color:#FBC02D; font-size:10px; padding:2px 6px; border-radius:4px; font-weight:bold; margin-right:6px;">🟡 Starts From</span>`;
    } else if (type === 'range') {
      priceDisplay = `₹${srv.minPrice || 0} - ₹${srv.maxPrice || 0}`;
      badgeHtml = `<span class="badge" style="background-color:rgba(33, 150, 243, 0.15); color:#2196F3; font-size:10px; padding:2px 6px; border-radius:4px; font-weight:bold; margin-right:6px;">🔵 Price Range</span>`;
    } else if (type === 'inspection') {
      priceDisplay = `Price after inspection`;
      badgeHtml = `<span class="badge" style="background-color:rgba(255, 152, 0, 0.15); color:#FF9800; font-size:10px; padding:2px 6px; border-radius:4px; font-weight:bold; margin-right:6px;">🟠 Quote Required</span>`;
    }
    
    div.innerHTML = `
      <img src="${imgUrl}" alt="${srv.title}">
      <div class="service-item-details">
        <h5 style="display:flex; align-items:center; gap:6px; margin:0;">${srv.title}</h5>
        <div style="margin-top: 4px; display: flex; align-items: center; flex-wrap: wrap; gap: 4px;">
          ${badgeHtml}
          <span style="font-size:12px; font-weight:600; color:var(--text-primary);">${priceDisplay}</span>
          <span style="color:var(--text-secondary);font-size:11px;"> • ${srv.durationText}</span>
        </div>
      </div>
      <div class="service-item-actions">
        <button class="btn-icon" type="button" onclick="moveService(${idx}, -1)" title="Move Up" ${idx === 0 ? 'disabled style="opacity:0.3;cursor:not-allowed;"' : ''}>
          <i class="fa-solid fa-arrow-up"></i>
        </button>
        <button class="btn-icon" type="button" onclick="moveService(${idx}, 1)" title="Move Down" ${idx === tempServicesList.length - 1 ? 'disabled style="opacity:0.3;cursor:not-allowed;"' : ''}>
          <i class="fa-solid fa-arrow-down"></i>
        </button>
        <button class="btn-icon" type="button" onclick="loadServiceForEdit('${srv.id}')" title="Edit Service">
          <i class="fa-solid fa-pen-to-square"></i>
        </button>
        <button class="btn-icon btn-delete" type="button" onclick="deleteService('${srv.id}')" title="Delete Service">
          <i class="fa-solid fa-trash-can"></i>
        </button>
      </div>
    `;
    container.appendChild(div);
  });
}

function updatePricingFieldsVisibility(type) {
  const groupFixed = document.getElementById('group-fixed-price');
  const groupOriginal = document.getElementById('group-original-price');
  const groupRange = document.getElementById('group-range-price');
  const lblPrice = document.getElementById('lbl-srv-price');

  if (!groupFixed || !groupRange || !lblPrice) return;

  if (type === 'fixed') {
    groupFixed.style.display = 'flex';
    if (groupOriginal) groupOriginal.style.display = 'block';
    groupRange.style.display = 'none';
    lblPrice.textContent = 'Selling Price (₹)';
  } else if (type === 'starting') {
    groupFixed.style.display = 'flex';
    if (groupOriginal) groupOriginal.style.display = 'block';
    groupRange.style.display = 'none';
    lblPrice.textContent = 'Starting Price (₹)';
  } else if (type === 'range') {
    groupFixed.style.display = 'none';
    groupRange.style.display = 'flex';
  } else if (type === 'inspection') {
    groupFixed.style.display = 'none';
    groupRange.style.display = 'none';
  }
}

function moveService(idx, direction) {
  const targetIdx = idx + direction;
  if (targetIdx < 0 || targetIdx >= tempServicesList.length) return;
  
  const temp = tempServicesList[idx];
  tempServicesList[idx] = tempServicesList[targetIdx];
  tempServicesList[targetIdx] = temp;
  
  renderModalServicesList();
}

function deleteService(srvId) {
  tempServicesList = tempServicesList.filter(s => s.id !== srvId);
  if (document.getElementById('edit-service-id').value === srvId) {
    resetServiceForm();
  }
  renderModalServicesList();
}

function loadServiceForEdit(srvId) {
  const srv = tempServicesList.find(s => s.id === srvId);
  if (!srv) return;
  
  document.getElementById('service-form-title').textContent = "Edit Service";
  document.getElementById('edit-service-id').value = srv.id;
  document.getElementById('srv-title').value = srv.title;
  
  const pricingType = srv.pricingType || 'fixed';
  document.getElementById('srv-pricing-type').value = pricingType;
  document.getElementById('srv-price').value = srv.price || '';
  document.getElementById('srv-original-price').value = srv.originalPrice || '';
  document.getElementById('srv-min-price').value = srv.minPrice || '';
  document.getElementById('srv-max-price').value = srv.maxPrice || '';
  document.getElementById('srv-visiting-charges').value = srv.visitingCharges !== undefined ? srv.visitingCharges : '150';
  document.getElementById('srv-free-inspection').checked = srv.isFreeInspection === true;
  document.getElementById('srv-gst').value = srv.gst !== undefined ? srv.gst : '0';
  document.getElementById('srv-extra-charges').value = srv.extraCharges !== undefined ? srv.extraCharges : '0';
  document.getElementById('srv-extra-charges-label').value = srv.extraChargesLabel || '';
  
  document.getElementById('srv-duration').value = srv.durationText || '1 hr';
  document.getElementById('srv-image').value = srv.imageUrl || '';
  document.getElementById('srv-bullets').value = (srv.bulletPoints || []).join('\n');
  document.getElementById('srv-allow-price-edit').checked = srv.allowPriceEdit !== false;
  document.getElementById('srv-allow-visiting-edit').checked = srv.allowVisitingEdit !== false;
  
  updatePricingFieldsVisibility(pricingType);
  document.getElementById('btn-cancel-edit-service').style.display = 'inline-flex';
}

function resetServiceForm() {
  document.getElementById('service-form-title').textContent = "Add New Service";
  document.getElementById('edit-service-id').value = "";
  document.getElementById('service-edit-form').reset();
  document.getElementById('srv-pricing-type').value = "fixed";
  document.getElementById('srv-allow-price-edit').checked = true;
  document.getElementById('srv-allow-visiting-edit').checked = true;
  updatePricingFieldsVisibility("fixed");
  document.getElementById('btn-cancel-edit-service').style.display = 'none';
}

function setupServicesEvents() {
  document.getElementById('btn-cancel-edit-service').addEventListener('click', resetServiceForm);
  
  document.getElementById('srv-pricing-type').addEventListener('change', (e) => {
    updatePricingFieldsVisibility(e.target.value);
  });
  
  document.getElementById('service-edit-form').addEventListener('submit', (e) => {
    e.preventDefault();
    
    const srvId = document.getElementById('edit-service-id').value;
    const title = document.getElementById('srv-title').value;
    const pricingType = document.getElementById('srv-pricing-type').value;
    const price = parseFloat(document.getElementById('srv-price').value) || 0;
    const originalPrice = parseFloat(document.getElementById('srv-original-price').value) || 0;
    const minPrice = parseFloat(document.getElementById('srv-min-price').value) || 0;
    const maxPrice = parseFloat(document.getElementById('srv-max-price').value) || 0;
    const visitingCharges = parseFloat(document.getElementById('srv-visiting-charges').value) || 0;
    const isFreeInspection = document.getElementById('srv-free-inspection').checked;
    const gst = parseFloat(document.getElementById('srv-gst').value) || 0;
    const extraCharges = parseFloat(document.getElementById('srv-extra-charges').value) || 0;
    const extraChargesLabel = document.getElementById('srv-extra-charges-label').value;
    
    const durationText = document.getElementById('srv-duration').value;
    const imageUrl = document.getElementById('srv-image').value || 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=300';
    const allowPriceEdit = document.getElementById('srv-allow-price-edit').checked;
    const allowVisitingEdit = document.getElementById('srv-allow-visiting-edit').checked;
    
    const bulletsRaw = document.getElementById('srv-bullets').value;
    const bulletPoints = bulletsRaw.split('\n').map(b => b.trim()).filter(b => b.length > 0);
    
    const servicePayload = {
      title,
      price: (pricingType === 'fixed' || pricingType === 'starting') ? price : 0,
      originalPrice: (pricingType === 'fixed' || pricingType === 'starting') ? originalPrice : 0,
      pricingType,
      minPrice: pricingType === 'range' ? minPrice : 0,
      maxPrice: pricingType === 'range' ? maxPrice : 0,
      visitingCharges,
      isFreeInspection,
      gst,
      extraCharges,
      extraChargesLabel,
      durationText,
      imageUrl,
      bulletPoints,
      allowPriceEdit,
      allowVisitingEdit
    };
    
    if (srvId) {
      const idx = tempServicesList.findIndex(s => s.id === srvId);
      if (idx !== -1) {
        tempServicesList[idx] = {
          ...tempServicesList[idx],
          ...servicePayload
        };
      }
    } else {
      const newSrv = {
        id: `srv-${Date.now()}`,
        rating: 5.0,
        reviewsCount: 0,
        ...servicePayload
      };
      tempServicesList.push(newSrv);
    }
    
    resetServiceForm();
    renderModalServicesList();
  });
  
  document.getElementById('btn-submit-all-services').addEventListener('click', async () => {
    if (!activeServicesShopId) return;
    
    try {
      const res = await fetch(`${API_URL}/shops/update`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          id: activeServicesShopId,
          services: tempServicesList
        })
      });
      const data = await res.json();
      if (data.success) {
        showToast('Shop services updated successfully!', 'success');
        await logAdminActivity('Modify Shop Services', activeServicesShopId, `Updated services catalog`);
        document.getElementById('services-modal').classList.remove('active');
        refreshAllData();
      } else {
        showToast('Failed to save shop services: ' + (data.error || 'Server error'), 'error');
      }
    } catch (e) {
      console.error('Error saving services:', e);
      showToast('Network error while saving services', 'error');
    }
  });
}

// Load customer directory from backend
async function loadCustomers() {
  const tbody = document.getElementById('customers-tbody');
  if (!tbody) return;
  tbody.innerHTML = '<tr><td colspan="9" style="text-align:center;color:var(--text-muted);"><i class="fa-solid fa-spinner fa-spin"></i> Loading...</td></tr>';
  
  try {
    const res = await fetch(`${API_URL}/users`);
    users = await res.json();
    
    tbody.innerHTML = '';
    if (users.length === 0) {
      tbody.innerHTML = '<tr><td colspan="9" style="text-align:center;">No users registered yet.</td></tr>';
      return;
    }
    
    users.forEach(u => {
      const isBlocked = u.accountStatus === 'inactive';
      const toggleBtnText = isBlocked ? 'Unblock' : 'Block';
      const statusBadge = isBlocked ? '<span class="badge badge-suspended">Blocked</span>' : '<span class="badge badge-active">Active</span>';
      
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td>${u.id || u._id}</td>
        <td><strong>${u.name || 'N/A'}</strong></td>
        <td>${u.phone}</td>
        <td>${u.email || 'N/A'}</td>
        <td style="color:var(--success); font-weight:600;">₹${u.walletBalance || 0}</td>
        <td><span style="text-transform:capitalize;">${u.membership || 'basic'}</span></td>
        <td>${new Date(u.memberSince || u.createdAt || Date.now()).toLocaleDateString()}</td>
        <td>${statusBadge}</td>
        <td>
          <button class="btn btn-secondary btn-sm" onclick="triggerWalletAdjustment('${u.id || u._id}', '${u.name || u.phone}')"><i class="fa-solid fa-wallet"></i> Adjust Escrow</button>
          <button class="btn ${isBlocked ? 'btn-primary' : 'btn-danger'} btn-sm" onclick="toggleUserBlock('${u.id || u._id}')">${toggleBtnText}</button>
        </td>
      `;
      tbody.appendChild(tr);
    });
  } catch (e) {
    console.error(e);
  }
}

// Trigger Wallet Adjust modal
function triggerWalletAdjustment(userId, username) {
  document.getElementById('wallet-user-id').value = userId;
  document.getElementById('wallet-username').value = username;
  document.getElementById('wallet-amount').value = '';
  document.getElementById('wallet-reason').value = '';
  document.getElementById('wallet-modal').classList.add('active');
}

// Block/Unblock user
async function toggleUserBlock(userId) {
  try {
    const res = await fetch(`${API_URL}/users/toggle-status`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ userId })
    });
    const data = await res.json();
    if (data.success) {
      showToast(`User status updated to: ${data.status}`, 'success');
      await logAdminActivity('Toggle User Ban', userId, `User state updated to: ${data.status}`);
      loadCustomers();
    }
  } catch (e) {
    console.error(e);
  }
}

// Load operational Settings variables
async function loadSettings() {
  try {
    const res = await fetch(`${API_URL}/settings`);
    settings = await res.json();
    
    document.getElementById('set-tax').value = settings.taxRate || 5.0;
    document.getElementById('set-commission').value = settings.commission || 10.0;
    document.getElementById('set-visiting').value = settings.visitingCharges || 150;
    document.getElementById('set-support').value = settings.supportNumber || '';
    document.getElementById('set-emergency').value = settings.emergencyContact || '';
    document.getElementById('set-version').value = settings.appVersion || '1.0.0';
    document.getElementById('set-terms').value = settings.terms || '';
    document.getElementById('set-privacy').value = settings.privacy || '';
    document.getElementById('set-maintenance').checked = settings.maintenanceMode || false;
  } catch (e) {
    console.error(e);
  }
}

// Load operational categories
async function loadCategories() {
  const container = document.getElementById('categories-list');
  if (!container) return;
  container.innerHTML = '<p style="grid-column:1/-1;text-align:center;">Loading Categories...</p>';
  
  try {
    const res = await fetch(`${API_URL}/categories`);
    categories = await res.json();
    
    container.innerHTML = '';
    if (categories.length === 0) {
      container.innerHTML = '<p style="grid-column:1/-1;text-align:center;">No active categories available.</p>';
      return;
    }
    
    categories.forEach(c => {
      const div = document.createElement('div');
      div.className = 'category-badge-item';
      div.style = "display: flex; align-items: center; justify-content: space-between; gap: 10px;";
      
      const imgHtml = c.iconUrl ? `<img src="${c.iconUrl}" alt="${c.name}" style="width: 24px; height: 24px; object-fit: contain; border-radius: 4px;">` : `<i class="fa-solid fa-folder" style="font-size: 18px; color: var(--primary-solid);"></i>`;
      
      div.innerHTML = `
        <div style="display: flex; align-items: center; gap: 10px;">
          ${imgHtml}
          <h4>${c.name} <span style="font-size: 10px; color: var(--text-muted);">(${c.id})</span></h4>
        </div>
        <div style="display: flex; gap: 5px;">
          <button class="btn btn-icon" onclick="editCategory('${c.id}', '${c.name.replace(/'/g, "\\'")}', '${(c.iconUrl || '').replace(/'/g, "\\'")}')" title="Edit Category"><i class="fa-solid fa-pen-to-square"></i></button>
          <button class="btn btn-icon btn-delete" onclick="deleteCategory('${c.id}')" title="Delete Category"><i class="fa-solid fa-trash-can"></i></button>
        </div>
      `;
      container.appendChild(div);
    });
  } catch (e) {
    console.error(e);
  }
}

// Edit Category helper function
function editCategory(id, name, iconUrl) {
  document.getElementById('cat-id').value = id;
  document.getElementById('cat-id').disabled = true;
  document.getElementById('cat-name').value = name;
  document.getElementById('cat-icon-url').value = iconUrl;
  
  const previewImg = document.getElementById('cat-icon-preview');
  const previewContainer = document.getElementById('cat-icon-preview-container');
  const fileNameSpan = document.getElementById('cat-icon-file-name');
  
  if (iconUrl) {
    previewImg.src = iconUrl;
    previewContainer.style.display = 'flex';
    fileNameSpan.textContent = 'Existing image';
  } else {
    previewImg.src = '';
    previewContainer.style.display = 'none';
    fileNameSpan.textContent = 'No file chosen';
  }
  
  const formHeader = document.querySelector('#categories-tab .form-card h2');
  if (formHeader) formHeader.innerHTML = '<i class="fa-solid fa-pen-to-square"></i> Edit Service Category';
  
  const submitBtn = document.querySelector('#category-form button[type="submit"]');
  if (submitBtn) submitBtn.innerHTML = '<i class="fa-solid fa-floppy-disk"></i> Update Category';
  
  let cancelBtn = document.getElementById('btn-cancel-category-edit');
  if (!cancelBtn && submitBtn) {
    cancelBtn = document.createElement('button');
    cancelBtn.type = 'button';
    cancelBtn.id = 'btn-cancel-category-edit';
    cancelBtn.className = 'btn btn-secondary';
    cancelBtn.style.marginLeft = '8px';
    cancelBtn.innerHTML = 'Cancel';
    cancelBtn.addEventListener('click', resetCategoryForm);
    submitBtn.parentNode.appendChild(cancelBtn);
  }
}

// Reset Category Form helper function
function resetCategoryForm() {
  document.getElementById('category-form').reset();
  document.getElementById('cat-id').disabled = false;
  
  const fileInput = document.getElementById('cat-icon-file');
  if (fileInput) fileInput.value = '';
  const fileNameSpan = document.getElementById('cat-icon-file-name');
  if (fileNameSpan) fileNameSpan.textContent = 'No file chosen';
  const previewImg = document.getElementById('cat-icon-preview');
  if (previewImg) previewImg.src = '';
  const previewContainer = document.getElementById('cat-icon-preview-container');
  if (previewContainer) previewContainer.style.display = 'none';
  const iconUrlInput = document.getElementById('cat-icon-url');
  if (iconUrlInput) iconUrlInput.value = '';
  
  const formHeader = document.querySelector('#categories-tab .form-card h2');
  if (formHeader) formHeader.innerHTML = '<i class="fa-solid fa-square-plus"></i> Create Service Category';
  
  const submitBtn = document.querySelector('#category-form button[type="submit"]');
  if (submitBtn) submitBtn.innerHTML = '<i class="fa-solid fa-check"></i> Add Category';
  
  const cancelBtn = document.getElementById('btn-cancel-category-edit');
  if (cancelBtn) cancelBtn.remove();
}

function convertFileToBase64(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.readAsDataURL(file);
    reader.onload = () => {
      const base64String = reader.result.split(',')[1];
      resolve({ base64: base64String });
    };
    reader.onerror = error => reject(error);
  });
}

function setupCategoryImageUpload() {
  const fileInput = document.getElementById('cat-icon-file');
  if (fileInput) {
    fileInput.addEventListener('change', (e) => {
      const file = e.target.files[0];
      const previewImg = document.getElementById('cat-icon-preview');
      const previewContainer = document.getElementById('cat-icon-preview-container');
      const fileNameSpan = document.getElementById('cat-icon-file-name');
      
      if (file) {
        fileNameSpan.textContent = file.name;
        previewImg.src = URL.createObjectURL(file);
        previewContainer.style.display = 'flex';
      } else {
        if (!document.getElementById('cat-icon-url').value) {
          fileNameSpan.textContent = 'No file chosen';
          previewImg.src = '';
          previewContainer.style.display = 'none';
        }
      }
    });
  }

  const removeBtn = document.getElementById('btn-remove-cat-icon');
  if (removeBtn) {
    removeBtn.addEventListener('click', () => {
      const fileInput = document.getElementById('cat-icon-file');
      if (fileInput) fileInput.value = '';
      document.getElementById('cat-icon-file-name').textContent = 'No file chosen';
      document.getElementById('cat-icon-preview').src = '';
      document.getElementById('cat-icon-preview-container').style.display = 'none';
      document.getElementById('cat-icon-url').value = '';
    });
  }
}

function setupBannerImageUpload() {
  const fileInput = document.getElementById('banner-image-file');
  if (fileInput) {
    fileInput.addEventListener('change', (e) => {
      const file = e.target.files[0];
      const previewImg = document.getElementById('banner-image-preview');
      const previewContainer = document.getElementById('banner-image-preview-container');
      const fileNameSpan = document.getElementById('banner-image-file-name');
      
      if (file) {
        fileNameSpan.textContent = file.name;
        previewImg.src = URL.createObjectURL(file);
        previewContainer.style.display = 'flex';
      } else {
        if (!document.getElementById('banner-image').value) {
          fileNameSpan.textContent = 'No file chosen';
          previewImg.src = '';
          previewContainer.style.display = 'none';
        }
      }
    });
  }

  const removeBtn = document.getElementById('btn-remove-banner-image');
  if (removeBtn) {
    removeBtn.addEventListener('click', () => {
      const fileInput = document.getElementById('banner-image-file');
      if (fileInput) fileInput.value = '';
      document.getElementById('banner-image-file-name').textContent = 'No file chosen';
      document.getElementById('banner-image-preview').src = '';
      document.getElementById('banner-image-preview-container').style.display = 'none';
      document.getElementById('banner-image').value = '';
    });
  }
}

// Delete category
async function deleteCategory(id) {
  if (confirm('Are you sure you want to delete this category? All service items under this label will remain active but category filters will break.')) {
    try {
      const res = await fetch(`${API_URL}/categories/${id}`, { method: 'DELETE' });
      const data = await res.json();
      if (data.success) {
        showToast('Category deleted successfully', 'success');
        await logAdminActivity('Delete Category', id, 'Removed service category tag');
        loadCategories();
        refreshAllData().then(() => {
          renderShopCategoriesCheckbox();
        });
      }
    } catch (e) {
      console.error(e);
    }
  }
}

// Load financial stats page
function loadPaymentStats() {
  const payComm = document.getElementById('pay-platform-comm');
  const payDue = document.getElementById('pay-provider-due');
  const txTbody = document.getElementById('wallet-tx-tbody');
  const setTbody = document.getElementById('settlement-tbody');
  
  if (!payComm) return;
  
  let platformCommission = 0;
  let settlementsDue = 0;
  
  // Clean tx list
  txTbody.innerHTML = '';
  setTbody.innerHTML = '';
  
  // Calculate commission & settlements per shop
  const shopSettlementMap = {};
  shops.forEach(s => {
    shopSettlementMap[s.id] = {
      name: s.name,
      phone: s.phone,
      visiting: s.visitingCharges || 150,
      bookingsCount: 0,
      grossAmount: 0
    };
  });
  
  bookings.forEach(b => {
    if (b.status === 'completed') {
      const commRate = (shops.find(s => s.id === b.shopId)?.commissionRate || 20) / 100;
      const comm = b.amount * commRate;
      platformCommission += comm;
      settlementsDue += (b.amount - comm);
      
      if (shopSettlementMap[b.shopId]) {
        shopSettlementMap[b.shopId].bookingsCount += 1;
        shopSettlementMap[b.shopId].grossAmount += b.amount;
      }
    }
  });
  
  payComm.textContent = `₹${platformCommission.toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2})}`;
  payDue.textContent = `₹${settlementsDue.toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2})}`;
  
  // Populate settlements table
  Object.entries(shopSettlementMap).forEach(([shopId, s]) => {
    if (s.bookingsCount > 0) {
      const shop = shops.find(sh => sh.id === shopId);
      const commRate = (shop?.commissionRate || 20) / 100;
      const earned = s.grossAmount * (1 - commRate);
      const commission = s.grossAmount * commRate;
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td>${shopId}</td>
        <td><strong>${s.name}</strong></td>
        <td>${s.phone}</td>
        <td>₹${s.visiting}</td>
        <td>${s.bookingsCount} Completed</td>
        <td style="font-weight:600;">₹${s.grossAmount.toFixed(2)}</td>
        <td style="color:var(--success); font-weight:600;">₹${earned.toFixed(2)}</td>
        <td style="color:var(--warning); font-weight:600;">₹${commission.toFixed(2)}</td>
      `;
      setTbody.appendChild(tr);
    }
  });

  if (setTbody.innerHTML === '') {
    setTbody.innerHTML = '<tr><td colspan="8" style="text-align:center;color:var(--text-secondary);">No completed shop bookings yet for settlement.</td></tr>';
  }

  // Populate recent transaction logs
  let txIndex = 0;
  users.forEach(u => {
    if (u.walletTransactions && u.walletTransactions.length > 0) {
      u.walletTransactions.forEach(t => {
        txIndex++;
        const tr = document.createElement('tr');
        const badgeClass = t.type === 'credit' ? 'badge-completed' : 'badge-cancelled';
        tr.innerHTML = `
          <td>${t.id || 'TX-'+txIndex}</td>
          <td>${u.name || u.phone}</td>
          <td style="font-weight:600;">₹${t.amount}</td>
          <td><span class="badge ${badgeClass}">${t.type}</span></td>
          <td>${t.title || 'Escrow adjustment'}</td>
        `;
        txTbody.appendChild(tr);
      });
    }
  });

  if (txTbody.innerHTML === '') {
    txTbody.innerHTML = '<tr><td colspan="5" style="text-align:center;color:var(--text-secondary);">No escrow transactions log found.</td></tr>';
  }

  // Also load the new enterprise payment dashboard
  refreshPaymentDashboard();
}

// ============================================================
// ENTERPRISE PAYMENT ACCOUNTING CONSOLE - FUNCTIONS
// ============================================================

function switchPaySubtab(btn) {
  document.querySelectorAll('.pay-subtab').forEach(b => {
    b.classList.remove('active');
    b.classList.add('btn-secondary');
    b.classList.remove('btn-primary');
  });
  btn.classList.add('active', 'btn-primary');
  btn.classList.remove('btn-secondary');

  const paneId = btn.getAttribute('data-pay-tab');
  document.querySelectorAll('.pay-pane').forEach(p => p.style.display = 'none');
  const pane = document.getElementById(paneId);
  if (pane) pane.style.display = 'block';

  // Load data for the activated pane
  if (paneId === 'pay-overview-pane') refreshPaymentDashboard();
  if (paneId === 'pay-ledger-pane') loadLedgerTable();
  if (paneId === 'pay-queue-pane') loadSettlementQueue();
  if (paneId === 'pay-history-pane') loadSettlementHistory();
  if (paneId === 'pay-commission-pane') { loadCommissionConfig(); loadCommissionReport(); populateCommissionShopDropdowns(); }
  if (paneId === 'pay-audit-pane') loadPaymentAuditLog();
}

async function refreshPaymentDashboard() {
  try {
    const res = await fetch(`${API_URL}/payments/dashboard/admin`);
    const data = await res.json();
    if (!data.today) return;

    // Update KPI cards
    document.getElementById('pay-kpi-today-gross').textContent = `₹${(data.today.grossRevenue || 0).toFixed(2)}`;
    document.getElementById('pay-kpi-today-comm').textContent = `₹${(data.today.commissionEarned || 0).toFixed(2)}`;
    document.getElementById('pay-kpi-total-comm').textContent = `₹${(data.overall.totalCommissionEarned || 0).toFixed(2)}`;
    document.getElementById('pay-kpi-outstanding-comm').textContent = `₹${(data.overall.outstandingCommission || 0).toFixed(2)}`;
    document.getElementById('pay-kpi-pending-set').textContent = `₹${(data.settlements.pendingAmount || 0).toFixed(2)}`;
    document.getElementById('pay-kpi-total-settled').textContent = `₹${(data.settlements.totalSettled || 0).toFixed(2)}`;

    // Update top bar commission stats
    const globalRateEl = document.getElementById('pay-global-rate');
    if (globalRateEl) globalRateEl.textContent = 'Per-Shop Config';
    const outstandingEl = document.getElementById('pay-outstanding-comm');
    if (outstandingEl) outstandingEl.textContent = `₹${(data.overall.outstandingCommission || 0).toFixed(2)}`;
    const platformCommEl = document.getElementById('pay-platform-comm');
    if (platformCommEl) platformCommEl.textContent = `₹${(data.overall.totalCommissionEarned || 0).toFixed(2)}`;
    const providerDueEl = document.getElementById('pay-provider-due');
    if (providerDueEl) providerDueEl.textContent = `₹${(data.overall.totalProviderEarnings || 0).toFixed(2)}`;

    // Settlement badge
    const badge = document.getElementById('pay-queue-badge');
    if (badge) {
      if ((data.settlements.pendingCount || 0) > 0) {
        badge.textContent = data.settlements.pendingCount;
        badge.style.display = 'inline';
      } else {
        badge.style.display = 'none';
      }
    }

    // Overview pane sections
    const methodSplit = document.getElementById('pay-method-split');
    if (methodSplit) {
      const total = (data.overall.totalGrossRevenue || 0);
      const cash = (data.overall.cashCollection || 0);
      const online = (data.overall.onlineCollection || 0);
      methodSplit.innerHTML = `
        <div class="set-row"><span>💵 Cash Payments</span><strong style="color:var(--warning);">₹${cash.toFixed(2)}</strong></div>
        <div class="set-row"><span>💳 Online Payments</span><strong style="color:var(--success);">₹${online.toFixed(2)}</strong></div>
        <div class="set-row"><span>📊 Total Gross Volume</span><strong>₹${total.toFixed(2)}</strong></div>
      `;
    }

    const commStatus = document.getElementById('pay-commission-status');
    if (commStatus) {
      const totalComm = (data.overall.totalCommissionEarned || 0);
      const outstanding = (data.overall.outstandingCommission || 0);
      const collected = totalComm - outstanding;
      commStatus.innerHTML = `
        <div class="set-row"><span>✅ Commission Collected</span><strong style="color:var(--success);">₹${collected.toFixed(2)}</strong></div>
        <div class="set-row"><span>⚠️ Outstanding (Cash)</span><strong style="color:var(--warning);">₹${outstanding.toFixed(2)}</strong></div>
        <div class="set-row"><span>📊 Total Commission</span><strong>₹${totalComm.toFixed(2)}</strong></div>
      `;
    }

    const settleOverview = document.getElementById('pay-settlement-overview');
    if (settleOverview) {
      settleOverview.innerHTML = `
        <div class="set-row"><span>⏳ Pending Requests</span><strong style="color:var(--warning);">${data.settlements.pendingCount || 0} (₹${(data.settlements.pendingAmount || 0).toFixed(2)})</strong></div>
        <div class="set-row"><span>✅ Completed</span><strong style="color:var(--success);">${data.settlements.completedCount || 0}</strong></div>
        <div class="set-row"><span>💸 Total Settled</span><strong>₹${(data.settlements.totalSettled || 0).toFixed(2)}</strong></div>
      `;
    }

    // Provider wallets table
    const walletsTbody = document.getElementById('pay-provider-wallets-tbody');
    if (walletsTbody && data.providerWallets) {
      walletsTbody.innerHTML = '';
      data.providerWallets.forEach(p => {
        const isNegative = p.walletBalance < 0;
        const tr = document.createElement('tr');
        tr.innerHTML = `
          <td><strong>${p.shopName}</strong></td>
          <td style="font-size:11px;color:var(--text-muted);">${p.shopId}</td>
          <td>${p.commissionRate}%</td>
          <td style="font-weight:700; color: ${isNegative ? 'var(--danger)' : 'var(--success)'};">₹${p.walletBalance.toFixed(2)}${isNegative ? ' ⚠️' : ''}</td>
          <td>${isNegative ? '<span class="badge badge-cancelled">Commission Due</span>' : '<span class="badge badge-completed">OK</span>'}</td>
        `;
        walletsTbody.appendChild(tr);
      });
      if (data.providerWallets.length === 0) {
        walletsTbody.innerHTML = '<tr><td colspan="5" style="text-align:center;color:var(--text-muted);">No providers registered</td></tr>';
      }
    }

  } catch (e) {
    console.error('Payment dashboard error:', e);
  }
}

async function loadLedgerTable() {
  const tbody = document.getElementById('pay-ledger-tbody');
  if (!tbody) return;
  tbody.innerHTML = '<tr><td colspan="11" style="text-align:center;padding:40px;color:var(--text-muted);">Loading...</td></tr>';

  // Populate shop filter dropdown
  const shopSelect = document.getElementById('ledger-filter-shop');
  if (shopSelect && shopSelect.options.length <= 1) {
    shops.forEach(s => {
      const opt = document.createElement('option');
      opt.value = s.id;
      opt.textContent = s.name;
      shopSelect.appendChild(opt);
    });
  }

  const method = document.getElementById('ledger-filter-method')?.value || '';
  const status = document.getElementById('ledger-filter-status')?.value || '';
  const shopId = document.getElementById('ledger-filter-shop')?.value || '';

  let url = `${API_URL}/payments/ledger?`;
  if (method) url += `paymentMethod=${method}&`;
  if (status) url += `paymentStatus=${status}&`;
  if (shopId) url += `shopId=${shopId}&`;

  try {
    const res = await fetch(url);
    const data = await res.json();
    const ledgers = data.ledgers || [];

    tbody.innerHTML = '';
    if (ledgers.length === 0) {
      tbody.innerHTML = '<tr><td colspan="11" style="text-align:center;padding:40px;color:var(--text-muted);">No ledger entries found. Ledger entries are created automatically when bookings are placed.</td></tr>';
      return;
    }

    ledgers.forEach(l => {
      const tr = document.createElement('tr');
      const payBadge = renderPayStatusBadge(l.paymentStatus);
      const commBadge = renderCommStatusBadge(l.commissionStatus);
      const methBadge = renderMethodBadge(l.paymentMethod);
      tr.innerHTML = `
        <td style="font-size:11px;font-family:monospace;">${l.bookingId}</td>
        <td style="font-size:11px;">${l.customerName || '—'}</td>
        <td style="font-size:11px;">${l.providerName || '—'}</td>
        <td style="font-weight:700;color:var(--primary-solid);">₹${(l.grossAmount || 0).toFixed(2)}</td>
        <td style="font-weight:600;color:var(--warning);">₹${(l.commissionAmount || 0).toFixed(2)} <span style="font-size:9px;color:var(--text-muted);">(${l.commissionRate || 20}%)</span></td>
        <td style="font-weight:600;color:var(--success);">₹${(l.providerEarnings || 0).toFixed(2)}</td>
        <td>${methBadge}</td>
        <td>${payBadge}</td>
        <td>${commBadge}</td>
        <td style="font-size:11px;">${l.createdAt ? new Date(l.createdAt).toLocaleString('en-IN', {dateStyle:'short',timeStyle:'short'}) : '—'}</td>
        <td>
          ${l.paymentMethod === 'cash' && l.commissionStatus === 'pending' ?
            `<button class="btn btn-primary btn-sm" style="font-size:10px;padding:3px 8px;" onclick="collectCommissionForBooking('${l.shopId}', '${l.bookingId}', ${l.commissionAmount})">Collect Comm</button>` : ''}
        </td>
      `;
      tbody.appendChild(tr);
    });
  } catch (e) {
    console.error('Ledger load error:', e);
    tbody.innerHTML = '<tr><td colspan="11" style="text-align:center;padding:40px;color:var(--danger);">Failed to load ledger data.</td></tr>';
  }
}

async function loadSettlementQueue() {
  const listEl = document.getElementById('pay-queue-list');
  const emptyEl = document.getElementById('pay-queue-empty');
  if (!listEl) return;
  listEl.innerHTML = '<p style="color:var(--text-muted);text-align:center;padding:40px;">Loading...</p>';

  try {
    const res = await fetch(`${API_URL}/payments/settlements?status=pending`);
    const data = await res.json();
    const settlements = data.settlements || [];

    listEl.innerHTML = '';
    if (settlements.length === 0) {
      if (emptyEl) emptyEl.style.display = 'block';
      return;
    }
    if (emptyEl) emptyEl.style.display = 'none';

    settlements.forEach(s => {
      const card = document.createElement('div');
      card.style.cssText = 'border: 1px solid var(--border); border-radius: 12px; padding: 20px; margin-bottom: 16px; background: var(--card-bg);';
      card.innerHTML = `
        <div style="display:flex; justify-content:space-between; align-items:flex-start; flex-wrap:wrap; gap:12px;">
          <div>
            <h4 style="margin:0;display:flex;align-items:center;gap:8px;">${s.providerName || s.shopId} <span class="badge badge-pending" style="font-size:10px;">Pending</span></h4>
            <p style="font-size:12px;color:var(--text-muted);margin:4px 0;">Settlement ID: <strong>${s.id}</strong></p>
            <p style="font-size:12px;color:var(--text-muted);margin:4px 0;">Bank: ${s.bankAccount ? '****' + s.bankAccount.slice(-4) : 'N/A'} | IFSC: ${s.ifscCode || 'N/A'} | UPI: ${s.upiId || 'N/A'}</p>
            <p style="font-size:12px;color:var(--text-muted);">Requested: ${s.requestedAt ? new Date(s.requestedAt).toLocaleString('en-IN') : '—'}</p>
          </div>
          <div style="text-align:right;">
            <p style="font-size:28px;font-weight:800;color:var(--primary-solid);margin:0;">₹${(s.amount || 0).toFixed(2)}</p>
            <p style="font-size:11px;color:var(--text-muted);">Requested Amount</p>
          </div>
        </div>
        <div style="display:flex; gap:10px; margin-top:16px; flex-wrap:wrap;">
          <button class="btn btn-primary btn-sm" onclick="approveSettlement('${s.id}')"><i class="fa-solid fa-check"></i> Approve</button>
          <button class="btn btn-secondary btn-sm" onclick="completeSettlement('${s.id}')"><i class="fa-solid fa-money-bill-transfer"></i> Mark Completed</button>
          <button class="btn btn-danger btn-sm" onclick="rejectSettlement('${s.id}')"><i class="fa-solid fa-xmark"></i> Reject</button>
        </div>
      `;
      listEl.appendChild(card);
    });
  } catch (e) {
    console.error('Settlement queue error:', e);
    listEl.innerHTML = '<p style="color:var(--danger);text-align:center;">Failed to load settlement queue.</p>';
  }
}

async function loadSettlementHistory() {
  const tbody = document.getElementById('pay-history-tbody');
  if (!tbody) return;
  tbody.innerHTML = '<tr><td colspan="9" style="text-align:center;padding:40px;color:var(--text-muted);">Loading...</td></tr>';

  try {
    const res = await fetch(`${API_URL}/payments/settlements`);
    const data = await res.json();
    const settlements = (data.settlements || []).filter(s => s.status !== 'pending');

    tbody.innerHTML = '';
    if (settlements.length === 0) {
      tbody.innerHTML = '<tr><td colspan="9" style="text-align:center;padding:40px;color:var(--text-muted);">No settlement history yet.</td></tr>';
      return;
    }

    settlements.forEach(s => {
      const statusColors = { approved: 'var(--primary-solid)', completed: 'var(--success)', failed: 'var(--danger)', rejected: 'var(--danger)', processing: 'var(--warning)' };
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td style="font-size:11px;font-family:monospace;">${s.id}</td>
        <td><strong>${s.providerName || s.shopId}</strong></td>
        <td style="font-weight:700;color:var(--primary-solid);">₹${(s.amount || 0).toFixed(2)}</td>
        <td><span style="color:${statusColors[s.status] || 'var(--text-primary)'};font-weight:600;">${s.status.toUpperCase()}</span></td>
        <td style="font-size:11px;">${s.bankAccount ? '****' + s.bankAccount.slice(-4) + (s.ifscCode ? ' | ' + s.ifscCode : '') : (s.upiId || 'N/A')}</td>
        <td style="font-size:11px;font-family:monospace;">${s.transactionId || '—'}</td>
        <td style="font-size:11px;">${s.requestedAt ? new Date(s.requestedAt).toLocaleDateString('en-IN') : '—'}</td>
        <td style="font-size:11px;">${s.completedAt ? new Date(s.completedAt).toLocaleDateString('en-IN') : '—'}</td>
        <td style="font-size:11px;color:var(--text-muted);">${s.adminNote || '—'}</td>
      `;
      tbody.appendChild(tr);
    });
  } catch (e) {
    console.error('Settlement history error:', e);
    tbody.innerHTML = '<tr><td colspan="9" style="text-align:center;color:var(--danger);">Failed to load settlement history.</td></tr>';
  }
}

async function approveSettlement(id) {
  const note = prompt('Admin note for approval (optional):') || '';
  try {
    const res = await fetch(`${API_URL}/payments/settlements/${id}/approve`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ adminNote: note })
    });
    const data = await res.json();
    if (data.success) {
      showToast('Settlement approved! Provider has been notified.', 'success');
      await logAdminActivity('Approve Settlement', id, `Settlement ${id} approved`);
      loadSettlementQueue();
      loadSettlementHistory();
    } else {
      showToast(data.error || 'Failed to approve settlement', 'error');
    }
  } catch (e) {
    showToast('Failed to approve settlement', 'error');
  }
}

async function completeSettlement(id) {
  const txnId = prompt('Enter bank transaction ID (required to mark as completed):');
  if (!txnId) { showToast('Transaction ID is required to mark as completed', 'warning'); return; }
  const note = prompt('Admin note (optional):') || '';
  try {
    const res = await fetch(`${API_URL}/payments/settlements/${id}/complete`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ transactionId: txnId, adminNote: note })
    });
    const data = await res.json();
    if (data.success) {
      showToast(`Settlement completed! TxnID: ${txnId}`, 'success');
      await logAdminActivity('Complete Settlement', id, `Settlement ${id} completed. TxnID: ${txnId}`);
      loadSettlementQueue();
      loadSettlementHistory();
      refreshAllData();
    } else {
      showToast(data.error || 'Failed to complete settlement', 'error');
    }
  } catch (e) {
    showToast('Failed to complete settlement', 'error');
  }
}

async function rejectSettlement(id) {
  const reason = prompt('Reason for rejection (required):');
  if (!reason) { showToast('Rejection reason is required', 'warning'); return; }
  if (!confirm(`Reject this settlement request? Reason: "${reason}"`)) return;
  try {
    const res = await fetch(`${API_URL}/payments/settlements/${id}/reject`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ adminNote: reason })
    });
    const data = await res.json();
    if (data.success) {
      showToast('Settlement rejected. Provider has been notified.', 'success');
      await logAdminActivity('Reject Settlement', id, `Settlement ${id} rejected. Reason: ${reason}`);
      loadSettlementQueue();
      loadSettlementHistory();
    } else {
      showToast(data.error || 'Failed to reject settlement', 'error');
    }
  } catch (e) {
    showToast('Failed to reject settlement', 'error');
  }
}

async function loadPaymentAuditLog() {
  const tbody = document.getElementById('pay-audit-tbody');
  if (!tbody) return;
  tbody.innerHTML = '<tr><td colspan="7" style="text-align:center;padding:40px;color:var(--text-muted);">Loading...</td></tr>';

  const eventType = document.getElementById('audit-filter-type')?.value || '';
  let url = `${API_URL}/payments/audit-logs?`;
  if (eventType) url += `eventType=${eventType}`;

  try {
    const res = await fetch(url);
    const data = await res.json();
    const logs = data.logs || [];

    tbody.innerHTML = '';
    if (logs.length === 0) {
      tbody.innerHTML = '<tr><td colspan="7" style="text-align:center;padding:40px;color:var(--text-muted);">No audit logs found.</td></tr>';
      return;
    }

    logs.slice(0, 200).forEach(l => {
      const eventColors = {
        booking_created: 'var(--primary-solid)',
        payment_success: 'var(--success)',
        payment_failed: 'var(--danger)',
        commission_calculated: 'var(--warning)',
        wallet_updated: 'var(--accent)',
        settlement_created: 'var(--primary-solid)',
        settlement_approved: 'var(--success)',
        settlement_completed: 'var(--success)',
        commission_collected: 'var(--success)',
        cash_confirmed: 'var(--accent)'
      };
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td style="font-size:11px;">${l.createdAt ? new Date(l.createdAt).toLocaleString('en-IN') : '—'}</td>
        <td><span style="font-size:10px;font-weight:700;color:${eventColors[l.eventType] || 'var(--text-primary)'};">${l.eventType.toUpperCase().replace(/_/g, ' ')}</span></td>
        <td style="font-size:11px;font-family:monospace;">${l.bookingId || '—'}</td>
        <td style="font-size:11px;">${l.shopId || '—'}</td>
        <td style="font-weight:600;">${l.amount ? '₹' + l.amount.toFixed(2) : '—'}</td>
        <td><span class="badge ${l.actor === 'admin' ? 'badge-active' : l.actor === 'provider' ? 'badge-pending' : 'badge-completed'}">${l.actor || 'system'}</span></td>
        <td style="font-size:11px;color:var(--text-secondary);">${l.description || '—'}</td>
      `;
      tbody.appendChild(tr);
    });
  } catch (e) {
    console.error('Audit log error:', e);
    tbody.innerHTML = '<tr><td colspan="7" style="text-align:center;color:var(--danger);">Failed to load audit logs.</td></tr>';
  }
}

async function loadCommissionConfig() {
  try {
    const res = await fetch(`${API_URL}/commission-config`);
    const data = await res.json();
    const rateEl = document.getElementById('comm-default-rate');
    const typeEl = document.getElementById('comm-type');
    if (rateEl) rateEl.value = data.defaultCommissionRate || 20;
    if (typeEl) typeEl.value = data.commissionType || 'percentage';
  } catch (e) {
    console.error('Commission config load error:', e);
  }
}

async function loadCommissionReport() {
  const listEl = document.getElementById('comm-report-list');
  if (!listEl) return;
  listEl.innerHTML = '<p style="color:var(--text-muted);font-size:12px;">Loading...</p>';

  try {
    const res = await fetch(`${API_URL}/payments/reports/commission`);
    const data = await res.json();
    const report = data.report || [];

    listEl.innerHTML = '';
    if (report.length === 0) {
      listEl.innerHTML = '<p style="color:var(--text-muted);font-size:12px;">No commission data yet.</p>';
      return;
    }

    report.forEach(r => {
      const div = document.createElement('div');
      div.style.cssText = 'border:1px solid var(--border);border-radius:10px;padding:12px;';
      div.innerHTML = `
        <div style="display:flex;justify-content:space-between;align-items:center;">
          <strong style="font-size:13px;">${r.providerName || r.shopId}</strong>
          <span style="font-size:11px;color:var(--text-muted);">${r.jobCount} jobs</span>
        </div>
        <div style="display:flex;gap:12px;margin-top:8px;font-size:11px;flex-wrap:wrap;">
          <span>Gross: <strong>₹${r.totalGross.toFixed(2)}</strong></span>
          <span>Commission: <strong style="color:var(--warning);">₹${r.totalCommission.toFixed(2)}</strong></span>
          <span>Collected: <strong style="color:var(--success);">₹${r.commissionPaid.toFixed(2)}</strong></span>
          ${r.commissionPending > 0 ? `<span>Pending: <strong style="color:var(--danger);">₹${r.commissionPending.toFixed(2)}</strong></span>` : ''}
        </div>
      `;
      listEl.appendChild(div);
    });
  } catch (e) {
    console.error('Commission report error:', e);
  }
}

function populateCommissionShopDropdowns() {
  const selects = ['comm-collect-shop'];
  selects.forEach(selectId => {
    const sel = document.getElementById(selectId);
    if (!sel) return;
    sel.innerHTML = '<option value="">-- Select Provider --</option>';
    shops.forEach(s => {
      const opt = document.createElement('option');
      opt.value = s.id;
      opt.textContent = `${s.name} (${s.shopDisplayId || s.id})`;
      sel.appendChild(opt);
    });
  });
}

async function saveCommissionConfig() {
  const rate = parseFloat(document.getElementById('comm-default-rate')?.value || '20');
  const type = document.getElementById('comm-type')?.value || 'percentage';

  if (isNaN(rate) || rate < 0 || rate > 100) {
    showToast('Commission rate must be between 0 and 100', 'error');
    return;
  }

  try {
    const res = await fetch(`${API_URL}/commission-config`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ defaultCommissionRate: rate, commissionType: type })
    });
    const data = await res.json();
    if (data.success) {
      showToast(`Commission config saved: ${rate}% (${type})`, 'success');
      await logAdminActivity('Update Commission Config', 'SYSTEM', `Rate: ${rate}%, Type: ${type}`);
    } else {
      showToast(data.error || 'Failed to save commission config', 'error');
    }
  } catch (e) {
    showToast('Failed to save commission config', 'error');
  }
}

async function collectCommission() {
  const shopId = document.getElementById('comm-collect-shop')?.value;
  const amount = parseFloat(document.getElementById('comm-collect-amount')?.value || '0');
  const note = document.getElementById('comm-collect-note')?.value || '';

  if (!shopId) { showToast('Please select a provider', 'warning'); return; }
  if (!amount || amount <= 0) { showToast('Please enter a valid amount', 'warning'); return; }

  if (!confirm(`Mark ₹${amount} as commission collected from ${shops.find(s => s.id === shopId)?.name || shopId}?`)) return;

  try {
    const res = await fetch(`${API_URL}/payments/commission-collect/${shopId}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ amount, note, bookingIds: [] })
    });
    const data = await res.json();
    if (data.success) {
      showToast(`Commission ₹${amount} marked as collected!`, 'success');
      await logAdminActivity('Collect Commission', shopId, `₹${amount} collected. ${note}`);
      document.getElementById('comm-collect-amount').value = '';
      document.getElementById('comm-collect-note').value = '';
      loadCommissionReport();
      refreshAllData();
    } else {
      showToast(data.error || 'Failed to record commission', 'error');
    }
  } catch (e) {
    showToast('Failed to collect commission', 'error');
  }
}

async function collectCommissionForBooking(shopId, bookingId, amount) {
  if (!confirm(`Mark commission ₹${amount.toFixed(2)} as collected for booking ${bookingId}?`)) return;
  try {
    const res = await fetch(`${API_URL}/payments/commission-collect/${shopId}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ amount, note: `Booking ${bookingId}`, bookingIds: [bookingId] })
    });
    const data = await res.json();
    if (data.success) {
      showToast('Commission marked as collected!', 'success');
      loadLedgerTable();
      refreshAllData();
    } else {
      showToast(data.error || 'Failed', 'error');
    }
  } catch (e) {
    showToast('Failed to collect commission', 'error');
  }
}

function exportLedgerCSV() {
  const tbody = document.getElementById('pay-ledger-tbody');
  if (!tbody || !tbody.children.length) return;
  
  let csv = 'Booking ID,Customer,Provider,Gross Amount,Commission,Provider Earnings,Method,Payment Status,Commission Status,Date\n';
  Array.from(tbody.querySelectorAll('tr')).forEach(tr => {
    const cells = Array.from(tr.querySelectorAll('td')).map(td => `"${td.textContent.replace(/"/g, '').trim()}"`);
    if (cells.length > 1) csv += cells.slice(0, 10).join(',') + '\n';
  });

  const blob = new Blob([csv], { type: 'text/csv' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `quickfix_ledger_${new Date().toISOString().split('T')[0]}.csv`;
  a.click();
  URL.revokeObjectURL(url);
  showToast('Ledger CSV exported!', 'success');
}

// Badge helper functions for payment system
function renderPayStatusBadge(status) {
  const map = {
    cash_pending: ['badge-pending', '💵 Cash Pending'],
    cash_collected: ['badge-active', '✅ Cash Collected'],
    paid: ['badge-completed', '💳 Paid'],
    settlement_pending: ['badge-pending', '⏳ Settlement Pending'],
    settled: ['badge-completed', '✅ Settled'],
    pending: ['badge-pending', '⏳ Pending'],
    failed: ['badge-cancelled', '❌ Failed'],
    refunded: ['badge-cancelled', '↩️ Refunded']
  };
  const [cls, label] = map[status] || ['badge-pending', status];
  return `<span class="badge ${cls}" style="font-size:10px;">${label}</span>`;
}

function renderCommStatusBadge(status) {
  const map = {
    pending: ['badge-pending', '⏳ Pending'],
    paid: ['badge-completed', '✅ Paid'],
    waived: ['badge-active', '🎁 Waived'],
    na: ['', '—']
  };
  const [cls, label] = map[status] || ['badge-pending', status];
  return cls ? `<span class="badge ${cls}" style="font-size:10px;">${label}</span>` : label;
}

function renderMethodBadge(method) {
  const map = {
    cash: ['⚠️', '#f59e0b'],
    online: ['💳', 'var(--success)'],
    wallet: ['👛', 'var(--primary-solid)'],
    upi: ['📱', 'var(--accent)'],
    card: ['💳', 'var(--success)'],
    netbanking: ['🏦', 'var(--success)']
  };
  const [icon, color] = map[method] || ['💰', 'var(--text-primary)'];
  return `<span style="font-size:11px;font-weight:600;color:${color};">${icon} ${method ? method.toUpperCase() : '—'}</span>`;
}

// Load Audit logs tab
async function loadAuditLogs() {
  const tbody = document.getElementById('audit-logs-tbody');
  if (!tbody) return;
  tbody.innerHTML = '<tr><td colspan="6" style="text-align:center;"><i class="fa-solid fa-spinner fa-spin"></i> Fetching log...</td></tr>';
  
  try {
    const res = await fetch(`${API_URL}/audit-logs`);
    auditLogs = await res.json();
    
    tbody.innerHTML = '';
    if (auditLogs.length === 0) {
      tbody.innerHTML = '<tr><td colspan="6" style="text-align:center;">Audit logs are clean.</td></tr>';
      return;
    }
    
    auditLogs.forEach(l => {
      const date = new Date(l.createdAt || Date.now()).toLocaleString();
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td>${date}</td>
        <td><span style="font-family: monospace;">${l.adminId}</span></td>
        <td><strong>${l.action}</strong></td>
        <td><span style="color:var(--primary-solid); font-family:monospace;">${l.target || 'N/A'}</span></td>
        <td>${l.details}</td>
        <td><code>${l.ip}</code></td>
      `;
      tbody.appendChild(tr);
    });
  } catch (e) {
    console.error(e);
  }
}

// Load customer demand submissions from backend
async function loadDemands() {
  const tbody = document.getElementById('demand-tbody');
  if (!tbody) return;
  tbody.innerHTML = '<tr><td colspan="5" style="text-align:center;color:var(--text-secondary);padding:24px;"><i class="fa-solid fa-spinner fa-spin"></i> Loading...</td></tr>';

  try {
    const res = await fetch(`${API_URL}/demand`);
    demands = await res.json();

    if (!Array.isArray(demands) || demands.length === 0) {
      tbody.innerHTML = '<tr><td colspan="5" style="text-align:center;color:var(--text-secondary);padding:24px;">No customer demand submissions yet.</td></tr>';
      return;
    }

    tbody.innerHTML = '';
    demands.forEach((d, index) => {
      const date = d.createdAt ? new Date(d.createdAt).toLocaleString('en-IN') : 'N/A';
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td>${index + 1}</td>
        <td><strong>${d.phone}</strong></td>
        <td>${d.address}</td>
        <td><code>${d.latitude.toFixed(4)}, ${d.longitude.toFixed(4)}</code></td>
        <td>${date}</td>
      `;
      tbody.appendChild(tr);
    });
  } catch (e) {
    console.error('Failed to load demands:', e);
  }
}

// Chart renders
let revenueTrendChart = null;
let categorySplitChart = null;
let fulfillmentStatusChart = null;

async function loadReports() {
  // Load aggregate metrics
  let totalGross = 0;
  let couponsCount = 0;
  let completed = 0;
  let cancelled = 0;
  
  bookings.forEach(b => {
    if (b.status === 'completed') {
      totalGross += b.amount;
      completed++;
    } else if (b.status === 'cancelled') {
      cancelled++;
    }
  });
  
  const totalFulfill = completed + cancelled;
  const rate = totalFulfill > 0 ? ((completed / totalFulfill) * 100).toFixed(1) : 100;
  
  document.getElementById('report-gross-volume').textContent = `₹${totalGross.toLocaleString()}`;
  document.getElementById('report-commission').textContent = `₹${(totalGross * 0.10).toFixed(0).toLocaleString()}`;
  document.getElementById('report-fulfillment-rate').textContent = `${rate}%`;
  
  // Render Top shops
  const shopTotals = {};
  shops.forEach(s => {
    shopTotals[s.id] = { name: s.name, rating: s.rating || 5.0, bookingsCount: 0 };
  });
  bookings.forEach(b => {
    if (shopTotals[b.shopId]) {
      shopTotals[b.shopId].bookingsCount++;
    }
  });
  
  const topShopsTbody = document.getElementById('top-shops-tbody');
  topShopsTbody.innerHTML = '';
  Object.values(shopTotals)
    .sort((a,b) => b.bookingsCount - a.bookingsCount)
    .slice(0, 5)
    .forEach(s => {
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td><strong>${s.name}</strong></td>
        <td>⭐ ${s.rating.toFixed(1)}</td>
        <td>${s.bookingsCount} orders</td>
      `;
      topShopsTbody.appendChild(tr);
    });
    
  if (topShopsTbody.innerHTML === '') {
    topShopsTbody.innerHTML = '<tr><td colspan="3" style="text-align:center;">No shop sales recorded yet.</td></tr>';
  }

  // Draw Charts
  await renderCharts();
}

async function renderCharts() {
  try {
    const res = await fetch(`${API_URL}/reports/summary`);
    const summary = await res.json();
    
    const isDark = document.documentElement.getAttribute('data-theme') === 'dark';
    const textColor = isDark ? '#94a3b8' : '#475569';
    const gridColor = isDark ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.05)';

    // 1. Revenue trend Chart
    if (revenueTrendChart) revenueTrendChart.destroy();
    const revCtx = document.getElementById('revenueTrendChart');
    if (revCtx) {
      revenueTrendChart = new Chart(revCtx, {
        type: 'line',
        data: {
          labels: summary.daily.map(d => d.date),
          datasets: [
            {
              label: 'Platform Gross Revenue (₹)',
              data: summary.daily.map(d => d.revenue),
              borderColor: '#3b82f6',
              backgroundColor: 'rgba(59, 130, 246, 0.1)',
              fill: true,
              tension: 0.3,
              borderWidth: 2
            },
            {
              label: 'Total Orders Placed',
              data: summary.daily.map(d => d.bookings),
              borderColor: '#8b5cf6',
              backgroundColor: 'rgba(139, 92, 246, 0.1)',
              fill: false,
              tension: 0.1,
              borderWidth: 1.5,
              yAxisID: 'y1'
            }
          ]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: { labels: { color: textColor, font: { family: 'Outfit' } } }
          },
          scales: {
            x: { grid: { color: gridColor }, ticks: { color: textColor } },
            y: { grid: { color: gridColor }, ticks: { color: textColor } },
            y1: { type: 'linear', position: 'right', grid: { drawOnChartArea: false }, ticks: { color: textColor } }
          }
        }
      });
    }

    // 2. Category split chart
    if (categorySplitChart) categorySplitChart.destroy();
    const catCtx = document.getElementById('categorySplitChart');
    if (catCtx) {
      categorySplitChart = new Chart(catCtx, {
        type: 'doughnut',
        data: {
          labels: summary.categories.map(c => c.name),
          datasets: [{
            data: summary.categories.map(c => c.bookings),
            backgroundColor: ['#3b82f6', '#10b981', '#f59e0b', '#8b5cf6', '#ef4444', '#64748b']
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: { position: 'bottom', labels: { color: textColor, font: { family: 'Outfit' } } }
          }
        }
      });
    }

    // 3. Fulfillment Rate pie chart (in reports tab)
    if (fulfillmentStatusChart) fulfillmentStatusChart.destroy();
    const fulfillCtx = document.getElementById('fulfillmentStatusChart');
    if (fulfillCtx) {
      let pending = bookings.filter(b => b.status === 'pending').length;
      let completed = bookings.filter(b => b.status === 'completed').length;
      let cancelled = bookings.filter(b => b.status === 'cancelled').length;
      let ongoing = bookings.filter(b => b.status === 'accepted' || b.status === 'on_the_way').length;

      fulfillmentStatusChart = new Chart(fulfillCtx, {
        type: 'pie',
        data: {
          labels: ['Completed', 'Cancelled', 'Ongoing', 'Pending'],
          datasets: [{
            data: [completed, cancelled, ongoing, pending],
            backgroundColor: ['#10b981', '#ef4444', '#3b82f6', '#f59e0b']
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: { position: 'bottom', labels: { color: textColor, font: { family: 'Outfit' } } }
          }
        }
      });
    }
  } catch (e) {
    console.error('Failed to render reports summary charts:', e);
  }
}

// Client-side export to CSV
function exportReportsCSV() {
  let csvContent = "data:text/csv;charset=utf-8,";
  csvContent += "Booking ID,Customer Name,Customer Phone,Customer Address,Shop ID,Provider Name,Amount,Status,Scheduled Date\n";
  
  bookings.forEach(b => {
    const row = [
      b.id,
      `"${b.customerName}"`,
      b.customerPhone,
      `"${b.customerAddress}"`,
      b.shopId,
      `"${b.providerName}"`,
      b.amount,
      b.status,
      new Date(b.date).toLocaleDateString()
    ].join(",");
    csvContent += row + "\n";
  });
  
  const encodedUri = encodeURI(csvContent);
  const link = document.createElement("a");
  link.setAttribute("href", encodedUri);
  link.setAttribute("download", `quickfix_platform_bookings_report_${Date.now()}.csv`);
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  showToast('Booking reports CSV generated!', 'success');
}

// --- HOMEPAGE CMS INTEGRATION LOGIC ---
let cmsLayout = [];
let cmsPromotions = [];
let cmsSpecials = [];
let cmsExperts = [];
let cmsReviews = [];

function setupSubtabs() {
  const subtabBtns = document.querySelectorAll('.subtab-btn');
  const subtabPanes = document.querySelectorAll('.subtab-pane');
  
  subtabBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      const subtabId = btn.getAttribute('data-subtab');
      
      subtabBtns.forEach(b => b.classList.remove('active'));
      subtabPanes.forEach(p => {
        p.classList.remove('active');
        p.style.display = 'none';
      });
      
      btn.classList.add('active');
      const targetPane = document.getElementById(subtabId);
      targetPane.classList.add('active');
      targetPane.style.display = 'block';
    });
  });
}

async function loadCmsData() {
  await Promise.all([
    fetchCmsLayout(),
    fetchCmsPromotions(),
    fetchCmsSpecials(),
    fetchCmsExperts(),
    fetchCmsReviews(),
    fetchCmsCustomSections()
  ]);
  renderCmsLayout();
  renderCmsPromotions();
  renderCmsSpecials();
  renderCmsExperts();
  renderCmsReviews();
  renderCustomSectionsList();
  populateExpertShopsDropdown();
}

async function fetchCmsLayout() {
  try {
    const res = await fetch(`${API_URL}/admin/homepage/layout`);
    cmsLayout = await res.json();
  } catch (e) {
    console.error('Error fetching CMS layout:', e);
  }
}

async function fetchCmsPromotions() {
  try {
    const res = await fetch(`${API_URL}/admin/promotions`);
    cmsPromotions = await res.json();
  } catch (e) {
    console.error('Error fetching promotions:', e);
  }
}

async function fetchCmsSpecials() {
  try {
    const res = await fetch(`${API_URL}/admin/special-cards`);
    cmsSpecials = await res.json();
  } catch (e) {
    console.error('Error fetching special cards:', e);
  }
}

async function fetchCmsExperts() {
  try {
    const res = await fetch(`${API_URL}/admin/professionals`);
    cmsExperts = await res.json();
  } catch (e) {
    console.error('Error fetching featured experts:', e);
  }
}

async function fetchCmsReviews() {
  try {
    const res = await fetch(`${API_URL}/admin/reviews`);
    cmsReviews = await res.json();
  } catch (e) {
    console.error('Error fetching reviews:', e);
  }
}

function renderCmsLayout() {
  const tbody = document.getElementById('cms-layout-tbody');
  if (!tbody) return;
  tbody.innerHTML = '';
  
  if (cmsLayout.length === 0) {
    tbody.innerHTML = '<tr><td colspan="6" style="text-align:center;color:var(--text-muted);">No layout sections defined.</td></tr>';
    return;
  }
  
  cmsLayout.forEach((sec, idx) => {
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td>
        <input type="number" class="layout-priority-input form-group" style="width:70px; margin-bottom:0;" data-id="${sec.id}" value="${sec.priority !== undefined ? sec.priority : idx}">
      </td>
      <td><code>${sec.id}</code></td>
      <td><strong>${sec.title}</strong></td>
      <td><span class="badge badge-accepted">${sec.type}</span></td>
      <td>
        <label class="switch">
          <input type="checkbox" class="layout-active-checkbox" data-id="${sec.id}" ${sec.isActive ? 'checked' : ''}>
          <span class="slider"></span>
        </label>
      </td>
      <td>
        <button class="btn btn-secondary btn-sm" onclick="moveLayoutRow(${idx}, -1)" ${idx === 0 ? 'disabled' : ''}><i class="fa-solid fa-arrow-up"></i></button>
        <button class="btn btn-secondary btn-sm" onclick="moveLayoutRow(${idx}, 1)" ${idx === cmsLayout.length - 1 ? 'disabled' : ''}><i class="fa-solid fa-arrow-down"></i></button>
      </td>
    `;
    tbody.appendChild(tr);
  });
}

function moveLayoutRow(idx, direction) {
  const targetIdx = idx + direction;
  if (targetIdx < 0 || targetIdx >= cmsLayout.length) return;
  
  const temp = cmsLayout[idx];
  cmsLayout[idx] = cmsLayout[targetIdx];
  cmsLayout[targetIdx] = temp;
  
  // Re-index priority
  cmsLayout.forEach((sec, i) => {
    sec.priority = i;
  });
  
  renderCmsLayout();
}

async function saveCmsLayoutOrder() {
  const tbody = document.getElementById('cms-layout-tbody');
  const orderList = [];
  const promises = [];
  
  cmsLayout.forEach(sec => {
    const rowInput = tbody.querySelector(`.layout-priority-input[data-id="${sec.id}"]`);
    const rowActive = tbody.querySelector(`.layout-active-checkbox[data-id="${sec.id}"]`);
    
    const priority = rowInput ? parseInt(rowInput.value) : sec.priority;
    const isActive = rowActive ? rowActive.checked : sec.isActive;
    
    orderList.push({ id: sec.id, priority });
    
    promises.push(
      fetch(`${API_URL}/homepage/layout/update`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: sec.id, isActive, priority })
      })
    );
  });
  
  try {
    await Promise.all(promises);
    showToast('CMS Homepage layout order saved successfully!', 'success');
    await logAdminActivity('Save CMS Layout Order', 'Homepage Layout', `Reordered layout configuration`);
    loadCmsData();
  } catch (e) {
    console.error('Failed to save layout order:', e);
    showToast('Failed to save layout order changes', 'error');
  }
}

function renderCmsPromotions() {
  const tbody = document.getElementById('cms-promotions-tbody');
  if (!tbody) return;
  tbody.innerHTML = '';
  
  if (cmsPromotions.length === 0) {
    tbody.innerHTML = '<tr><td colspan="7" style="text-align:center;color:var(--text-muted);">No promotions active.</td></tr>';
    return;
  }
  
  cmsPromotions.forEach(promo => {
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td>
        <div style="display:flex; align-items:center; gap:10px;">
          ${promo.bannerImage ? `<img src="${promo.bannerImage}" style="width:40px; height:40px; border-radius:6px; object-fit:cover;">` : `<i class="fa-solid fa-gifts" style="font-size:24px; color:var(--text-muted);"></i>`}
          <div>
            <strong>${promo.title}</strong>
            <div style="font-size:11px; color:var(--text-secondary);">${promo.subtitle}</div>
          </div>
        </div>
      </td>
      <td><code>${promo.couponCode || 'N/A'}</code></td>
      <td><strong>${promo.offerPercentage || 'N/A'}</strong></td>
      <td><span class="badge badge-accepted">${promo.ctaButtonAction}</span> <code style="font-size:11px;">${promo.ctaButtonActionValue || ''}</code></td>
      <td>
        <span class="color-preview" style="background-color: ${promo.backgroundColor || '#FFF1F0'};"></span>
        <span class="color-preview" style="background-color: ${promo.textColor || '#000000'};"></span>
      </td>
      <td>
        <label class="switch">
          <input type="checkbox" onchange="togglePromoActive('${promo.id}', this.checked)" ${promo.isActive ? 'checked' : ''}>
          <span class="slider"></span>
        </label>
      </td>
      <td>
        <button class="btn btn-secondary btn-sm" onclick="editPromo('${promo.id}')"><i class="fa-solid fa-pen-to-square"></i></button>
        <button class="btn btn-danger btn-sm" onclick="deletePromo('${promo.id}')"><i class="fa-solid fa-trash-can"></i></button>
      </td>
    `;
    tbody.appendChild(tr);
  });
}

function editPromo(id) {
  const promo = cmsPromotions.find(p => p.id === id);
  if (!promo) return;
  
  document.getElementById('promo-modal-title').textContent = "Edit Promo Ribbon";
  document.getElementById('edit-promo-id').value = promo.id;
  document.getElementById('promo-title').value = promo.title;
  document.getElementById('promo-subtitle').value = promo.subtitle;
  document.getElementById('promo-desc').value = promo.description || '';
  document.getElementById('promo-pct').value = promo.offerPercentage || '';
  document.getElementById('promo-code').value = promo.couponCode || '';
  document.getElementById('promo-cta').value = promo.ctaButtonAction || 'No Action';
  document.getElementById('promo-cta-val').value = promo.ctaButtonActionValue || '';
  document.getElementById('promo-image').value = promo.bannerImage || '';
  document.getElementById('promo-color-bg').value = promo.backgroundColor || '#FFF1F0';
  document.getElementById('promo-color-txt').value = promo.textColor || '#000000';
  document.getElementById('promo-color-btn').value = promo.buttonColor || '#FF4D4F';
  document.getElementById('promo-color-btn-txt').value = promo.buttonTextColor || '#FFFFFF';
  document.getElementById('promo-priority').value = promo.priority || 0;
  document.getElementById('promo-active').value = promo.isActive ? "true" : "false";
  document.getElementById('promo-start').value = promo.startDate ? promo.startDate.substring(0, 16) : '';
  document.getElementById('promo-end').value = promo.endDate ? promo.endDate.substring(0, 16) : '';
  
  document.getElementById('promo-modal').classList.add('active');
}

async function togglePromoActive(id, isActive) {
  const promo = cmsPromotions.find(p => p.id === id);
  if (!promo) return;
  try {
    const updated = { ...promo, isActive };
    const res = await fetch(`${API_URL}/promotions`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(updated)
    });
    const data = await res.json();
    if (data.success) {
      showToast('Promotion active state toggled', 'success');
      fetchCmsPromotions().then(renderCmsPromotions);
    }
  } catch (e) {
    console.error(e);
  }
}

async function deletePromo(id) {
  if (confirm('Delete this promotional ribbon permanently?')) {
    try {
      const res = await fetch(`${API_URL}/promotions/${id}`, { method: 'DELETE' });
      const data = await res.json();
      if (data.success) {
        showToast('Promotion deleted', 'success');
        await logAdminActivity('Delete Promotion', id, 'Deleted promotional homepage ribbon');
        loadCmsData();
      }
    } catch (e) {
      console.error(e);
    }
  }
}

function renderCmsSpecials() {
  const tbody = document.getElementById('cms-specials-tbody');
  if (!tbody) return;
  tbody.innerHTML = '';
  
  if (cmsSpecials.length === 0) {
    tbody.innerHTML = '<tr><td colspan="6" style="text-align:center;color:var(--text-muted);">No special cards defined.</td></tr>';
    return;
  }
  
  cmsSpecials.forEach((card, idx) => {
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td>
        <input type="number" class="special-priority-input form-group" style="width:70px; margin-bottom:0;" data-id="${card.id}" value="${card.priority !== undefined ? card.priority : idx}">
      </td>
      <td><i class="fa-solid fa-star" style="font-size:18px; color:var(--primary-solid);"></i> <code style="font-size:11px;">${card.icon}</code></td>
      <td>
        <strong>${card.title}</strong>
        <div style="font-size:11px; color:var(--text-secondary);">${card.subtitle || card.description}</div>
      </td>
      <td><span class="badge badge-on_the_way">${card.ctaAction}</span> <code style="font-size:11px;">${card.ctaActionValue || ''}</code></td>
      <td>
        <label class="switch">
          <input type="checkbox" onchange="toggleSpecialActive('${card.id}', this.checked)" ${card.isActive ? 'checked' : ''}>
          <span class="slider"></span>
        </label>
      </td>
      <td>
        <button class="btn btn-secondary btn-sm" onclick="editSpecial('${card.id}')"><i class="fa-solid fa-pen-to-square"></i></button>
        <button class="btn btn-danger btn-sm" onclick="deleteSpecial('${card.id}')"><i class="fa-solid fa-trash-can"></i></button>
      </td>
    `;
    tbody.appendChild(tr);
  });
}

function editSpecial(id) {
  const card = cmsSpecials.find(c => c.id === id);
  if (!card) return;
  
  document.getElementById('special-modal-title').textContent = "Edit Special Card";
  document.getElementById('edit-special-id').value = card.id;
  document.getElementById('special-title').value = card.title;
  document.getElementById('special-subtitle').value = card.subtitle || '';
  document.getElementById('special-desc').value = card.description || '';
  document.getElementById('special-icon').value = card.icon || 'star';
  document.getElementById('special-bg-color').value = card.backgroundColor || '#EEF2FF';
  document.getElementById('special-cta').value = card.ctaAction || 'No Action';
  document.getElementById('special-cta-val').value = card.ctaActionValue || '';
  document.getElementById('special-priority').value = card.priority || 0;
  document.getElementById('special-active').value = card.isActive ? "true" : "false";
  
  document.getElementById('special-card-modal').classList.add('active');
}

async function toggleSpecialActive(id, isActive) {
  const card = cmsSpecials.find(c => c.id === id);
  if (!card) return;
  try {
    const updated = { ...card, isActive };
    const res = await fetch(`${API_URL}/special-cards`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(updated)
    });
    const data = await res.json();
    if (data.success) {
      showToast('Special card active state toggled', 'success');
      fetchCmsSpecials().then(renderCmsSpecials);
    }
  } catch (e) {
    console.error(e);
  }
}

async function deleteSpecial(id) {
  if (confirm('Delete this Special For You card permanently?')) {
    try {
      const res = await fetch(`${API_URL}/special-cards/${id}`, { method: 'DELETE' });
      const data = await res.json();
      if (data.success) {
        showToast('Special card deleted', 'success');
        await logAdminActivity('Delete Special Card', id, 'Deleted Special For You promotional card');
        loadCmsData();
      }
    } catch (e) {
      console.error(e);
    }
  }
}

function renderCmsExperts() {
  const tbody = document.getElementById('cms-experts-tbody');
  if (!tbody) return;
  tbody.innerHTML = '';
  
  if (cmsExperts.length === 0) {
    tbody.innerHTML = '<tr><td colspan="8" style="text-align:center;color:var(--text-muted);">No experts registered.</td></tr>';
    return;
  }
  
  cmsExperts.forEach((exp, idx) => {
    const tr = document.createElement('tr');
    const isLinked = !!exp.shopId;
    const linkedShopName = isLinked ? (shops.find(s => s.id === exp.shopId)?.name || `Shop ID: ${exp.shopId}`) : '<span style="color:var(--text-muted);">None (Standalone)</span>';
    
    tr.innerHTML = `
      <td>
        <input type="number" class="expert-priority-input form-group" style="width:70px; margin-bottom:0;" data-id="${exp.id}" value="${exp.priority !== undefined ? exp.priority : idx}">
      </td>
      <td>
        <div style="display:flex; align-items:center; gap:10px;">
          <img src="${exp.imageUrl || 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150'}" style="width:36px; height:36px; border-radius:50%; object-fit:cover; border: 1.5px solid var(--primary-solid);">
          <div>
            <strong>${exp.name}</strong>
            ${exp.verifiedBadge ? '<span style="font-size:10px; color:var(--success); margin-left:4px;"><i class="fa-solid fa-circle-check"></i></span>' : ''}
            <div style="font-size:10px; color:var(--text-muted);">${exp.experience || 'N/A exp'} • ${exp.completedJobs || 0} jobs</div>
          </div>
        </div>
      </td>
      <td><strong>${exp.specialty}</strong></td>
      <td>${linkedShopName}</td>
      <td>⭐ ${exp.rating ? exp.rating.toFixed(1) : '5.0'}</td>
      <td>
        <span class="badge ${exp.availability ? 'badge-active' : 'badge-inactive'}">${exp.availability ? 'Available' : 'Busy/Offline'}</span>
      </td>
      <td>
        <label class="switch">
          <input type="checkbox" onchange="toggleExpertActive('${exp.id}', this.checked)" ${exp.isActive !== false ? 'checked' : ''}>
          <span class="slider"></span>
        </label>
      </td>
      <td>
        <button class="btn btn-secondary btn-sm" onclick="editExpert('${exp.id}')"><i class="fa-solid fa-pen-to-square"></i></button>
        <button class="btn btn-danger btn-sm" onclick="deleteExpert('${exp.id}')"><i class="fa-solid fa-trash-can"></i></button>
      </td>
    `;
    tbody.appendChild(tr);
  });
}

function populateExpertShopsDropdown() {
  const select = document.getElementById('expert-shop');
  if (!select) return;
  
  const currentVal = select.value;
  select.innerHTML = '<option value="">-- No Linked Shop (Stand-alone profile) --</option>';
  
  shops.forEach(s => {
    const opt = document.createElement('option');
    opt.value = s.id;
    opt.textContent = `${s.name} (Owner: ${s.ownerName})`;
    select.appendChild(opt);
  });
  select.value = currentVal;
}

function editExpert(id) {
  const exp = cmsExperts.find(e => e.id === id);
  if (!exp) return;
  
  document.getElementById('expert-modal-title').textContent = "Edit Featured Expert";
  document.getElementById('edit-expert-id').value = exp.id;
  document.getElementById('expert-name').value = exp.name;
  document.getElementById('expert-shop').value = exp.shopId || '';
  document.getElementById('expert-specialty').value = exp.specialty || '';
  document.getElementById('expert-exp').value = exp.experience || '';
  document.getElementById('expert-rating').value = exp.rating || 5.0;
  document.getElementById('expert-jobs').value = exp.completedJobs || 0;
  document.getElementById('expert-image').value = exp.imageUrl || '';
  document.getElementById('expert-location').value = exp.location || '';
  document.getElementById('expert-priority').value = exp.priority || 0;
  document.getElementById('expert-active').value = exp.isActive !== false ? "true" : "false";
  
  document.getElementById('expert-modal').classList.add('active');
}

async function toggleExpertActive(id, isActive) {
  const exp = cmsExperts.find(e => e.id === id);
  if (!exp) return;
  try {
    const updated = { ...exp, isActive };
    const res = await fetch(`${API_URL}/professionals`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(updated)
    });
    const data = await res.json();
    if (data.success) {
      showToast('Expert active state toggled', 'success');
      fetchCmsExperts().then(renderCmsExperts);
    }
  } catch (e) {
    console.error(e);
  }
}

async function deleteExpert(id) {
  if (confirm('Delete this expert profile permanently?')) {
    try {
      const res = await fetch(`${API_URL}/professionals/${id}`, { method: 'DELETE' });
      const data = await res.json();
      if (data.success) {
        showToast('Expert profile deleted', 'success');
        await logAdminActivity('Delete Professional Expert', id, 'Deleted featured expert card');
        loadCmsData();
      }
    } catch (e) {
      console.error(e);
    }
  }
}

function renderCmsReviews() {
  const tbody = document.getElementById('cms-reviews-tbody');
  if (!tbody) return;
  tbody.innerHTML = '';
  
  if (cmsReviews.length === 0) {
    tbody.innerHTML = '<tr><td colspan="7" style="text-align:center;color:var(--text-muted);">No reviews submitted.</td></tr>';
    return;
  }
  
  cmsReviews.forEach(rev => {
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td>
        <div style="display:flex; align-items:center; gap:10px;">
          <img src="${rev.userAvatar || 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150'}" style="width:30px; height:30px; border-radius:50%; object-fit:cover;">
          <div>
            <strong>${rev.userName}</strong>
            <div style="font-size:10px; color:var(--text-muted);">${rev.locationName || 'Kanpur'}</div>
          </div>
        </div>
      </td>
      <td>
        <strong>${rev.serviceName || 'General'}</strong>
        ${rev.providerName ? `<div style="font-size:10px; color:var(--text-secondary);">Expert: ${rev.providerName}</div>` : ''}
      </td>
      <td>
        <div style="max-width:300px; white-space:normal; font-size:12px;">"${rev.comment}"</div>
        ${rev.reply ? `<div style="font-size:11px; color:var(--primary-solid); margin-top:4px;"><strong>Reply:</strong> ${rev.reply}</div>` : ''}
      </td>
      <td>⭐ ${rev.rating ? rev.rating.toFixed(1) : '5.0'}</td>
      <td>
        <label class="switch">
          <input type="checkbox" onchange="toggleReviewFeatured('${rev.id}', this.checked)" ${rev.isFeatured ? 'checked' : ''}>
          <span class="slider"></span>
        </label>
      </td>
      <td>
        <select class="table-action-select" onchange="changeReviewStatus('${rev.id}', this.value)" style="background-color: var(--surface-solid);">
          <option value="approved" ${rev.status === 'approved' ? 'selected' : ''}>Approved</option>
          <option value="pending" ${rev.status === 'pending' ? 'selected' : ''}>Pending</option>
          <option value="rejected" ${rev.status === 'rejected' ? 'selected' : ''}>Rejected</option>
        </select>
      </td>
      <td>
        <button class="btn btn-secondary btn-sm" onclick="editReview('${rev.id}')" title="Edit Review"><i class="fa-solid fa-pen-to-square"></i></button>
        <button class="btn btn-secondary btn-sm" onclick="promptReviewReply('${rev.id}')" title="Reply to Review"><i class="fa-solid fa-reply"></i></button>
        <button class="btn btn-danger btn-sm" onclick="deleteReview('${rev.id}')"><i class="fa-solid fa-trash-can"></i></button>
      </td>
    `;
    tbody.appendChild(tr);
  });
}

function editReview(id) {
  const rev = cmsReviews.find(r => r.id === id);
  if (!rev) return;

  document.getElementById('review-modal-title').textContent = "Edit Testimonial Review";
  document.getElementById('edit-review-id').value = rev.id;
  document.getElementById('review-user-name').value = rev.userName || '';
  document.getElementById('review-user-avatar').value = rev.userAvatar || '';
  document.getElementById('review-service-name').value = rev.serviceName || '';
  document.getElementById('review-provider-name').value = rev.providerName || '';
  document.getElementById('review-rating').value = rev.rating || 5.0;
  document.getElementById('review-location-name').value = rev.locationName || '';
  document.getElementById('review-comment').value = rev.comment || '';
  document.getElementById('review-priority').value = rev.priority || 0;
  document.getElementById('review-status').value = rev.status || 'approved';
  document.getElementById('review-featured').value = rev.isFeatured ? "true" : "false";
  document.getElementById('review-active').value = rev.isActive !== false ? "true" : "false";

  document.getElementById('review-modal').classList.add('active');
}

async function changeReviewStatus(id, status) {
  try {
    const res = await fetch(`${API_URL}/reviews/approve`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id, status })
    });
    const data = await res.json();
    if (data.success) {
      showToast(`Review status updated to: ${status}`, 'success');
      await logAdminActivity('Update Review Status', id, `Updated review state to ${status}`);
      fetchCmsReviews().then(renderCmsReviews);
    }
  } catch (e) {
    console.error(e);
  }
}

async function toggleReviewFeatured(id, isFeatured) {
  const review = cmsReviews.find(r => r.id === id);
  if (!review) return;
  try {
    const updated = { ...review, isFeatured };
    const res = await fetch(`${API_URL}/reviews`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(updated)
    });
    const data = await res.json();
    if (data.success) {
      showToast('Review featured status toggled', 'success');
      fetchCmsReviews().then(renderCmsReviews);
    }
  } catch (e) {
    console.error(e);
  }
}

async function promptReviewReply(id) {
  const review = cmsReviews.find(r => r.id === id);
  if (!review) return;
  const reply = prompt('Enter your response reply to this customer testimonial review:', review.reply || '');
  if (reply === null) return;
  
  try {
    const updated = { ...review, reply };
    const res = await fetch(`${API_URL}/reviews`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(updated)
    });
    const data = await res.json();
    if (data.success) {
      showToast('Testimonial response reply saved!', 'success');
      await logAdminActivity('Reply Review Testimonial', id, `Saved admin reply: ${reply}`);
      fetchCmsReviews().then(renderCmsReviews);
    }
  } catch (e) {
    console.error(e);
  }
}

async function deleteReview(id) {
  if (confirm('Delete this customer review permanently?')) {
    try {
      const res = await fetch(`${API_URL}/reviews/${id}`, { method: 'DELETE' });
      const data = await res.json();
      if (data.success) {
        showToast('Review deleted successfully', 'success');
        await logAdminActivity('Delete Customer Review', id, 'Deleted testimonial review entry');
        loadCmsData();
      }
    } catch (e) {
      console.error(e);
    }
  }
}

function setupCmsEvents() {
  const saveLayoutBtn = document.getElementById('btn-save-layout-order');
  if (saveLayoutBtn) {
    saveLayoutBtn.addEventListener('click', saveCmsLayoutOrder);
  }

  const addPromoBtn = document.getElementById('btn-add-promo-modal');
  if (addPromoBtn) {
    addPromoBtn.addEventListener('click', () => {
      document.getElementById('promo-modal-title').textContent = "Add Promo Ribbon";
      document.getElementById('edit-promo-id').value = "";
      document.getElementById('promo-form').reset();
      document.getElementById('promo-modal').classList.add('active');
    });
  }

  const addSpecialBtn = document.getElementById('btn-add-special-modal');
  if (addSpecialBtn) {
    addSpecialBtn.addEventListener('click', () => {
      document.getElementById('special-modal-title').textContent = "Add Special Card";
      document.getElementById('edit-special-id').value = "";
      document.getElementById('special-form').reset();
      document.getElementById('special-card-modal').classList.add('active');
    });
  }

  const addExpertBtn = document.getElementById('btn-add-expert-modal');
  if (addExpertBtn) {
    addExpertBtn.addEventListener('click', () => {
      document.getElementById('expert-modal-title').textContent = "Add Featured Expert";
      document.getElementById('edit-expert-id').value = "";
      document.getElementById('expert-shop').value = "";
      document.getElementById('expert-form').reset();
      populateExpertShopsDropdown();
      document.getElementById('expert-modal').classList.add('active');
    });
  }

  const addReviewBtn = document.getElementById('btn-add-review-modal');
  if (addReviewBtn) {
    addReviewBtn.addEventListener('click', () => {
      document.getElementById('review-modal-title').textContent = "Add Testimonial Review";
      document.getElementById('edit-review-id').value = "";
      document.getElementById('review-form').reset();
      document.getElementById('review-modal').classList.add('active');
    });
  }

  setupCustomSectionEvents();
}

function setupCmsForms() {
  const promoForm = document.getElementById('promo-form');
  if (promoForm) {
    promoForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      const id = document.getElementById('edit-promo-id').value;
      const title = document.getElementById('promo-title').value;
      const subtitle = document.getElementById('promo-subtitle').value;
      const description = document.getElementById('promo-desc').value;
      const offerPercentage = document.getElementById('promo-pct').value;
      const couponCode = document.getElementById('promo-code').value;
      const ctaButtonText = 'Grab Now';
      const ctaButtonAction = document.getElementById('promo-cta').value;
      const ctaButtonActionValue = document.getElementById('promo-cta-val').value;
      const bannerImage = document.getElementById('promo-image').value;
      const backgroundColor = document.getElementById('promo-color-bg').value;
      const textColor = document.getElementById('promo-color-txt').value;
      const buttonColor = document.getElementById('promo-color-btn').value;
      const buttonTextColor = document.getElementById('promo-color-btn-txt').value;
      const priority = document.getElementById('promo-priority').value;
      const isActive = document.getElementById('promo-active').value === "true";
      const startDate = document.getElementById('promo-start').value;
      const endDate = document.getElementById('promo-end').value;
      
      const body = { id, title, subtitle, description, offerPercentage, couponCode, ctaButtonText, ctaButtonAction, ctaButtonActionValue, bannerImage, backgroundColor, textColor, buttonColor, buttonTextColor, priority, isActive, startDate, endDate };
      
      try {
        const res = await fetch(`${API_URL}/promotions`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(body)
        });
        const data = await res.json();
        if (data.success) {
          showToast('Promotion saved successfully', 'success');
          await logAdminActivity(id ? 'Edit Promotion' : 'Create Promotion', data.promotion.id, `Saved homepage promotion ribbon: ${title}`);
          document.getElementById('promo-modal').classList.remove('active');
          loadCmsData();
        }
      } catch (err) {
        console.error(err);
        showToast('Failed to save promotion ribbon', 'error');
      }
    });
  }

  const specialForm = document.getElementById('special-form');
  if (specialForm) {
    specialForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      const id = document.getElementById('edit-special-id').value;
      const title = document.getElementById('special-title').value;
      const subtitle = document.getElementById('special-subtitle').value;
      const description = document.getElementById('special-desc').value;
      const icon = document.getElementById('special-icon').value;
      const backgroundColor = document.getElementById('special-bg-color').value;
      const ctaAction = document.getElementById('special-cta').value;
      const ctaActionValue = document.getElementById('special-cta-val').value;
      const priority = document.getElementById('special-priority').value;
      const isActive = document.getElementById('special-active').value === "true";
      
      const body = { id, title, subtitle, description, icon, backgroundColor, ctaAction, ctaActionValue, priority, isActive };
      
      try {
        const res = await fetch(`${API_URL}/special-cards`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(body)
        });
        const data = await res.json();
        if (data.success) {
          showToast('Special card saved successfully', 'success');
          await logAdminActivity(id ? 'Edit Special Card' : 'Create Special Card', data.card.id, `Saved special for you card: ${title}`);
          document.getElementById('special-card-modal').classList.remove('active');
          loadCmsData();
        }
      } catch (err) {
        console.error(err);
        showToast('Failed to save special card', 'error');
      }
    });
  }

  const expertForm = document.getElementById('expert-form');
  if (expertForm) {
    expertForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      const id = document.getElementById('edit-expert-id').value;
      const name = document.getElementById('expert-name').value;
      const shopId = document.getElementById('expert-shop').value;
      const specialty = document.getElementById('expert-specialty').value;
      const experience = document.getElementById('expert-exp').value;
      const rating = document.getElementById('expert-rating').value;
      const completedJobs = document.getElementById('expert-jobs').value;
      const imageUrl = document.getElementById('expert-image').value;
      const location = document.getElementById('expert-location').value;
      const priority = document.getElementById('expert-priority').value;
      const isActive = document.getElementById('expert-active').value === "true";
      
      const body = { id, name, shopId, specialty, experience, rating, completedJobs, imageUrl, location, priority, isActive };
      
      try {
        const res = await fetch(`${API_URL}/professionals`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(body)
        });
        const data = await res.json();
        if (data.success) {
          showToast('Expert profile saved successfully', 'success');
          await logAdminActivity(id ? 'Edit Expert' : 'Create Expert', data.professional.id, `Saved featured expert: ${name}`);
          document.getElementById('expert-modal').classList.remove('active');
          loadCmsData();
        }
      } catch (err) {
        console.error(err);
        showToast('Failed to save expert profile', 'error');
      }
    });
  }

  const reviewForm = document.getElementById('review-form');
  if (reviewForm) {
    reviewForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      const id = document.getElementById('edit-review-id').value;
      const userName = document.getElementById('review-user-name').value;
      const userAvatar = document.getElementById('review-user-avatar').value;
      const rating = document.getElementById('review-rating').value;
      const comment = document.getElementById('review-comment').value;
      const serviceName = document.getElementById('review-service-name').value;
      const locationName = document.getElementById('review-location-name').value;
      const providerName = document.getElementById('review-provider-name').value;
      const priority = document.getElementById('review-priority').value;
      const status = document.getElementById('review-status').value;
      const isFeatured = document.getElementById('review-featured').value === "true";
      const isActive = document.getElementById('review-active').value === "true";

      const body = { id, userName, userAvatar, rating: parseFloat(rating), comment, serviceName, locationName, providerName, priority: parseInt(priority) || 0, status, isFeatured, isActive };

      try {
        const res = await fetch(`${API_URL}/reviews`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(body)
        });
        const data = await res.json();
        if (data.success) {
          showToast('Testimonial saved successfully', 'success');
          await logAdminActivity(id ? 'Edit Testimonial' : 'Create Testimonial', data.review.id, `Saved review/testimonial for: ${userName}`);
          document.getElementById('review-modal').classList.remove('active');
          loadCmsData();
        }
      } catch (err) {
        console.error(err);
        showToast('Failed to save testimonial', 'error');
      }
    });
  }
}

// Bind handlers globally for dynamic HTML events
window.openServicesModal = openServicesModal;
window.deleteShop = deleteShop;
window.toggleShopOnline = toggleShopOnline;
window.toggleShopLogin = toggleShopLogin;
window.approveShop = approveShop;
window.suspendShop = suspendShop;
window.resetShopPassword = resetShopPassword;
window.editShop = editShop;
window.deleteBanner = deleteBanner;
window.editBanner = editBanner;
window.deleteOffer = deleteOffer;
window.editOffer = editOffer;
window.moveService = moveService;
window.loadServiceForEdit = loadServiceForEdit;
window.deleteService = deleteService;
window.changeBookingStatus = changeBookingStatus;
window.updateProviderName = updateProviderName;
window.renderManageBookingsTable = renderManageBookingsTable;
window.loadDemands = loadDemands;
window.triggerWalletAdjustment = triggerWalletAdjustment;
window.toggleUserBlock = toggleUserBlock;
window.loadAuditLogs = loadAuditLogs;
window.exportReportsCSV = exportReportsCSV;

// CMS Bindings
window.moveLayoutRow = moveLayoutRow;
window.togglePromoActive = togglePromoActive;
window.editPromo = editPromo;
window.deletePromo = deletePromo;
window.toggleSpecialActive = toggleSpecialActive;
window.editSpecial = editSpecial;
window.deleteSpecial = deleteSpecial;
window.toggleExpertActive = toggleExpertActive;
window.editExpert = editExpert;
window.deleteExpert = deleteExpert;
window.changeReviewStatus = changeReviewStatus;
window.toggleReviewFeatured = toggleReviewFeatured;
window.promptReviewReply = promptReviewReply;
window.deleteReview = deleteReview;
window.editReview = editReview;
window.loadCmsData = loadCmsData;
window.saveCmsLayoutOrder = saveCmsLayoutOrder;
window.exportReportsCSV = exportReportsCSV;

// Custom Sections CMS Logic
let cmsCustomSections = [];

async function fetchCmsCustomSections() {
  try {
    const res = await fetch(`${API_URL}/admin/custom-sections`);
    cmsCustomSections = await res.json();
  } catch (e) {
    console.error('Error fetching custom sections:', e);
    cmsCustomSections = [];
  }
}

function renderCustomSectionsList() {
  const container = document.getElementById('custom-sections-list');
  if (!container) return;
  container.innerHTML = '';

  if (!cmsCustomSections || cmsCustomSections.length === 0) {
    container.innerHTML = `
      <div style="text-align:center; padding:40px; color:var(--text-muted);">
        <i class="fa-solid fa-puzzle-piece" style="font-size:32px; margin-bottom:12px; display:block;"></i>
        <p>No custom sections yet. Click 'Create Custom Section' to get started!</p>
      </div>`;
    return;
  }

  cmsCustomSections.forEach(sec => {
    const card = document.createElement('div');
    card.style.cssText = 'background: var(--surface); border: 1px solid var(--border); border-radius: 12px; overflow: hidden; margin-bottom: 12px;';
    
    const bannerPreview = sec.bannerImageUrl 
      ? `<div style="position:relative; height:120px; overflow:hidden;">
           <img src="${sec.bannerImageUrl}" style="width:100%; height:100%; object-fit:cover;" onerror="this.style.display='none'">
           <div style="position:absolute; inset:0; background:linear-gradient(to bottom, rgba(0,0,0,0.1), rgba(0,0,0,0.7)); display:flex; flex-direction:column; justify-content:flex-end; padding:10px;">
             ${sec.bannerBadgeText ? `<span style="background:#1a9e3f; color:white; font-size:9px; padding:2px 8px; border-radius:3px; width:fit-content; margin-bottom:3px;">${sec.bannerBadgeText}</span>` : ''}
             <span style="color:white; font-size:15px; font-weight:bold;">${sec.title}</span>
           </div>
         </div>` 
      : `<div style="height:60px; background: linear-gradient(135deg, var(--primary-solid), var(--primary-end)); display:flex; align-items:center; justify-content:center; padding: 10px;">
           <span style="color:white; font-weight:bold;"><i class="fa-solid fa-puzzle-piece"></i> ${sec.title}</span>
         </div>`;
    
    const serviceItemsPreview = sec.serviceItems && sec.serviceItems.length > 0
      ? `<div style="display:flex; gap:12px; overflow-x:auto; padding-top:8px; padding-bottom:8px;">
          ${sec.serviceItems.map(item => `
            <div style="min-width:100px; max-width:100px; text-align:center;">
              <div style="width:100px; height:70px; border-radius:8px; overflow:hidden; background:var(--background); border:1px solid var(--border);">
                ${item.imageUrl ? `<img src="${item.imageUrl}" style="width:100%; height:100%; object-fit:cover;">` : `<div style="width:100%; height:100%; display:flex; align-items:center; justify-content:center;"><i class="fa-solid fa-wrench" style="color:var(--text-muted);"></i></div>`}
              </div>
              <div style="font-size:10px; margin-top:4px; color:var(--text-primary); white-space:nowrap; overflow:hidden; text-overflow:ellipsis; font-weight:500;">${item.title}</div>
              <div style="font-size:9px; color:var(--text-muted);">${item.startingPrice ? `${item.startingPrice}` : ''} ${item.rating ? `⭐${item.rating}` : ''}</div>
            </div>
          `).join('')}
         </div>`
      : `<p style="color:var(--text-muted); font-size:12px; font-style:italic; margin-top:8px;">No service cards added to this section.</p>`;

    card.innerHTML = `
      ${bannerPreview}
      <div style="padding: 14px;">
        <div style="display:flex; justify-content:space-between; align-items:flex-start; margin-bottom:8px;">
          <div>
            <strong style="font-size:14px; color:var(--text-primary);">${sec.title}</strong>
            ${sec.subtitle ? `<div style="font-size:11px; color:var(--text-muted); margin-top:2px;">${sec.subtitle}</div>` : ''}
          </div>
          <div style="display:flex; gap:8px; align-items:center;">
            <span class="badge ${sec.isActive ? 'badge-accepted' : 'badge-rejected'}">${sec.isActive ? 'Active' : 'Inactive'}</span>
            <button class="btn btn-secondary btn-sm" onclick="editCustomSection('${sec.id}')"><i class="fa-solid fa-pen-to-square"></i></button>
            <button class="btn btn-danger btn-sm" onclick="deleteCustomSection('${sec.id}')"><i class="fa-solid fa-trash-can"></i></button>
          </div>
        </div>
        <div style="margin-bottom:6px;">
          <span style="font-size:11px; color:var(--text-muted);"><i class="fa-solid fa-layer-group"></i> Priority: ${sec.priority} | Click action: ${sec.bannerActionType || 'No Action'} (${sec.bannerActionValue || 'none'})</span>
        </div>
        ${serviceItemsPreview}
      </div>
    `;
    container.appendChild(card);
  });
}

function setupCustomSectionBannerPreview() {
  const imgInput = document.getElementById('custom-section-banner-image');
  const badgeInput = document.getElementById('custom-section-banner-badge');
  const titleInput = document.getElementById('custom-section-title');
  const previewDiv = document.getElementById('custom-section-banner-preview');
  const previewImg = document.getElementById('custom-section-banner-img');
  const previewBadge = document.getElementById('custom-section-banner-badge-preview');
  const previewTitle = document.getElementById('custom-section-banner-title-preview');

  function updatePreview() {
    const url = imgInput.value.trim();
    if (url) {
      previewDiv.style.display = 'block';
      previewImg.src = url;
      previewBadge.textContent = badgeInput.value || '';
      previewBadge.style.display = badgeInput.value ? 'inline-block' : 'none';
      previewTitle.textContent = titleInput.value || 'Banner Title';
    } else {
      previewDiv.style.display = 'none';
    }
  }

  if (imgInput) imgInput.addEventListener('input', updatePreview);
  if (badgeInput) badgeInput.addEventListener('input', updatePreview);
  if (titleInput) titleInput.addEventListener('input', updatePreview);
}

function addServiceItemRow(data = {}) {
  const container = document.getElementById('service-items-container');
  if (!container) return;

  const itemId = data.id || `si-${Date.now()}-${Math.random().toString(36).substr(2, 5)}`;
  const row = document.createElement('div');
  row.className = 'service-item-row';
  row.setAttribute('data-item-id', itemId);
  row.style.cssText = 'background: var(--background); border: 1px solid var(--border); border-radius: 8px; padding: 12px; margin-bottom: 8px; position:relative;';
  row.innerHTML = `
    <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:8px;">
      <strong style="font-size:12px; color:var(--primary-solid);"><i class="fa-solid fa-wrench"></i> Service Card Details</strong>
      <button type="button" class="btn btn-danger btn-sm" onclick="this.closest('.service-item-row').remove()" style="padding: 2px 6px; font-size:10px;"><i class="fa-solid fa-trash-can"></i> Remove</button>
    </div>
    <div class="form-row">
      <div class="form-group" style="margin-bottom:8px;">
        <label style="font-size:11px; margin-bottom:2px;">Service Title *</label>
        <input type="text" class="si-title" value="${data.title || ''}" placeholder="e.g. Sofa Cleaning" required style="padding: 6px; font-size:12px;">
      </div>
      <div class="form-group" style="margin-bottom:8px;">
        <label style="font-size:11px; margin-bottom:2px;">Image URL</label>
        <input type="url" class="si-image" value="${data.imageUrl || ''}" placeholder="https://images.unsplash.com/..." style="padding: 6px; font-size:12px;">
      </div>
    </div>
    <div class="form-row">
      <div class="form-group" style="margin-bottom:8px;">
        <label style="font-size:11px; margin-bottom:2px;">Rating (0 - 5)</label>
        <input type="number" class="si-rating" value="${data.rating || 4.5}" step="0.1" min="0" max="5" style="padding: 6px; font-size:12px;">
      </div>
      <div class="form-group" style="margin-bottom:8px;">
        <label style="font-size:11px; margin-bottom:2px;">Reviews Count</label>
        <input type="text" class="si-reviews" value="${data.reviewsCount || ''}" placeholder="e.g. 1.2K or 580" style="padding: 6px; font-size:12px;">
      </div>
    </div>
    <div class="form-row">
      <div class="form-group" style="margin-bottom:8px;">
        <label style="font-size:11px; margin-bottom:2px;">Starting Price</label>
        <input type="text" class="si-price" value="${data.startingPrice || ''}" placeholder="e.g. ₹599" style="padding: 6px; font-size:12px;">
      </div>
      <div class="form-group" style="margin-bottom:8px;">
        <label style="font-size:11px; margin-bottom:2px;">On Click Action</label>
        <select class="si-action" style="padding: 6px; font-size:12px;">
          <option value="Open Shop" ${(data.actionType || 'Open Shop') === 'Open Shop' ? 'selected' : ''}>Open Shop</option>
          <option value="Open Category" ${data.actionType === 'Open Category' ? 'selected' : ''}>Open Category</option>
          <option value="Open Internal Screen" ${data.actionType === 'Open Internal Screen' ? 'selected' : ''}>Open Internal Screen</option>
          <option value="No Action" ${data.actionType === 'No Action' ? 'selected' : ''}>No Action</option>
        </select>
      </div>
    </div>
    <div class="form-group" style="margin-bottom:0;">
      <label style="font-size:11px; margin-bottom:2px;">Action Value (Shop ID / Category ID / Screen Path)</label>
      <input type="text" class="si-action-value" value="${data.actionValue || ''}" placeholder="e.g. shop-123 or cleaning" style="padding: 6px; font-size:12px;">
    </div>
    <input type="hidden" class="si-id" value="${itemId}">
  `;
  container.appendChild(row);
}

function collectServiceItems() {
  const rows = document.querySelectorAll('.service-item-row');
  const items = [];
  rows.forEach(row => {
    const title = row.querySelector('.si-title')?.value?.trim();
    if (!title) return;
    items.push({
      id: row.querySelector('.si-id')?.value || `si-${Date.now()}`,
      title,
      imageUrl: row.querySelector('.si-image')?.value?.trim() || '',
      rating: parseFloat(row.querySelector('.si-rating')?.value) || 4.5,
      reviewsCount: row.querySelector('.si-reviews')?.value?.trim() || '',
      startingPrice: row.querySelector('.si-price')?.value?.trim() || '',
      actionType: row.querySelector('.si-action')?.value || 'Open Shop',
      actionValue: row.querySelector('.si-action-value')?.value?.trim() || ''
    });
  });
  return items;
}

function editCustomSection(id) {
  const sec = cmsCustomSections.find(s => s.id === id);
  if (!sec) return;

  document.getElementById('custom-section-modal-title').textContent = 'Edit Custom Section';
  document.getElementById('edit-custom-section-id').value = sec.id;
  document.getElementById('custom-section-title').value = sec.title;
  document.getElementById('custom-section-subtitle').value = sec.subtitle || '';
  document.getElementById('custom-section-banner-image').value = sec.bannerImageUrl || '';
  document.getElementById('custom-section-banner-badge').value = sec.bannerBadgeText || '';
  document.getElementById('custom-section-banner-action').value = sec.bannerActionType || 'Open Category';
  document.getElementById('custom-section-banner-value').value = sec.bannerActionValue || '';
  document.getElementById('custom-section-see-all-action').value = sec.seeAllActionType || 'Open Category';
  document.getElementById('custom-section-see-all-value').value = sec.seeAllActionValue || '';
  document.getElementById('custom-section-priority').value = sec.priority || 0;
  document.getElementById('custom-section-active').value = sec.isActive !== false ? 'true' : 'false';

  // Clear and populate service items
  const container = document.getElementById('service-items-container');
  container.innerHTML = '';
  (sec.serviceItems || []).forEach(item => addServiceItemRow(item));

  // Update banner preview
  const previewDiv = document.getElementById('custom-section-banner-preview');
  const previewImg = document.getElementById('custom-section-banner-img');
  const previewBadge = document.getElementById('custom-section-banner-badge-preview');
  const previewTitle = document.getElementById('custom-section-banner-title-preview');
  if (sec.bannerImageUrl) {
    previewDiv.style.display = 'block';
    previewImg.src = sec.bannerImageUrl;
    previewBadge.textContent = sec.bannerBadgeText || '';
    previewBadge.style.display = sec.bannerBadgeText ? 'inline-block' : 'none';
    previewTitle.textContent = sec.title;
  } else {
    previewDiv.style.display = 'none';
  }

  document.getElementById('custom-section-modal').classList.add('active');
}

async function deleteCustomSection(id) {
  if (!confirm('Delete this custom section? It will be removed from layouts and the application.')) return;
  try {
    const res = await fetch(`${API_URL}/custom-sections/${id}`, { method: 'DELETE' });
    const data = await res.json();
    if (data.success) {
      showToast('Custom section deleted', 'success');
      await logAdminActivity('Delete Custom Section', id, 'Deleted custom homepage section');
      await fetchCmsCustomSections();
      renderCustomSectionsList();
      await fetchCmsLayout();
      renderCmsLayout();
    } else {
      showToast(data.error || 'Delete failed', 'error');
    }
  } catch (e) {
    console.error(e);
    showToast('Failed to delete custom section', 'error');
  }
}

function setupCustomSectionEvents() {
  const addServiceItemBtn = document.getElementById('btn-add-service-item');
  if (addServiceItemBtn) {
    addServiceItemBtn.addEventListener('click', () => addServiceItemRow());
  }

  const addBtn = document.getElementById('btn-add-custom-section-modal');
  if (addBtn) {
    addBtn.addEventListener('click', () => {
      document.getElementById('custom-section-modal-title').textContent = 'Create Custom Section';
      document.getElementById('edit-custom-section-id').value = '';
      document.getElementById('custom-section-form').reset();
      document.getElementById('service-items-container').innerHTML = '';
      document.getElementById('custom-section-banner-preview').style.display = 'none';
      document.getElementById('custom-section-modal').classList.add('active');
    });
  }

  const form = document.getElementById('custom-section-form');
  if (form) {
    form.addEventListener('submit', async (e) => {
      e.preventDefault();
      const id = document.getElementById('edit-custom-section-id').value;
      const title = document.getElementById('custom-section-title').value;
      const subtitle = document.getElementById('custom-section-subtitle').value;
      const bannerImageUrl = document.getElementById('custom-section-banner-image').value;
      const bannerBadgeText = document.getElementById('custom-section-banner-badge').value;
      const bannerActionType = document.getElementById('custom-section-banner-action').value;
      const bannerActionValue = document.getElementById('custom-section-banner-value').value;
      const seeAllActionType = document.getElementById('custom-section-see-all-action').value;
      const seeAllActionValue = document.getElementById('custom-section-see-all-value').value;
      const priority = document.getElementById('custom-section-priority').value;
      const isActive = document.getElementById('custom-section-active').value === 'true';
      const serviceItems = collectServiceItems();

      const body = { id, title, subtitle, bannerImageUrl, bannerBadgeText, bannerActionType, bannerActionValue, seeAllActionType, seeAllActionValue, serviceItems, priority, isActive };

      try {
        const res = await fetch(`${API_URL}/custom-sections`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(body)
        });
        const data = await res.json();
        if (data.success) {
          showToast(id ? 'Custom section updated!' : 'Custom section created!', 'success');
          await logAdminActivity(id ? 'Edit Custom Section' : 'Create Custom Section', data.section.id, `Saved custom section: ${title}`);
          document.getElementById('custom-section-modal').classList.remove('active');
          await fetchCmsCustomSections();
          renderCustomSectionsList();
          await fetchCmsLayout();
          renderCmsLayout();
        } else {
          showToast('Failed to save section: ' + (data.error || 'Unknown error'), 'error');
        }
      } catch (err) {
        console.error(err);
        showToast('Failed to save custom section', 'error');
      }
    });
  }

  setupCustomSectionBannerPreview();
}

// Bindings
window.editCustomSection = editCustomSection;
window.deleteCustomSection = deleteCustomSection;
window.fetchCmsCustomSections = fetchCmsCustomSections;
window.renderCustomSectionsList = renderCustomSectionsList;
window.setupCustomSectionEvents = setupCustomSectionEvents;

