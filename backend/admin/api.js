// API Base URL
const API_BASE_URL = '/api';

// Token management
const TOKEN_KEY = 'auth_token';

class ApiClient {
    constructor() {
        this.baseUrl = API_BASE_URL;
    }

    // Get token from localStorage
    getToken() {
        return localStorage.getItem(TOKEN_KEY);
    }

    // Save token to localStorage
    saveToken(token) {
        localStorage.setItem(TOKEN_KEY, token);
    }

    // Clear token
    clearToken() {
        localStorage.removeItem(TOKEN_KEY);
    }

    // Get headers with authentication
    getHeaders(includeAuth = true) {
        const headers = {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
        };

        if (includeAuth) {
            const token = this.getToken();
            if (token) {
                headers['Authorization'] = `Bearer ${token}`;
            }
        }

        return headers;
    }

    // Handle response
    async handleResponse(response) {
        const data = await response.json();
        
        if (!response.ok) {
            throw new Error(data.message || 'Request failed');
        }

        return data;
    }

    // GET request
    async get(endpoint, queryParams = null, includeAuth = true) {
        let url = `${this.baseUrl}${endpoint}`;
        
        if (queryParams) {
            const params = new URLSearchParams(queryParams);
            url += `?${params.toString()}`;
        }

        const response = await fetch(url, {
            method: 'GET',
            headers: this.getHeaders(includeAuth)
        });

        return this.handleResponse(response);
    }

    // POST request
    async post(endpoint, body = null, includeAuth = true) {
        const response = await fetch(`${this.baseUrl}${endpoint}`, {
            method: 'POST',
            headers: this.getHeaders(includeAuth),
            body: body ? JSON.stringify(body) : null
        });

        const result = await this.handleResponse(response);

        // Save token if it's a login/register response
        if (endpoint.includes('/auth/') && result.data?.token) {
            this.saveToken(result.data.token);
        }

        return result;
    }

    // PUT request
    async put(endpoint, body = null, includeAuth = true) {
        const response = await fetch(`${this.baseUrl}${endpoint}`, {
            method: 'PUT',
            headers: this.getHeaders(includeAuth),
            body: body ? JSON.stringify(body) : null
        });

        return this.handleResponse(response);
    }

    // DELETE request
    async delete(endpoint, includeAuth = true) {
        const response = await fetch(`${this.baseUrl}${endpoint}`, {
            method: 'DELETE',
            headers: this.getHeaders(includeAuth)
        });

        return this.handleResponse(response);
    }

    // Upload image
    async uploadImage(file, includeAuth = true) {
        const formData = new FormData();
        formData.append('image', file);

        const headers = {};
        if (includeAuth) {
            const token = this.getToken();
            if (token) {
                headers['Authorization'] = `Bearer ${token}`;
            }
        }
        // Don't set Content-Type for FormData, browser will set it automatically with boundary

        const response = await fetch(`${this.baseUrl}/upload/image`, {
            method: 'POST',
            headers: headers,
            body: formData
        });

        return this.handleResponse(response);
    }

    // Upload video
    async uploadVideo(file, includeAuth = true) {
        const formData = new FormData();
        formData.append('video', file);

        const headers = {};
        if (includeAuth) {
            const token = this.getToken();
            if (token) {
                headers['Authorization'] = `Bearer ${token}`;
            }
        }
        // Don't set Content-Type for FormData, browser will set it automatically with boundary

        const response = await fetch(`${this.baseUrl}/upload/video`, {
            method: 'POST',
            headers: headers,
            body: formData
        });

        return this.handleResponse(response);
    }
}

// Create singleton instance
const apiClient = new ApiClient();

// Auth API
export const authAPI = {
    login: (email, password) => apiClient.post('/auth/login', { email, password }, false),
    adminLogin: (email, password) => apiClient.post('/auth/admin/login', { email, password }, false),
    register: (email, password, name = 'Admin User', gender = 'other', dateOfBirth = new Date(), currentWeight = 70, currentHeight = 170, goalWeight = 65, activeFrequency = 'moderate') => 
        apiClient.post('/auth/register', { email, password, name, gender, dateOfBirth, currentWeight, currentHeight, goalWeight, activeFrequency }, false),
    createAdmin: (email, password, name) => apiClient.post('/auth/admin/create', { email, password, name }),
    getMe: () => apiClient.get('/auth/me'),
    logout: () => {
        apiClient.clearToken();
        return Promise.resolve();
    }
};

// Ingredients API
export const ingredientsAPI = {
    getAll: () => apiClient.get('/ingredients'),
    getById: (id) => apiClient.get(`/ingredients/${id}`),
    create: (data) => apiClient.post('/ingredients', data),
    update: (id, data) => apiClient.put(`/ingredients/${id}`, data),
    delete: (id) => apiClient.delete(`/ingredients/${id}`)
};

// Meals API
export const mealsAPI = {
    getAll: (categoryId = null) => {
        const params = categoryId ? { categoryId } : null;
        return apiClient.get('/meals', params);
    },
    getById: (id) => apiClient.get(`/meals/${id}`),
    create: (data) => apiClient.post('/meals', data),
    update: (id, data) => apiClient.put(`/meals/${id}`, data),
    delete: (id) => apiClient.delete(`/meals/${id}`)
};

// Equipment API
export const equipmentAPI = {
    getAll: () => apiClient.get('/equipment'),
    getById: (id) => apiClient.get(`/equipment/${id}`),
    create: (data) => apiClient.post('/equipment', data),
    update: (id, data) => apiClient.put(`/equipment/${id}`, data),
    delete: (id) => apiClient.delete(`/equipment/${id}`)
};

// Workouts API
export const workoutsAPI = {
    getAll: () => apiClient.get('/workouts'),
    getById: (id) => apiClient.get(`/workouts/${id}`),
    create: (data) => apiClient.post('/workouts', data),
    update: (id, data) => apiClient.put(`/workouts/${id}`, data),
    delete: (id) => apiClient.delete(`/workouts/${id}`)
};

// Categories API
export const categoriesAPI = {
    getAll: (type = null) => {
        const params = type ? { type } : null;
        return apiClient.get('/categories', params);
    },
    getById: (id) => apiClient.get(`/categories/${id}`),
    create: (data) => apiClient.post('/categories', data),
    update: (id, data) => apiClient.put(`/categories/${id}`, data),
    delete: (id) => apiClient.delete(`/categories/${id}`)
};

// Collections API
export const collectionsAPI = {
    // Workout Collections
    getWorkoutCollections: () => apiClient.get('/collections/workouts'),
    getWorkoutCollectionById: (id) => apiClient.get(`/collections/workouts/${id}`),
    createWorkoutCollection: (data) => apiClient.post('/collections/workouts', data),
    updateWorkoutCollection: (id, data) => apiClient.put(`/collections/workouts/${id}`, data),
    deleteWorkoutCollection: (id) => apiClient.delete(`/collections/workouts/${id}`),
    
    // Meal Collections
    getMealCollections: () => apiClient.get('/collections/meals'),
    getMealCollectionById: (id) => apiClient.get(`/collections/meals/${id}`),
    createMealCollection: (data) => apiClient.post('/collections/meals', data),
    updateMealCollection: (id, data) => apiClient.put(`/collections/meals/${id}`, data),
    deleteMealCollection: (id) => apiClient.delete(`/collections/meals/${id}`)
};

// Plan Exercise Collections API
export const planExerciseAPI = {
    getCollections: (planID = 0) => apiClient.get(`/plan-exercises/collections?planID=${planID}`),
    getCollectionById: (id) => apiClient.get(`/plan-exercises/collections/${id}`),
    createCollection: (data) => apiClient.post('/plan-exercises/collections', data),
    updateCollection: (id, data) => apiClient.put(`/plan-exercises/collections/${id}`, data),
    deleteCollection: (id) => apiClient.delete(`/plan-exercises/collections/${id}`),
    getExercises: (listID) => apiClient.get(`/plan-exercises?listID=${listID}`)
};

// Plan Meal Collections API
export const planMealAPI = {
    getCollections: (planID = 0) => apiClient.get(`/plan-meals/collections?planID=${planID}`),
    getCollectionById: (id) => apiClient.get(`/plan-meals/collections/${id}`),
    createCollection: (data) => apiClient.post('/plan-meals/collections', data),
    updateCollection: (id, data) => apiClient.put(`/plan-meals/collections/${id}`, data),
    deleteCollection: (id) => apiClient.delete(`/plan-meals/collections/${id}`),
    getMeals: (listID) => apiClient.get(`/plan-meals?listID=${listID}`)
};

// Library Sections API
export const librarySectionsAPI = {
    getAll: () => apiClient.get('/library-sections'),
    getById: (id) => apiClient.get(`/library-sections/${id}`),
    create: (data) => apiClient.post('/library-sections', data),
    update: (id, data) => apiClient.put(`/library-sections/${id}`, data),
    delete: (id) => apiClient.delete(`/library-sections/${id}`)
};

// Upload API
export const uploadAPI = {
    uploadImage: (file) => apiClient.uploadImage(file),
    uploadVideo: (file) => apiClient.uploadVideo(file)
};

