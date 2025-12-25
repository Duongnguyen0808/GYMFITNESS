import PlanMealCollection from '../models/PlanMealCollection.model.js';
import PlanMeal from '../models/PlanMeal.model.js';

/**
 * @desc    Get all plan meal collections by planID
 * @route   GET /api/plan-meals/collections?planID=0
 * @access  Public
 */
export const getPlanMealCollections = async (req, res) => {
  try {
    const { planID } = req.query;
    let query = {};
    
    if (planID !== undefined) {
      query.planID = parseInt(planID);
    }

    const collections = await PlanMealCollection.find(query)
      .sort({ date: 1 });

    res.status(200).json({
      success: true,
      count: collections.length,
      data: collections
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Get single plan meal collection
 * @route   GET /api/plan-meals/collections/:id
 * @access  Public
 */
export const getPlanMealCollection = async (req, res) => {
  try {
    const collection = await PlanMealCollection.findById(req.params.id);

    if (!collection) {
      return res.status(404).json({
        success: false,
        message: 'Plan meal collection not found'
      });
    }

    res.status(200).json({
      success: true,
      data: collection
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Create plan meal collection
 * @route   POST /api/plan-meals/collections
 * @access  Private
 */
export const createPlanMealCollection = async (req, res) => {
  try {
    const { date, planID, mealRatio, mealIDs } = req.body;

    // Tạo collection
    const collection = await PlanMealCollection.create({
      date: new Date(date),
      planID: planID || 0,
      mealRatio: mealRatio || 1.0
    });

    // Tạo các PlanMeal
    if (mealIDs && Array.isArray(mealIDs) && mealIDs.length > 0) {
      const meals = mealIDs.map(mealID => ({
        mealID,
        listID: collection._id.toString()
      }));
      await PlanMeal.insertMany(meals);
    }

    // Populate meals để trả về
    const meals = await PlanMeal.find({ listID: collection._id.toString() })
      .populate('mealID', 'name asset');

    res.status(201).json({
      success: true,
      data: {
        ...collection.toObject(),
        meals: meals
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Update plan meal collection
 * @route   PUT /api/plan-meals/collections/:id
 * @access  Private
 */
export const updatePlanMealCollection = async (req, res) => {
  try {
    const { date, planID, mealRatio, mealIDs } = req.body;

    let collection = await PlanMealCollection.findById(req.params.id);
    if (!collection) {
      return res.status(404).json({
        success: false,
        message: 'Plan meal collection not found'
      });
    }

    // Cập nhật collection
    if (date) collection.date = new Date(date);
    if (planID !== undefined) collection.planID = planID;
    if (mealRatio !== undefined) collection.mealRatio = mealRatio;
    await collection.save();

    // Xóa meals cũ và tạo mới
    if (mealIDs && Array.isArray(mealIDs)) {
      await PlanMeal.deleteMany({ listID: collection._id.toString() });
      
      if (mealIDs.length > 0) {
        const meals = mealIDs.map(mealID => ({
          mealID,
          listID: collection._id.toString()
        }));
        await PlanMeal.insertMany(meals);
      }
    }

    // Populate meals để trả về
    const meals = await PlanMeal.find({ listID: collection._id.toString() })
      .populate('mealID', 'name asset');

    res.status(200).json({
      success: true,
      data: {
        ...collection.toObject(),
        meals: meals
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Delete plan meal collection
 * @route   DELETE /api/plan-meals/collections/:id
 * @access  Private
 */
export const deletePlanMealCollection = async (req, res) => {
  try {
    const collection = await PlanMealCollection.findById(req.params.id);
    if (!collection) {
      return res.status(404).json({
        success: false,
        message: 'Plan meal collection not found'
      });
    }

    // Xóa tất cả meals liên quan
    await PlanMeal.deleteMany({ listID: collection._id.toString() });
    
    // Xóa collection
    await PlanMealCollection.findByIdAndDelete(req.params.id);

    res.status(200).json({
      success: true,
      message: 'Plan meal collection deleted successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Delete all plan meal collections by planID (batch delete)
 * @route   DELETE /api/plan-meals/collections?planID=6
 * @access  Private
 */
export const deletePlanMealCollectionsByPlanID = async (req, res) => {
  try {
    const { planID } = req.query;
    
    if (!planID) {
      return res.status(400).json({
        success: false,
        message: 'planID is required'
      });
    }

    const planIDNum = parseInt(planID);
    
    // Tìm tất cả collections của plan này
    const collections = await PlanMealCollection.find({ planID: planIDNum });
    
    if (collections.length === 0) {
      return res.status(200).json({
        success: true,
        message: 'No collections found for this plan',
        deletedCount: 0
      });
    }

    // Lấy tất cả collection IDs
    const collectionIds = collections.map(col => col._id.toString());
    
    // Xóa tất cả meals liên quan trong một lần
    await PlanMeal.deleteMany({ listID: { $in: collectionIds } });

    // Xóa tất cả collections trong một lần
    const deleteResult = await PlanMealCollection.deleteMany({ planID: planIDNum });

    res.status(200).json({
      success: true,
      message: `Deleted ${deleteResult.deletedCount} plan meal collections successfully`,
      deletedCount: deleteResult.deletedCount
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Get meals by listID
 * @route   GET /api/plan-meals?listID=xxx
 * @access  Public
 */
export const getPlanMeals = async (req, res) => {
  try {
    const { listID } = req.query;
    let query = {};
    
    if (listID) {
      query.listID = listID;
    }

    const meals = await PlanMeal.find(query)
      .populate('mealID', 'name asset cookTime')
      .sort({ createdAt: 1 });

    res.status(200).json({
      success: true,
      count: meals.length,
      data: meals
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

