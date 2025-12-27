// Login logic for index.html
import { authAPI } from './api.js';

document.addEventListener('DOMContentLoaded', () => {
    checkAuth();
    setupEventListeners();
});

async function checkAuth() {
    const token = localStorage.getItem('auth_token');
    if (token) {
        try {
            const response = await authAPI.getMe();
            // Check if user is admin
            if (response.data && response.data.role === 'admin') {
                window.location.href = 'ingredients.html';
            } else {
                // Not admin, clear token and show login
                localStorage.removeItem('auth_token');
            }
        } catch (error) {
            localStorage.removeItem('auth_token');
            // Show login screen
        }
    }
}

function setupEventListeners() {
    const loginForm = document.getElementById('loginForm');
    const toggleSignUp = document.getElementById('toggleSignUp');
    const loginBtn = document.getElementById('loginBtn');
    const toast = document.getElementById('toast');

    if (loginForm) {
        loginForm.addEventListener('submit', handleLogin);
    }

    // Hide sign up option for admin panel
    if (toggleSignUp) {
        toggleSignUp.style.display = 'none';
    }

    async function handleLogin(e) {
        e.preventDefault();
        
        const emailInput = document.getElementById('email');
        const passwordInput = document.getElementById('password');
        
        if (!emailInput || !passwordInput) return;

        const email = emailInput.value.trim();
        const password = passwordInput.value;

        if (!email || !password) {
            showToast('Vui lòng nhập đầy đủ thông tin', 'error');
            return;
        }

        if (loginBtn) {
            loginBtn.disabled = true;
            loginBtn.textContent = 'Đang xử lý...';
        }

        try {
            // Use admin login endpoint
            const response = await authAPI.adminLogin(email, password);
            showToast('✅ Đăng nhập thành công!', 'success');
            // Redirect to ingredients page
            setTimeout(() => {
                window.location.href = 'ingredients.html';
            }, 500);
        } catch (error) {
            let errorMessage = error.message || 'Đăng nhập thất bại';
            if (error.message.includes('Admin')) {
                errorMessage = 'Tài khoản không có quyền Admin';
            }
            showToast(`❌ ${errorMessage}`, 'error');
        } finally {
            if (loginBtn) {
                loginBtn.disabled = false;
                loginBtn.textContent = 'Đăng nhập';
            }
        }
    }

    function showToast(message, type = 'success') {
        if (!toast) return;
        
        toast.textContent = message;
        toast.className = `toast ${type} show`;
        
        setTimeout(() => {
            toast.classList.remove('show');
        }, 3000);
    }
}

