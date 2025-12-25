import multer from 'multer';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import fs from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Tạo thư mục uploads nếu chưa có
const uploadsDir = join(__dirname, '..', 'public', 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

// Cấu hình storage cho video
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadsDir);
  },
  filename: (req, file, cb) => {
    // Tạo tên file unique
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const ext = file.originalname.split('.').pop();
    cb(null, `video-${uniqueSuffix}.${ext}`);
  }
});

// Filter để chỉ cho phép file video
const fileFilter = (req, file, cb) => {
  const allowedTypes = /mp4|mov|avi|mkv|webm/;
  const extname = allowedTypes.test(file.originalname.toLowerCase().split('.').pop());
  const mimetype = /video/.test(file.mimetype);
  
  if (extname && mimetype) {
    cb(null, true);
  } else {
    cb(new Error('Chỉ cho phép upload file video (MP4, MOV, AVI, MKV, WEBM)'), false);
  }
};

const uploadVideo = multer({
  storage: storage,
  limits: {
    fileSize: 100 * 1024 * 1024 // 100MB cho video
  },
  fileFilter: fileFilter
});

export default uploadVideo;

