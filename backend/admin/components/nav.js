// Navigation component - có thể được include vào các trang
export function renderNavigation(currentPage = '') {
    const pages = [
        { id: 'ingredients', name: 'Nguyên liệu', icon: 'M3 2v7c0 1.1.9 2 2 2h4a2 2 0 002-2V2M3 2h18M3 2l9 9 9-9' },
        { id: 'meals', name: 'Món ăn', icon: 'M6 13h12M6 13a2 2 0 100-4h12a2 2 0 100 4M6 13v6a2 2 0 002 2h8a2 2 0 002-2v-6M9 9V7a2 2 0 012-2h2a2 2 0 012 2v2' },
        { id: 'equipment', name: 'Thiết bị', icon: 'M6.5 6.5h11v11h-11zM12 2v4M12 18v4M2 12h4M18 12h4' },
        { id: 'workouts', name: 'Bài tập', icon: 'M6 9l6 6 6-6' },
        { id: 'workout-categories', name: 'DM Bài tập', icon: 'M4 7h16M4 12h16M4 17h16' },
        { id: 'meal-categories', name: 'DM Món ăn', icon: 'M3 2v7c0 1.1.9 2 2 2h4a2 2 0 002-2V2' },
        { id: 'library-sections', name: 'Thư viện', icon: 'M4 19.5A2.5 2.5 0 016.5 17H20M6.5 2H20v20H6.5A2.5 2.5 0 014 19.5v-15A2.5 2.5 0 016.5 2z' },
        { id: 'workout-plans', name: 'DS Bài tập', icon: 'M9 11l3 3L22 4M21 12v7a2 2 0 01-2 2H5a2 2 0 01-2-2V5a2 2 0 012-2h11' },
        { id: 'meal-plans', name: 'DS Món ăn', icon: 'M9 11l3 3L22 4M21 12v7a2 2 0 01-2 2H5a2 2 0 01-2-2V5a2 2 0 012-2h11' }
    ];

    const navItems = pages.map(page => `
        <a href="${page.id}.html" class="nav-item ${currentPage === page.id ? 'active' : ''}">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="${page.icon}"/>
            </svg>
            <span>${page.name}</span>
        </a>
    `).join('');

    return `
        <nav class="sidebar">
            <div class="sidebar-header">
                <div class="sidebar-icon">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/>
                    </svg>
                </div>
                <h2>ViPT Admin</h2>
            </div>
            <div class="nav-menu">
                ${navItems}
            </div>
        </nav>
    `;
}

export function renderHeader() {
    return `
        <header class="admin-header">
            <div class="header-content">
                <div class="header-left">
                    <h1 id="pageTitle">Quản lý Dữ liệu</h1>
                </div>
                <div class="header-right">
                    <button id="syncAllBtn" class="btn-secondary">Đồng bộ tất cả</button>
                    <div class="user-menu">
                        <button id="userMenuBtn" class="user-menu-btn">
                            <span id="userName">Admin</span>
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M19 9l-7 7-7-7"/>
                            </svg>
                        </button>
                        <div id="userDropdown" class="user-dropdown" style="display: none;">
                            <a href="#" id="logoutBtn">Đăng xuất</a>
                        </div>
                    </div>
                </div>
            </div>
        </header>
    `;
}

