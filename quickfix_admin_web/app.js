const API_URL = 'http://localhost:3000/api';

// State variables
let shops = [];
let bookings = [];
let banners = [];
let offers = [];
let alerts = [];

// DOM Elements
const navItems = document.querySelectorAll('.nav-item');
const tabPanes = document.querySelectorAll('.tab-pane');
const tabTitle = document.getElementById('tab-title');

// Initial Load
document.addEventListener('DOMContentLoaded', () => {
  setupTabs();
  setupModals();
  setupForms();
  setupServicesEvents();
  
  const statusFilter = document.getElementById('booking-filter-status');
  if (statusFilter) {
    statusFilter.addEventListener('change', renderManageBookingsTable);
  }
  
  refreshAllData();
  
  // Refresh loop every 5 seconds to get real-time bookings
  setInterval(refreshAllData, 5000);
});

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
      
      // Update title text
      tabTitle.textContent = item.textContent.trim();

      // Auto-load demands when switching to that tab
      if (tabId === 'demand-tab') {
        loadDemands();
      }
    });
  });
}

// Setup modals opening/closing
function setupModals() {
  // Banner modal
  document.getElementById('btn-add-banner-modal').addEventListener('click', () => {
    document.getElementById('banner-modal').classList.add('active');
  });
  
  // Offer modal
  document.getElementById('btn-add-offer-modal').addEventListener('click', () => {
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

// Refresh all data collections
async function refreshAllData() {
  await Promise.all([
    fetchShops(),
    fetchBookings(),
    fetchBanners(),
    fetchOffers(),
    fetchAlerts()
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
    const res = await fetch(`${API_URL}/shops`);
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

// Update dashboard header stats
function updateDashboardStats() {
  document.getElementById('stat-shops').textContent = shops.length;
  document.getElementById('stat-bookings').textContent = bookings.length;
  document.getElementById('stat-offers').textContent = offers.filter(o => o.isActive).length;
  document.getElementById('stat-alerts').textContent = alerts.length;
}

// Render dynamic tables
function renderBookingsTable() {
  const tbody = document.getElementById('bookings-tbody');
  tbody.innerHTML = '';
  
  if (bookings.length === 0) {
    tbody.innerHTML = '<tr><td colspan="6" style="text-align:center;color:var(--text-secondary);">No active bookings streaming...</td></tr>';
    return;
  }
  
  bookings.forEach(b => {
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td>${b.id}</td>
      <td>${b.customerName}</td>
      <td>${b.providerName}</td>
      <td style="color:var(--primary);">₹${b.amount}</td>
      <td>${new Date(b.date).toLocaleDateString('en-GB')} • ${b.slot}</td>
      <td><span class="badge badge-${b.status}">${b.status.replace('_', ' ')}</span></td>
    `;
    tbody.appendChild(tr);
  });
}

// Render active registered shops list
function renderShopsList() {
  const container = document.getElementById('shops-list');
  container.innerHTML = '';
  
  if (shops.length === 0) {
    container.innerHTML = '<p style="text-align:center;color:var(--text-secondary);padding:20px;">No registered shops found.</p>';
    return;
  }
  
  shops.forEach(s => {
    const div = document.createElement('div');
    div.className = 'shop-list-item';
    div.innerHTML = `
      <div class="shop-info">
        <h4>${s.name}</h4>
        <p>Owner: ${s.ownerName} • Phone: ${s.phone} • ID: ${s.id}</p>
        <p style="font-size:11px;color:var(--primary);margin-top:4px;">Coords: ${s.latitude}, ${s.longitude} • Cats: ${s.categories.join(', ')}</p>
      </div>
      <div class="shop-actions">
        <div class="toggle-switch" style="border-top:none; padding-top:0; gap:8px;">
          <span>Online</span>
          <label class="switch">
            <input type="checkbox" ${s.isOnline ? 'checked' : ''} onchange="toggleShopOnline('${s.id}', ${!s.isOnline})">
            <span class="slider"></span>
          </label>
        </div>
        <button class="btn btn-secondary btn-sm" onclick="openServicesModal('${s.id}')"><i class="fa-solid fa-gears"></i> Services</button>
        <button class="btn btn-danger btn-sm btn-icon btn-delete" onclick="deleteShop('${s.id}')" title="Delete Shop"><i class="fa-solid fa-trash-can"></i></button>
      </div>
    `;
    container.appendChild(div);
  });
}

// Render banners grid
function renderBannersGrid() {
  const grid = document.getElementById('banners-grid');
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
        <p>Code: ${b.code} • Ribbon: ${b.percent}</p>
      </div>
      <div class="toggle-switch">
        <div style="display:flex; align-items:center; gap:8px;">
          <span>Active State</span>
          <label class="switch">
            <input type="checkbox" ${b.isActive ? 'checked' : ''} onchange="toggleBanner('${b.id}')">
            <span class="slider"></span>
          </label>
        </div>
        <button class="btn btn-icon btn-delete" onclick="deleteBanner('${b.id}')" title="Delete Banner" style="padding: 4px; font-size:12px; color:var(--danger);"><i class="fa-solid fa-trash-can"></i></button>
      </div>
    `;
    grid.appendChild(div);
  });
}

// Render offers coupons grid
function renderOffersGrid() {
  const grid = document.getElementById('offers-grid');
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
        <h4>Code: ${o.code}</h4>
        <p><strong>${o.title}</strong></p>
        <p>${o.description}</p>
      </div>
      <div class="toggle-switch">
        <div style="display:flex; align-items:center; gap:8px;">
          <span>Active State</span>
          <label class="switch">
            <input type="checkbox" ${o.isActive ? 'checked' : ''} onchange="toggleOffer('${o.code}')">
            <span class="slider"></span>
          </label>
        </div>
        <button class="btn btn-icon btn-delete" onclick="deleteOffer('${o.code}')" title="Delete Offer" style="padding: 4px; font-size:12px; color:var(--danger);"><i class="fa-solid fa-trash-can"></i></button>
      </div>
    `;
    grid.appendChild(div);
  });
}

// Render alerts notifications history
function renderAlertsHistory() {
  const container = document.getElementById('alerts-history');
  container.innerHTML = '';
  
  if (alerts.length === 0) {
    container.innerHTML = '<p style="text-align:center;color:var(--text-secondary);padding:20px;">No notifications broadcasted yet.</p>';
    return;
  }
  
  alerts.forEach(a => {
    const div = document.createElement('div');
    div.className = 'alert-history-item';
    div.innerHTML = `
      <h4>${a.title} <span>${a.time}</span></h4>
      <p>${a.body}</p>
    `;
    container.appendChild(div);
  });
}

// Actions handlers
async function toggleBanner(id) {
  try {
    await fetch(`${API_URL}/banners/toggle`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id })
    });
    refreshAllData();
  } catch (e) {
    console.error('Error toggling banner:', e);
  }
}

async function toggleOffer(code) {
  try {
    await fetch(`${API_URL}/offers/toggle`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ code })
    });
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
    
    const bodyData = {
      name: document.getElementById('shop-name').value,
      ownerName: document.getElementById('owner-name').value,
      phone: document.getElementById('shop-phone').value,
      password: document.getElementById('shop-password').value,
      latitude: parseFloat(document.getElementById('shop-lat').value),
      longitude: parseFloat(document.getElementById('shop-lng').value),
      address: document.getElementById('shop-address').value,
      serviceRadius: parseFloat(document.getElementById('shop-radius').value) || 5.0,
      visitingCharges: parseFloat(document.getElementById('shop-visiting-charges').value) || 150,
      timings: document.getElementById('shop-timings').value,
      verificationStatus: document.getElementById('shop-verification').value,
      status: 'active',
      isOpen: true,
      categories: checkedCats
    };
    
    try {
      const res = await fetch(`${API_URL}/shops/register`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(bodyData)
      });
      const data = await res.json();
      if (data.success) {
        alert(`Shop "${bodyData.name}" registered successfully!\nID: ${data.shop.id}\nPassword: ${bodyData.password}`);
        document.getElementById('shop-form').reset();
        refreshAllData();
      }
    } catch (err) {
      console.error('Error registering shop:', err);
    }
  });
  
  // 2. Add Banner Form
  document.getElementById('banner-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const bodyData = {
      title: document.getElementById('banner-title').value,
      code: document.getElementById('banner-code').value,
      percent: document.getElementById('banner-percent').value,
      imageUrl: document.getElementById('banner-image').value
    };
    
    try {
      await fetch(`${API_URL}/banners`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(bodyData)
      });
      document.getElementById('banner-modal').classList.remove('active');
      document.getElementById('banner-form').reset();
      refreshAllData();
    } catch (err) {
      console.error('Error creating banner:', err);
    }
  });

  // 3. Add Offer Form
  document.getElementById('offer-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const bodyData = {
      code: document.getElementById('offer-code').value,
      title: document.getElementById('offer-title').value,
      description: document.getElementById('offer-desc').value
    };
    
    try {
      await fetch(`${API_URL}/offers`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(bodyData)
      });
      document.getElementById('offer-modal').classList.remove('active');
      document.getElementById('offer-form').reset();
      refreshAllData();
    } catch (err) {
      console.error('Error creating offer:', err);
    }
  });

  // 4. Send Broadcast Form
  document.getElementById('broadcast-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const bodyData = {
      title: document.getElementById('alert-title').value,
      body: document.getElementById('alert-body').value,
      icon: document.getElementById('alert-icon').value
    };
    
    try {
      await fetch(`${API_URL}/notifications/send`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(bodyData)
      });
      document.getElementById('broadcast-form').reset();
      refreshAllData();
      alert('Broadcast notification sent successfully!');
    } catch (err) {
      console.error('Error sending broadcast:', err);
    }
  });
}

// --- NEW ACTION HANDLERS & ENHANCEMENTS ---

// Delete Shop
async function deleteShop(id) {
  const shop = shops.find(s => s.id === id);
  if (!shop) return;
  if (confirm(`Are you sure you want to delete the shop "${shop.name}"? This action cannot be undone.`)) {
    try {
      const res = await fetch(`${API_URL}/shops/${id}`, {
        method: 'DELETE'
      });
      const data = await res.json();
      if (data.success) {
        alert('Shop deleted successfully!');
        refreshAllData();
      } else {
        alert('Failed to delete shop: ' + (data.error || 'Unknown error'));
      }
    } catch (e) {
      console.error('Error deleting shop:', e);
      alert('Error connecting to backend.');
    }
  }
}

// Toggle Shop Online/Offline
async function toggleShopOnline(id, nextState) {
  try {
    const res = await fetch(`${API_URL}/shops/update`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id, isOnline: nextState })
    });
    const data = await res.json();
    if (data.success) {
      refreshAllData();
    } else {
      alert('Failed to update shop status.');
    }
  } catch (e) {
    console.error('Error toggling shop status:', e);
  }
}

// Delete Banner
async function deleteBanner(id) {
  if (confirm('Are you sure you want to delete this banner?')) {
    try {
      const res = await fetch(`${API_URL}/banners/${id}`, { method: 'DELETE' });
      const data = await res.json();
      if (data.success) {
        refreshAllData();
      }
    } catch (e) {
      console.error('Error deleting banner:', e);
    }
  }
}

// Delete Offer
async function deleteOffer(code) {
  if (confirm(`Are you sure you want to delete coupon code "${code}"?`)) {
    try {
      const res = await fetch(`${API_URL}/offers/${code}`, { method: 'DELETE' });
      const data = await res.json();
      if (data.success) {
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
    tbody.innerHTML = '<tr><td colspan="7" style="text-align:center;color:var(--text-secondary);padding:20px;">No bookings match the filter criteria.</td></tr>';
    return;
  }
  
  filteredBookings.forEach(b => {
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td>${b.id}</td>
      <td>
        <div style="font-weight:700;">${b.customerName}</div>
        <div style="font-size:11px;color:var(--text-secondary);">${b.customerPhone} • ${b.customerAddress}</div>
      </td>
      <td>
        <div style="font-weight:700;">${b.providerName}</div>
        <div style="font-size:11px;color:var(--text-secondary);">Shop ID: ${b.shopId}</div>
      </td>
      <td style="color:var(--primary);font-weight:700;">₹${b.amount}</td>
      <td>${new Date(b.date).toLocaleDateString('en-GB')} • ${b.slot}</td>
      <td><span class="badge badge-${b.status}">${b.status.replace('_', ' ')}</span></td>
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
      refreshAllData();
    } else {
      alert('Failed to update booking status: ' + (data.error || 'Server error'));
      refreshAllData();
    }
  } catch (e) {
    console.error('Error changing booking status:', e);
    alert('Error connecting to backend.');
    refreshAllData();
  }
}

// --- SERVICE MANAGEMENT MODAL LOGIC ---

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
    
    div.innerHTML = `
      <img src="${imgUrl}" alt="${srv.title}">
      <div class="service-item-details">
        <h5>${srv.title}</h5>
        <p>₹${srv.price} <span style="text-decoration:line-through;color:var(--text-secondary);font-size:10px;margin-left:4px;">₹${srv.originalPrice}</span> • ${srv.durationText}</p>
      </div>
      <div class="service-item-actions">
        <button class="btn-icon" onclick="moveService(${idx}, -1)" title="Move Up" ${idx === 0 ? 'disabled style="opacity:0.3;cursor:not-allowed;"' : ''}>
          <i class="fa-solid fa-arrow-up"></i>
        </button>
        <button class="btn-icon" onclick="moveService(${idx}, 1)" title="Move Down" ${idx === tempServicesList.length - 1 ? 'disabled style="opacity:0.3;cursor:not-allowed;"' : ''}>
          <i class="fa-solid fa-arrow-down"></i>
        </button>
        <button class="btn-icon" onclick="loadServiceForEdit('${srv.id}')" title="Edit Service">
          <i class="fa-solid fa-pen-to-square"></i>
        </button>
        <button class="btn-icon btn-delete" onclick="deleteService('${srv.id}')" title="Delete Service">
          <i class="fa-solid fa-trash-can"></i>
        </button>
      </div>
    `;
    container.appendChild(div);
  });
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
  document.getElementById('srv-price').value = srv.price;
  document.getElementById('srv-original-price').value = srv.originalPrice;
  document.getElementById('srv-duration').value = srv.durationText;
  document.getElementById('srv-image').value = srv.imageUrl || '';
  document.getElementById('srv-bullets').value = (srv.bulletPoints || []).join('\n');
  
  document.getElementById('btn-cancel-edit-service').style.display = 'inline-flex';
}

function resetServiceForm() {
  document.getElementById('service-form-title').textContent = "Add New Service";
  document.getElementById('edit-service-id').value = "";
  document.getElementById('service-edit-form').reset();
  document.getElementById('btn-cancel-edit-service').style.display = 'none';
}

function setupServicesEvents() {
  document.getElementById('btn-cancel-edit-service').addEventListener('click', resetServiceForm);
  
  document.getElementById('service-edit-form').addEventListener('submit', (e) => {
    e.preventDefault();
    
    const srvId = document.getElementById('edit-service-id').value;
    const title = document.getElementById('srv-title').value;
    const price = parseFloat(document.getElementById('srv-price').value);
    const originalPrice = parseFloat(document.getElementById('srv-original-price').value);
    const durationText = document.getElementById('srv-duration').value;
    const imageUrl = document.getElementById('srv-image').value || 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=300';
    
    const bulletsRaw = document.getElementById('srv-bullets').value;
    const bulletPoints = bulletsRaw.split('\n').map(b => b.trim()).filter(b => b.length > 0);
    
    if (srvId) {
      const idx = tempServicesList.findIndex(s => s.id === srvId);
      if (idx !== -1) {
        tempServicesList[idx] = {
          ...tempServicesList[idx],
          title,
          price,
          originalPrice,
          durationText,
          imageUrl,
          bulletPoints
        };
      }
    } else {
      const newSrv = {
        id: `srv-${Date.now()}`,
        title,
        price,
        originalPrice,
        rating: 5.0,
        reviewsCount: 0,
        durationText,
        bulletPoints,
        imageUrl
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
        alert('Shop services updated successfully!');
        document.getElementById('services-modal').classList.remove('active');
        refreshAllData();
      } else {
        alert('Failed to save shop services: ' + (data.error || 'Server error'));
      }
    } catch (e) {
      console.error('Error saving services:', e);
      alert('Network error while saving services.');
    }
  });
}

// Bind handlers globally for dynamic HTML events
window.openServicesModal = openServicesModal;
window.deleteShop = deleteShop;
window.toggleShopOnline = toggleShopOnline;
window.deleteBanner = deleteBanner;
window.deleteOffer = deleteOffer;
window.moveService = moveService;
window.loadServiceForEdit = loadServiceForEdit;
window.deleteService = deleteService;
window.changeBookingStatus = changeBookingStatus;
window.renderManageBookingsTable = renderManageBookingsTable;
window.loadDemands = loadDemands;

// Load customer demand submissions from backend
async function loadDemands() {
  const tbody = document.getElementById('demand-tbody');
  if (!tbody) return;
  tbody.innerHTML = '<tr><td colspan="5" style="text-align:center;color:var(--text-muted);padding:24px;"><i class="fa-solid fa-spinner fa-spin"></i> Loading...</td></tr>';

  try {
    const res = await fetch(`${API_URL}/demand`);
    const demands = await res.json();

    if (!Array.isArray(demands) || demands.length === 0) {
      tbody.innerHTML = '<tr><td colspan="5" style="text-align:center;color:var(--text-muted);padding:24px;">No customer demand submissions yet.</td></tr>';
      return;
    }

    tbody.innerHTML = '';
    demands.forEach((d, index) => {
      const date = d.createdAt ? new Date(d.createdAt).toLocaleString('en-IN') : 'N/A';
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td style="color:var(--text-muted);font-size:12px;">${index + 1}</td>
        <td style="font-weight:700;">${d.phone || 'N/A'}</td>
        <td style="font-size:13px;">${d.address || 'N/A'}</td>
        <td style="font-size:12px;color:var(--text-muted);">${(d.latitude || 0).toFixed(4)}, ${(d.longitude || 0).toFixed(4)}</td>
        <td style="font-size:12px;color:var(--text-muted);">${date}</td>
      `;
      tbody.appendChild(tr);
    });
  } catch (e) {
    tbody.innerHTML = '<tr><td colspan="5" style="text-align:center;color:var(--danger);padding:24px;">Failed to load demand data. Ensure the backend server is running.</td></tr>';
    console.error('Error loading demands:', e);
  }
}
