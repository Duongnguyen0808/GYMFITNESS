import express from "express";
import uploadToCloudinary from "../utils/uploadCloudinary.js";
import cloudinary from "../config/cloudinary.js";
import { protect } from "../middleware/auth.middleware.js";

const router = express.Router();

// Error handler middleware cho multer
const handleMulterError = (err, req, res, next) => {
  if (err) {
    if (err.code === "LIMIT_FILE_SIZE") {
      return res.status(400).json({
        success: false,
        message: "File quá lớn. Vui lòng chọn file nhỏ hơn 15MB",
      });
    }
    return res.status(400).json({
      success: false,
      message: err.message || "Lỗi khi upload file",
    });
  }
  next();
};

// Helper function để upload buffer lên Cloudinary
const uploadBufferToCloudinary = (buffer, options = {}) => {
  return new Promise((resolve, reject) => {
    const uploadStream = cloudinary.uploader.upload_stream(
      {
        folder: "vipt_uploads",
        resource_type: "auto",
        ...options,
      },
      (error, result) => {
        if (error) reject(error);
        else resolve(result);
      }
    );

    uploadStream.end(buffer);
  });
};

// Upload single image lên Cloudinary
router.post(
  "/image",
  protect,
  uploadToCloudinary.single("image"),
  handleMulterError,
  async (req, res) => {
    try {
      console.log("Upload request received");
      console.log("req.file:", req.file);
      console.log("req.body:", req.body);
      
      if (!req.file) {
        console.log("No file uploaded");
        return res.status(400).json({
          success: false,
          message: "Không có file được upload",
        });
      }

      // Upload lên Cloudinary
      const result = await uploadBufferToCloudinary(req.file.buffer, {
        resource_type: "image",
        transformation: [{ quality: "auto" }, { fetch_format: "auto" }],
      });

      // Trả về URL từ Cloudinary (URL đầy đủ, có thể truy cập từ mọi nơi)
      res.json({
        success: true,
        data: {
          url: result.secure_url,
          public_id: result.public_id,
          filename: req.file.originalname,
          originalname: req.file.originalname,
          size: req.file.size,
          format: result.format,
          width: result.width,
          height: result.height,
        },
      });
    } catch (error) {
      console.error("Cloudinary upload error:", error);
      res.status(500).json({
        success: false,
        message: error.message || "Lỗi khi upload file lên Cloudinary",
      });
    }
  }
);

// Upload single video lên Cloudinary
router.post(
  "/video",
  protect,
  uploadToCloudinary.single("video"),
  handleMulterError,
  async (req, res) => {
    try {
      if (!req.file) {
        return res.status(400).json({
          success: false,
          message: "Không có file được upload",
        });
      }

      // Upload video lên Cloudinary
      const result = await uploadBufferToCloudinary(req.file.buffer, {
        resource_type: "video",
        chunk_size: 6000000, // 6MB chunks for large videos
      });

      // Trả về URL từ Cloudinary
      res.json({
        success: true,
        data: {
          url: result.secure_url,
          public_id: result.public_id,
          filename: req.file.originalname,
          originalname: req.file.originalname,
          size: req.file.size,
          format: result.format,
          duration: result.duration,
        },
      });
    } catch (error) {
      console.error("Cloudinary video upload error:", error);

      // Xử lý lỗi file quá lớn
      if (error.http_code === 413 || error.message?.includes("too large")) {
        return res.status(400).json({
          success: false,
          message: "File quá lớn. Vui lòng chọn file video nhỏ hơn 100MB",
        });
      }

      res.status(500).json({
        success: false,
        message: error.message || "Lỗi khi upload video lên Cloudinary",
      });
    }
  }
);

export default router;
