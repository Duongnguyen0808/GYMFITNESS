import express from "express";
import mongoose from "mongoose";
import cors from "cors";
import helmet from "helmet";
import morgan from "morgan";
import dotenv from "dotenv";
import { createServer } from "http";
import { Server } from "socket.io";

// Import routes
import authRoutes from "./routes/auth.routes.js";
import userRoutes from "./routes/user.routes.js";
import mealRoutes from "./routes/meal.routes.js";
import workoutRoutes from "./routes/workout.routes.js";
import categoryRoutes from "./routes/category.routes.js";
import collectionRoutes from "./routes/collection.routes.js";
import equipmentRoutes from "./routes/equipment.routes.js";
import ingredientRoutes from "./routes/ingredient.routes.js";
import librarySectionRoutes from "./routes/library_section.routes.js";

// Import error handler
import { errorHandler } from "./middleware/errorHandler.middleware.js";

// Load environment variables
dotenv.config();

const app = express();
const httpServer = createServer(app);
const io = new Server(httpServer, {
  cors: {
    origin: process.env.CORS_ORIGIN || "*",
    methods: ["GET", "POST", "PUT", "DELETE"],
  },
});

const PORT = process.env.PORT || 3000;
const MONGODB_URI = process.env.MONGODB_URI || "mongodb://localhost:27017/vipt";

// Middleware
app.use(helmet()); // Security headers
app.use(
  cors({
    origin: process.env.CORS_ORIGIN || "*",
    credentials: true,
  })
);
app.use(morgan("dev")); // Logging
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true, limit: "10mb" }));

// Health check
app.get("/health", (req, res) => {
  res.json({
    status: "OK",
    message: "ViPT Backend API is running",
    timestamp: new Date().toISOString(),
  });
});

// API Routes
app.use("/api/auth", authRoutes);
app.use("/api/users", userRoutes);
app.use("/api/meals", mealRoutes);
app.use("/api/workouts", workoutRoutes);
app.use("/api/categories", categoryRoutes);
app.use("/api/collections", collectionRoutes);
app.use("/api/equipment", equipmentRoutes);
app.use("/api/ingredients", ingredientRoutes);
app.use("/api/library-sections", librarySectionRoutes);

// Socket.io for real-time updates
io.on("connection", (socket) => {
  console.log("Client connected:", socket.id);

  socket.on("disconnect", () => {
    console.log("Client disconnected:", socket.id);
  });

  // Join room for specific user
  socket.on("join-user-room", (userId) => {
    socket.join(`user-${userId}`);
    console.log(`User ${userId} joined their room`);
  });

  // Leave room
  socket.on("leave-user-room", (userId) => {
    socket.leave(`user-${userId}`);
  });
});

// Make io accessible to routes
app.set("io", io);

// Error handling middleware (must be last)
app.use(errorHandler);

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: "Route not found",
  });
});

// Connect to MongoDB
mongoose
  .connect(MONGODB_URI, {
    serverSelectionTimeoutMS: 5000, // Timeout after 5s instead of 30s
  })
  .then(() => {
    console.log("✅ Connected to MongoDB");

    // Start server
    httpServer.listen(PORT, () => {
      console.log(`🚀 Server is running on port ${PORT}`);
      console.log(`📡 Environment: ${process.env.NODE_ENV || "development"}`);
      console.log(`🔗 Health check: http://localhost:${PORT}/health`);
    });
  })
  .catch((error) => {
    console.error("❌ MongoDB connection error:", error.message);
    
    // Provide helpful error messages
    if (error.message.includes('IP') || error.message.includes('whitelist')) {
      console.error("\n⚠️  LỖI: IP address của bạn chưa được whitelist trong MongoDB Atlas!");
      console.error("📝 Cách khắc phục:");
      console.error("   1. Truy cập: https://cloud.mongodb.com/");
      console.error("   2. Vào Network Access (hoặc IP Access List)");
      console.error("   3. Click 'Add IP Address'");
      console.error("   4. Chọn 'Add Current IP Address' hoặc nhập IP của bạn");
      console.error("   5. Hoặc chọn 'Allow Access from Anywhere' (0.0.0.0/0) - chỉ dùng cho development");
      console.error("\n💡 Tip: Kiểm tra MONGODB_URI trong file .env có đúng không?\n");
    } else if (error.message.includes('authentication')) {
      console.error("\n⚠️  LỖI: Sai username/password trong MongoDB connection string!");
      console.error("📝 Kiểm tra lại MONGODB_URI trong file .env\n");
    } else {
      console.error("\n⚠️  LỖI: Không thể kết nối đến MongoDB!");
      console.error("📝 Kiểm tra:");
      console.error("   - MONGODB_URI trong file .env");
      console.error("   - MongoDB Atlas cluster đang chạy");
      console.error("   - Internet connection\n");
    }
    
    process.exit(1);
  });

// Handle MongoDB connection events
mongoose.connection.on("disconnected", () => {
  console.log("⚠️ MongoDB disconnected");
});

mongoose.connection.on("error", (error) => {
  console.error("❌ MongoDB error:", error);
});

// Graceful shutdown
process.on("SIGINT", async () => {
  console.log("\n🛑 Shutting down gracefully...");
  await mongoose.connection.close();
  httpServer.close(() => {
    console.log("✅ Server closed");
    process.exit(0);
  });
});

export default app;
