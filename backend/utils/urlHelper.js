/**
 * Kiểm tra xem URL có phải là URL từ Cloudinary không
 * @param {string} url - URL cần kiểm tra
 * @returns {boolean}
 */
function isCloudinaryUrl(url) {
  if (!url) return false;
  return url.includes("cloudinary.com") || url.includes("res.cloudinary.com");
}

/**
 * Chuyển đổi asset URL thành full URL dựa trên request
 * @param {string} assetUrl - URL có thể là relative (/uploads/...) hoặc absolute (http://...)
 * @param {Object} req - Express request object
 * @returns {string} - Full URL
 */
export function normalizeAssetUrl(assetUrl, req) {
  if (!assetUrl || assetUrl.trim() === "") {
    return assetUrl;
  }

  // Nếu là URL từ Cloudinary, giữ nguyên (đây là URL đầy đủ có thể truy cập từ mọi nơi)
  if (isCloudinaryUrl(assetUrl)) {
    return assetUrl;
  }

  const protocol = req.protocol;
  const host = req.get("host");

  // Nếu là relative path (bắt đầu bằng /uploads), chuyển thành full URL
  if (assetUrl.startsWith("/uploads/")) {
    return `${protocol}://${host}${assetUrl}`;
  }

  // Nếu là full URL, extract pathname và chuyển thành URL với host hiện tại
  try {
    const url = new URL(assetUrl);
    // Chỉ extract pathname nếu là path uploads (không phải Cloudinary)
    if (url.pathname.startsWith("/uploads/")) {
      return `${protocol}://${host}${url.pathname}`;
    }
    // Nếu đã là full URL khác (bao gồm Cloudinary) thì giữ nguyên
    return assetUrl;
  } catch (e) {
    // Nếu không phải là URL hợp lệ, giữ nguyên
    return assetUrl;
  }
}

/**
 * Chuyển đổi asset URL thành dạng phù hợp để lưu vào database
 * - URL từ Cloudinary: giữ nguyên (vì là URL public)
 * - URL local: chuyển về relative path
 * @param {string} assetUrl - URL có thể là relative (/uploads/...) hoặc absolute (http://...)
 * @returns {string} - URL đã được normalize
 */
export function normalizeAssetUrlForStorage(assetUrl) {
  if (!assetUrl || assetUrl.trim() === "") {
    return assetUrl;
  }

  // Nếu là URL từ Cloudinary, giữ nguyên (lưu full URL vào database)
  if (isCloudinaryUrl(assetUrl)) {
    return assetUrl;
  }

  // Nếu đã là relative path, trả về nguyên
  if (assetUrl.startsWith("/uploads/")) {
    return assetUrl;
  }

  // Nếu là full URL local, extract pathname
  try {
    const url = new URL(assetUrl);
    if (url.pathname.startsWith("/uploads/")) {
      return url.pathname;
    }
    // Nếu không phải uploads path, giữ nguyên
    return assetUrl;
  } catch (e) {
    // Nếu không phải là URL hợp lệ, giữ nguyên
    return assetUrl;
  }
}

/**
 * Normalize image URLs trong một object
 * @param {Object} obj - Object có thể chứa các trường image (imageUrl, imageLink, asset, thumbnail)
 * @param {Object} req - Express request object
 * @returns {Object} - Object đã được normalize URLs
 */
export function normalizeObjectImageUrls(obj, req) {
  if (!obj || typeof obj !== "object") {
    return obj;
  }

  const normalized = obj.toObject ? obj.toObject() : { ...obj };

  // Normalize các trường image/video phổ biến
  const assetFields = [
    "imageUrl",
    "imageLink",
    "asset",
    "thumbnail",
    "muscleFocusAsset",
    "animation",
  ];
  assetFields.forEach((field) => {
    if (normalized[field]) {
      normalized[field] = normalizeAssetUrl(normalized[field], req);
    }
  });

  // Xử lý populate fields (categoryIDs, etc.)
  if (normalized.categoryIDs && Array.isArray(normalized.categoryIDs)) {
    normalized.categoryIDs = normalized.categoryIDs.map((cat) => {
      if (cat && typeof cat === "object") {
        return normalizeObjectImageUrls(cat, req);
      }
      return cat;
    });
  }

  if (normalized.generatorIDs && Array.isArray(normalized.generatorIDs)) {
    normalized.generatorIDs = normalized.generatorIDs.map((gen) => {
      if (gen && typeof gen === "object") {
        return normalizeObjectImageUrls(gen, req);
      }
      return gen;
    });
  }

  return normalized;
}

/**
 * Normalize image URLs trong một array of objects
 * @param {Array} array - Array of objects
 * @param {Object} req - Express request object
 * @returns {Array} - Array đã được normalize URLs
 */
export function normalizeArrayImageUrls(array, req) {
  if (!Array.isArray(array)) {
    return array;
  }
  return array.map((item) => normalizeObjectImageUrls(item, req));
}
