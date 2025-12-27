import multer from "multer";

// Sử dụng memory storage để lưu file tạm trong buffer
// Sau đó upload lên Cloudinary
const storage = multer.memoryStorage();

// Filter để cho phép file ảnh và video
const fileFilter = (req, file, cb) => {
  const imageTypes = /jpeg|jpg|png|gif|webp/;
  const videoTypes = /mp4|mov|avi|wmv|webm|mkv/;

  const ext = file.originalname.toLowerCase().split(".").pop();
  const isImage = imageTypes.test(ext) || file.mimetype.startsWith("image/");
  const isVideo = videoTypes.test(ext) || file.mimetype.startsWith("video/");

  if (isImage || isVideo) {
    cb(null, true);
  } else {
    cb(
      new Error(
        "Chỉ cho phép upload file ảnh (JPEG, JPG, PNG, GIF, WEBP) hoặc video (MP4, MOV, AVI, WMV, WEBM, MKV)"
      ),
      false
    );
  }
};

const uploadToCloudinary = multer({
  storage: storage,
  limits: {
    fileSize: 100 * 1024 * 1024, // 100MB để hỗ trợ cả video
  },
  fileFilter: fileFilter,
});

export default uploadToCloudinary;
