import PlanExerciseCollection from '../models/PlanExerciseCollection.model.js';
import PlanExercise from '../models/PlanExercise.model.js';
import PlanExerciseCollectionSetting from '../models/PlanExerciseCollectionSetting.model.js';

/**
 * @desc    Get all plan exercise collections by planID
 * @route   GET /api/plan-exercises/collections?planID=0
 * @access  Public
 */
export const getPlanExerciseCollections = async (req, res) => {
  try {
    const { planID } = req.query;
    let query = {};
    
    if (planID !== undefined) {
      query.planID = parseInt(planID);
    }

    const collections = await PlanExerciseCollection.find(query)
      .sort({ date: 1 });

    // Populate settings for each collection
    const collectionsWithSettings = await Promise.all(
      collections.map(async (collection) => {
        const collectionObj = collection.toObject();
        try {
          if (collection.collectionSettingID) {
            const setting = await PlanExerciseCollectionSetting.findById(collection.collectionSettingID);
            if (setting) {
              collectionObj.setting = setting;
            }
          }
        } catch (error) {
          // Ignore setting errors
        }
        return collectionObj;
      })
    );

    res.status(200).json({
      success: true,
      count: collectionsWithSettings.length,
      data: collectionsWithSettings
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Get single plan exercise collection
 * @route   GET /api/plan-exercises/collections/:id
 * @access  Public
 */
export const getPlanExerciseCollection = async (req, res) => {
  try {
    const collection = await PlanExerciseCollection.findById(req.params.id);

    if (!collection) {
      return res.status(404).json({
        success: false,
        message: 'Plan exercise collection not found'
      });
    }

    const collectionObj = collection.toObject();
    
    // Populate setting if exists
    if (collection.collectionSettingID) {
      try {
        const setting = await PlanExerciseCollectionSetting.findById(collection.collectionSettingID);
        if (setting) {
          collectionObj.setting = setting;
        }
      } catch (error) {
        // Ignore setting errors
      }
    }

    res.status(200).json({
      success: true,
      data: collectionObj
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Create plan exercise collection
 * @route   POST /api/plan-exercises/collections
 * @access  Private
 */
export const createPlanExerciseCollection = async (req, res) => {
  try {
    const { date, planID, collectionSettingID, exerciseIDs, round, exerciseTime, numOfWorkoutPerRound } = req.body;

    // Tạo hoặc lấy setting
    let setting;
    if (collectionSettingID && collectionSettingID !== '') {
      // Nếu có ID, cập nhật setting
      setting = await PlanExerciseCollectionSetting.findByIdAndUpdate(
        collectionSettingID,
        {
          round: round || 3,
          exerciseTime: exerciseTime || 45,
          numOfWorkoutPerRound: numOfWorkoutPerRound || 10
        },
        { new: true, upsert: true }
      );
    } else {
      // Tạo setting mới
      setting = await PlanExerciseCollectionSetting.create({
        round: round || 3,
        exerciseTime: exerciseTime || 45,
        numOfWorkoutPerRound: numOfWorkoutPerRound || 10
      });
    }

    // Tạo collection
    const collection = await PlanExerciseCollection.create({
      date: new Date(date),
      planID: planID || 0,
      collectionSettingID: setting._id.toString()
    });

    // Tạo các PlanExercise
    if (exerciseIDs && Array.isArray(exerciseIDs) && exerciseIDs.length > 0) {
      const exercises = exerciseIDs.map(exerciseID => ({
        exerciseID,
        listID: collection._id.toString()
      }));
      await PlanExercise.insertMany(exercises);
    }

    // Populate exercises để trả về
    const exercises = await PlanExercise.find({ listID: collection._id.toString() })
      .populate('exerciseID', 'name thumbnail');

    res.status(201).json({
      success: true,
      data: {
        ...collection.toObject(),
        exercises: exercises
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
 * @desc    Update plan exercise collection
 * @route   PUT /api/plan-exercises/collections/:id
 * @access  Private
 */
export const updatePlanExerciseCollection = async (req, res) => {
  try {
    const { date, planID, collectionSettingID, exerciseIDs, round, exerciseTime, numOfWorkoutPerRound } = req.body;

    let collection = await PlanExerciseCollection.findById(req.params.id);
    if (!collection) {
      return res.status(404).json({
        success: false,
        message: 'Plan exercise collection not found'
      });
    }

    // Cập nhật setting
    let setting;
    if (collectionSettingID && collectionSettingID !== '') {
      setting = await PlanExerciseCollectionSetting.findByIdAndUpdate(
        collectionSettingID,
        {
          round: round || collection.round || 3,
          exerciseTime: exerciseTime || collection.exerciseTime || 45,
          numOfWorkoutPerRound: numOfWorkoutPerRound || collection.numOfWorkoutPerRound || 10
        },
        { new: true, upsert: true }
      );
    } else {
      // Tạo setting mới nếu chưa có
      setting = await PlanExerciseCollectionSetting.create({
        round: round || 3,
        exerciseTime: exerciseTime || 45,
        numOfWorkoutPerRound: numOfWorkoutPerRound || 10
      });
    }

    // Cập nhật collection
    if (date) collection.date = new Date(date);
    if (planID !== undefined) collection.planID = planID;
    collection.collectionSettingID = setting._id.toString();
    await collection.save();

    // Xóa exercises cũ và tạo mới
    if (exerciseIDs && Array.isArray(exerciseIDs)) {
      await PlanExercise.deleteMany({ listID: collection._id.toString() });
      
      if (exerciseIDs.length > 0) {
        const exercises = exerciseIDs.map(exerciseID => ({
          exerciseID,
          listID: collection._id.toString()
        }));
        await PlanExercise.insertMany(exercises);
      }
    }

    // Populate exercises để trả về
    const exercises = await PlanExercise.find({ listID: collection._id.toString() })
      .populate('exerciseID', 'name thumbnail');

    res.status(200).json({
      success: true,
      data: {
        ...collection.toObject(),
        exercises: exercises
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
 * @desc    Delete plan exercise collection
 * @route   DELETE /api/plan-exercises/collections/:id
 * @access  Private
 */
export const deletePlanExerciseCollection = async (req, res) => {
  try {
    const collection = await PlanExerciseCollection.findById(req.params.id);
    if (!collection) {
      return res.status(404).json({
        success: false,
        message: 'Plan exercise collection not found'
      });
    }

    // Xóa tất cả exercises liên quan
    await PlanExercise.deleteMany({ listID: collection._id.toString() });
    
    // Xóa setting nếu không còn collection nào dùng
    const otherCollections = await PlanExerciseCollection.findOne({
      collectionSettingID: collection.collectionSettingID,
      _id: { $ne: collection._id }
    });
    if (!otherCollections) {
      await PlanExerciseCollectionSetting.findByIdAndDelete(collection.collectionSettingID);
    }

    // Xóa collection
    await PlanExerciseCollection.findByIdAndDelete(req.params.id);

    res.status(200).json({
      success: true,
      message: 'Plan exercise collection deleted successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Delete all plan exercise collections by planID (batch delete)
 * @route   DELETE /api/plan-exercises/collections?planID=6
 * @access  Private
 */
export const deletePlanExerciseCollectionsByPlanID = async (req, res) => {
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
    const collections = await PlanExerciseCollection.find({ planID: planIDNum });
    
    if (collections.length === 0) {
      return res.status(200).json({
        success: true,
        message: 'No collections found for this plan',
        deletedCount: 0
      });
    }

    // Lấy tất cả collection IDs
    const collectionIds = collections.map(col => col._id.toString());
    
    // Xóa tất cả exercises liên quan trong một lần
    await PlanExercise.deleteMany({ listID: { $in: collectionIds } });
    
    // Lấy tất cả setting IDs và xóa settings không còn được dùng
    const settingIds = [...new Set(collections.map(col => col.collectionSettingID))];
    
    // Xóa settings song song để tăng tốc độ (chỉ xóa nếu không còn collection nào dùng)
    const deleteSettingPromises = settingIds.map(async (settingId) => {
      const otherCollections = await PlanExerciseCollection.findOne({
        collectionSettingID: settingId,
        planID: { $ne: planIDNum }
      });
      if (!otherCollections) {
        await PlanExerciseCollectionSetting.findByIdAndDelete(settingId);
      }
    });
    
    // Chờ tất cả settings được xóa song song
    await Promise.all(deleteSettingPromises);

    // Xóa tất cả collections trong một lần
    const deleteResult = await PlanExerciseCollection.deleteMany({ planID: planIDNum });

    res.status(200).json({
      success: true,
      message: `Deleted ${deleteResult.deletedCount} plan exercise collections successfully`,
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
 * @desc    Get exercises by listID
 * @route   GET /api/plan-exercises?listID=xxx
 * @access  Public
 */
export const getPlanExercises = async (req, res) => {
  try {
    const { listID } = req.query;
    let query = {};
    
    if (listID) {
      query.listID = listID;
    }

    const exercises = await PlanExercise.find(query)
      .populate('exerciseID', 'name thumbnail metValue')
      .sort({ createdAt: 1 });

    res.status(200).json({
      success: true,
      count: exercises.length,
      data: exercises
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

/**
 * @desc    Get plan exercise collection setting by ID
 * @route   GET /api/plan-exercises/settings/:id
 * @access  Public
 */
export const getPlanExerciseCollectionSetting = async (req, res) => {
  try {
    const setting = await PlanExerciseCollectionSetting.findById(req.params.id);

    if (!setting) {
      return res.status(404).json({
        success: false,
        message: 'Plan exercise collection setting not found'
      });
    }

    res.status(200).json({
      success: true,
      data: setting
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

