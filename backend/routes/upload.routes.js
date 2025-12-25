import express from 'express';
import upload from '../utils/upload.js';
import uploadVideo from '../utils/uploadVideo.js';
import { protect } from '../middleware/auth.middleware.js';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const router = express.Router();

// Error handler middleware cho multer
const handleMulterError = (err, req, res, next) => {
  if (err) {
    if (err.code === 'LIMIT_FILE_SIZE') {
      return res.status(400).json({
        success: false,
        message: 'File quá lớn. Vui lòng chọn file nhỏ hơn 15MB'
      });
    }
    return res.status(400).json({
      success: false,
      message: err.message || 'Lỗi khi upload file'
    });
  }
  next();
};

// Upload single image
router.post('/image', protect, upload.single('image'), handleMulterError, (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'Không có file được upload'
      });
    }

    // Trả về relative path để lưu vào database
    // Controller sẽ convert sang absolute URL khi trả về cho client
    const fileUrl = `/uploads/${req.file.filename}`;
    
    res.json({
      success: true,
      data: {
        url: fileUrl,
        filename: req.file.filename,
        originalname: req.file.originalname,
        size: req.file.size
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message || 'Lỗi khi upload file'
    });
  }
});

// Upload single video
router.post('/video', protect, uploadVideo.single('video'), handleMulterError, (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'Không có file được upload'
      });
    }

    // Trả về relative path để lưu vào database
    // Controller sẽ convert sang absolute URL khi trả về cho client
    const fileUrl = `/uploads/${req.file.filename}`;
    
    res.json({
      success: true,
      data: {
        url: fileUrl,
        filename: req.file.filename,
        originalname: req.file.originalname,
        size: req.file.size
      }
    });
  } catch (error) {
    // Xử lý lỗi file quá lớn
    if (error.code === 'LIMIT_FILE_SIZE') {
      return res.status(400).json({
        success: false,
        message: 'File quá lớn. Vui lòng chọn file video nhỏ hơn 100MB'
      });
    }
    
    res.status(500).json({
      success: false,
      message: error.message || 'Lỗi khi upload file'
    });
  }
});

export default router;

