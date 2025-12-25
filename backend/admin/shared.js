// Shared functionality across all pages
import { authAPI } from './api.js';

let currentUser = null;

// Check authentication
export async function checkAuth() {
    const token = localStorage.getItem('auth_token');
    if (!token) {
        window.location.href = 'index.html';
        return false;
    }
    
    try {
        const response = await authAPI.getMe();
        currentUser = response.data;
        if (document.getElementById('userName')) {
            document.getElementById('userName').textContent = currentUser.name || currentUser.email || 'Admin';
        }
        return true;
    } catch (error) {
        localStorage.removeItem('auth_token');
        window.location.href = 'index.html';
        return false;
    }
}

// Setup header event listeners
export function setupHeaderListeners() {
    const logoutBtn = document.getElementById('logoutBtn');
    const userMenuBtn = document.getElementById('userMenuBtn');
    const userDropdown = document.getElementById('userDropdown');
    const syncAllBtn = document.getElementById('syncAllBtn');

    if (logoutBtn) {
        logoutBtn.addEventListener('click', async (e) => {
            e.preventDefault();
            await authAPI.logout();
            window.location.href = 'index.html';
        });
    }

    if (userMenuBtn) {
        userMenuBtn.addEventListener('click', () => {
            userDropdown.style.display = userDropdown.style.display === 'none' ? 'block' : 'none';
        });
    }

    if (syncAllBtn) {
        syncAllBtn.addEventListener('click', () => {
            showToast('✅ Dữ liệu đã được cập nhật trên server. Mobile app sẽ tự động đồng bộ khi khởi động lại.', 'success');
        });
    }

    // Close dropdown when clicking outside
    document.addEventListener('click', (e) => {
        if (userMenuBtn && userDropdown && !userMenuBtn.contains(e.target) && !userDropdown.contains(e.target)) {
            userDropdown.style.display = 'none';
        }
    });
}

// Show/Hide Loading
export function showLoading() {
    const loadingOverlay = document.getElementById('loadingOverlay');
    if (loadingOverlay) {
        loadingOverlay.style.display = 'flex';
    }
}

export function hideLoading() {
    const loadingOverlay = document.getElementById('loadingOverlay');
    if (loadingOverlay) {
        loadingOverlay.style.display = 'none';
    }
}

// Show Toast
export function showToast(message, type = 'success') {
    const toast = document.getElementById('toast');
    if (!toast) return;
    
    toast.textContent = message;
    toast.className = `toast ${type} show`;
    
    setTimeout(() => {
        toast.classList.remove('show');
    }, 3000);
}

// Modal Functions
export function openModal(title) {
    const modal = document.getElementById('modal');
    const modalTitle = document.getElementById('modalTitle');
    if (modal) modal.style.display = 'flex';
    if (modalTitle) modalTitle.textContent = title;
}

export function closeModalDialog() {
    const modal = document.getElementById('modal');
    const modalBody = document.getElementById('modalBody');
    if (modal) modal.style.display = 'none';
    if (modalBody) modalBody.innerHTML = '';
}

// Make functions available globally for onclick handlers
window.showToast = showToast;
window.closeModalDialog = closeModalDialog;

