import LibrarySection from '../models/LibrarySection.model.js';

/**
 * @desc    Get all library sections
 * @route   GET /api/library-sections
 * @access  Public
 */
export const getLibrarySections = async (req, res) => {
  try {
    const { activeOnly } = req.query;
    let query = {};

    if (activeOnly === 'true') {
      query.isActive = true;
    }

    const sections = await LibrarySection.find(query)
      .sort({ order: 1 })
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      count: sections.length,
      data: sections
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Get single library section
 * @route   GET /api/library-sections/:id
 * @access  Public
 */
export const getLibrarySection = async (req, res) => {
  try {
    const section = await LibrarySection.findById(req.params.id);

    if (!section) {
      return res.status(404).json({
        success: false,
        message: 'Library section not found'
      });
    }

    res.status(200).json({
      success: true,
      data: section
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Create library section
 * @route   POST /api/library-sections
 * @access  Private
 */
export const createLibrarySection = async (req, res) => {
  try {
    const section = await LibrarySection.create(req.body);

    res.status(201).json({
      success: true,
      data: section
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Update library section
 * @route   PUT /api/library-sections/:id
 * @access  Private
 */
export const updateLibrarySection = async (req, res) => {
  try {
    const section = await LibrarySection.findByIdAndUpdate(
      req.params.id,
      req.body,
      {
        new: true,
        runValidators: true
      }
    );

    if (!section) {
      return res.status(404).json({
        success: false,
        message: 'Library section not found'
      });
    }

    res.status(200).json({
      success: true,
      data: section
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Delete library section
 * @route   DELETE /api/library-sections/:id
 * @access  Private
 */
export const deleteLibrarySection = async (req, res) => {
  try {
    const section = await LibrarySection.findById(req.params.id);

    if (!section) {
      return res.status(404).json({
        success: false,
        message: 'Library section not found'
      });
    }

    await section.deleteOne();

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

