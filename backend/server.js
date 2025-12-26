import express from "express";
import mongoose from "mongoose";
import cors from "cors";
import helmet from "helmet";
import morgan from "morgan";
import dotenv from "dotenv";
import { createServer } from "http";
import { Server } from "socket.io";
import { fileURLToPath } from "url";
import { dirname, join } from "path";

import authRoutes from "./routes/auth.routes.js";
import userRoutes from "./routes/user.routes.js";
import mealRoutes from "./routes/meal.routes.js";
import workoutRoutes from "./routes/workout.routes.js";
import categoryRoutes from "./routes/category.routes.js";
import collectionRoutes from "./routes/collection.routes.js";
import planExerciseRoutes from "./routes/plan_exercise.routes.js";
import planMealRoutes from "./routes/plan_meal.routes.js";
import equipmentRoutes from "./routes/equipment.routes.js";
import ingredientRoutes from "./routes/ingredient.routes.js";
import librarySectionRoutes from "./routes/library_section.routes.js";
import uploadRoutes from "./routes/upload.routes.js";
import recommendationRoutes from "./routes/recommendation.routes.js";

import { errorHandler } from "./middleware/errorHandler.middleware.js";

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

app.use(
  helmet({
    contentSecurityPolicy: false,
  })
);
app.use(
  cors({
    origin: process.env.CORS_ORIGIN || "*",
    credentials: true,
  })
);
app.use(morgan("dev"));
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true, limit: "10mb" }));

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

app.use("/admin", express.static(join(__dirname, "admin")));

app.use("/uploads", express.static(join(__dirname, "public", "uploads")));

app.get("/health", (req, res) => {
  res.json({
    status: "OK",
    message: "ViPT Backend API is running",
    timestamp: new Date().toISOString(),
  });
});

app.get("/favicon.ico", (req, res) => {
  res.status(204).end();
});

app.get("/admin", (req, res) => {
  res.sendFile(join(__dirname, "admin", "index.html"));
});

app.use("/api/auth", authRoutes);
app.use("/api/users", userRoutes);
app.use("/api/meals", mealRoutes);
app.use("/api/workouts", workoutRoutes);
app.use("/api/categories", categoryRoutes);
app.use("/api/collections", collectionRoutes);
app.use("/api/plan-exercises", planExerciseRoutes);
app.use("/api/plan-meals", planMealRoutes);
app.use("/api/equipment", equipmentRoutes);
app.use("/api/ingredients", ingredientRoutes);
app.use("/api/library-sections", librarySectionRoutes);
app.use("/api/upload", uploadRoutes);
app.use("/api/recommendations", recommendationRoutes);

io.on("connection", (socket) => {
  socket.on("join-user-room", (userId) => {
    socket.join(`user-${userId}`);
  });

  socket.on("leave-user-room", (userId) => {
    socket.leave(`user-${userId}`);
  });
});

app.set("io", io);

app.use(errorHandler);

app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: "Route not found",
  });
});

mongoose
  .connect(MONGODB_URI, {
    serverSelectionTimeoutMS: 5000,
  })
  .then(() => {
    console.log("Connected to MongoDB");

    httpServer.listen(PORT, () => {
      console.log(`Server is running on port ${PORT}`);
    });
  })
  .catch((error) => {
    console.error("MongoDB connection error:", error.message);
    process.exit(1);
  });

mongoose.connection.on("disconnected", () => {
  console.log("MongoDB disconnected");
});

mongoose.connection.on("error", (error) => {
  console.error("MongoDB error:", error);
});

process.on("SIGINT", async () => {
  console.log("\nShutting down gracefully...");
  await mongoose.connection.close();
  httpServer.close(() => {
    console.log("Server closed");
    process.exit(0);
  });
});

export default app;
