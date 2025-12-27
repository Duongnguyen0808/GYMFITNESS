import Equipment from '../models/Equipment.model.js';
import { normalizeAssetUrl, normalizeAssetUrlForStorage, normalizeArrayImageUrls } from '../utils/urlHelper.js';

/**
 * @desc    Get all equipment
 * @route   GET /api/equipment
 * @access  Public
 */
export const getEquipment = async (req, res) => {
  try {
    const { search } = req.query;
    let query = {};

    if (search) {
      query.$text = { $search: search };
    }

    const equipment = await Equipment.find(query).sort({ createdAt: -1 });

    // Normalize image URLs
    const normalizedEquipment = normalizeArrayImageUrls(equipment, req);

    res.status(200).json({
      success: true,
      count: normalizedEquipment.length,
      data: normalizedEquipment
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Get single equipment
 * @route   GET /api/equipment/:id
 * @access  Public
 */
export const getSingleEquipment = async (req, res) => {
  try {
    const equipment = await Equipment.findById(req.params.id);

    if (!equipment) {
      return res.status(404).json({
        success: false,
        message: 'Equipment not found'
      });
    }

    res.status(200).json({
      success: true,
      data: equipment
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Create equipment
 * @route   POST /api/equipment
 * @access  Private
 */
export const createEquipment = async (req, res) => {
  try {
    // Normalize imageLink để chỉ lưu relative path vào database
    const body = { ...req.body };
    if (body.imageLink) {
      body.imageLink = normalizeAssetUrlForStorage(body.imageLink);
    }
    const equipment = await Equipment.create(body);

    // Normalize image URL
    const normalizedEquipment = normalizeArrayImageUrls([equipment], req)[0];

    res.status(201).json({
      success: true,
      data: normalizedEquipment
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Update equipment
 * @route   PUT /api/equipment/:id
 * @access  Private
 */
export const updateEquipment = async (req, res) => {
  try {
    // Normalize imageLink để chỉ lưu relative path vào database
    const body = { ...req.body };
    if (body.imageLink) {
      body.imageLink = normalizeAssetUrlForStorage(body.imageLink);
    }
    const equipment = await Equipment.findByIdAndUpdate(
      req.params.id,
      body,
      {
        new: true,
        runValidators: true
      }
    );

    if (!equipment) {
      return res.status(404).json({
        success: false,
        message: 'Equipment not found'
      });
    }

    res.status(200).json({
      success: true,
      data: equipment
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Delete equipment
 * @route   DELETE /api/equipment/:id
 * @access  Private
 */
export const deleteEquipment = async (req, res) => {
  try {
    const equipment = await Equipment.findById(req.params.id);

    if (!equipment) {
      return res.status(404).json({
        success: false,
        message: 'Equipment not found'
      });
    }

    await equipment.deleteOne();

    res.status(200).json({
      success: true,
      data: {}
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};


