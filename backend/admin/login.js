// Login logic for index.html
import { authAPI } from './api.js';

let isSignUp = false;

document.addEventListener('DOMContentLoaded', () => {
    checkAuth();
    setupEventListeners();
});

async function checkAuth() {
    const token = localStorage.getItem('auth_token');
    if (token) {
        try {
            const response = await authAPI.getMe();
            // Redirect to ingredients page if already logged in
            window.location.href = 'ingredients.html';
        } catch (error) {
            localStorage.removeItem('auth_token');
            // Show login screen
        }
    }
}

function setupEventListeners() {
    const loginForm = document.getElementById('loginForm');
    const toggleSignUp = document.getElementById('toggleSignUp');
    const loginSubtitle = document.getElementById('loginSubtitle');
    const loginBtn = document.getElementById('loginBtn');
    const toast = document.getElementById('toast');

    if (loginForm) {
        loginForm.addEventListener('submit', handleLogin);
    }

    if (toggleSignUp) {
        toggleSignUp.addEventListener('click', (e) => {
            e.preventDefault();
            toggleSignUpMode();
        });
    }

    function toggleSignUpMode() {
        isSignUp = !isSignUp;
        if (loginSubtitle) {
            loginSubtitle.textContent = isSignUp ? 'Tạo tài khoản Admin' : 'Đăng nhập Admin';
        }
        if (loginBtn) {
            loginBtn.textContent = isSignUp ? 'Tạo tài khoản' : 'Đăng nhập';
        }
        if (toggleSignUp) {
            toggleSignUp.textContent = isSignUp ? 'Đã có tài khoản? Đăng nhập' : 'Chưa có tài khoản? Tạo mới';
        }
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
            let response;
            if (isSignUp) {
                response = await authAPI.register(email, password);
                showToast('✅ Tạo tài khoản thành công!', 'success');
                // Auto login after register
                setTimeout(() => {
                    window.location.href = 'ingredients.html';
                }, 1000);
            } else {
                response = await authAPI.login(email, password);
                showToast('✅ Đăng nhập thành công!', 'success');
                // Redirect to ingredients page
                setTimeout(() => {
                    window.location.href = 'ingredients.html';
                }, 500);
            }
        } catch (error) {
            showToast(`❌ ${error.message || 'Đăng nhập thất bại'}`, 'error');
        } finally {
            if (loginBtn) {
                loginBtn.disabled = false;
                loginBtn.textContent = isSignUp ? 'Tạo tài khoản' : 'Đăng nhập';
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

