# Server Configuration

PORT=3000
NODE_ENV=development
API_BASE_URL=http://10.0.2.2:3000/api

# MongoDB Configuration - MongoDB Atlas

MONGODB_URI=mongodb+srv://longnguyenphuoc749_db_user:VRahgMWI5QpQhfmw@cluster0.tglxawn.mongodb.net/vipt?retryWrites=true&w=majority

# JWT Secret

JWT_SECRET=vipt-super-secret-jwt-key-change-this-in-production-2024
JWT_EXPIRE=7d

# CORS

# Cho phép tất cả origins (development) hoặc chỉ định cụ thể (production)

CORS_ORIGIN=\*

# File Upload (náº¿u dĂ¹ng local storage)

UPLOAD_PATH=./uploads
MAX_FILE_SIZE=5242880

# Gemini

GEMINI_API_KEY=AIzaSyAHBBmHzNVQN_U56IH6NQWRpoajgsufYQk

# Cloudinary

CLOUDINARY_CLOUD_NAME=daouokjft
CLOUDINARY_API_KEY=484939797711948
CLOUDINARY_API_SECRET=c9jQOQvOpF6oNyt6VVBCp_okquQ
CLOUDINARY_UPLOAD_PRESET=Fitness_uploads
