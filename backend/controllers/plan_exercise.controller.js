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

    // Populate settings ngay tại đây để Frontend không phải gọi lại
    const collections = await PlanExerciseCollection.find(query)
      .sort({ date: 1 });

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

// ... (Giữ nguyên các hàm getPlanExerciseCollection, create..., update..., delete... ở giữa)

export const getPlanExerciseCollection = async (req, res) => {
  try {
    const collection = await PlanExerciseCollection.findById(req.params.id);
    if (!collection) return res.status(404).json({ success: false, message: 'Not found' });
    const collectionObj = collection.toObject();
    if (collection.collectionSettingID) {
        const setting = await PlanExerciseCollectionSetting.findById(collection.collectionSettingID);
        if (setting) collectionObj.setting = setting;
    }
    res.status(200).json({ success: true, data: collectionObj });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const createPlanExerciseCollection = async (req, res) => {
    // ... (Giữ nguyên code cũ của bạn)
    try {
        const { date, planID, collectionSettingID, exerciseIDs, round, exerciseTime, numOfWorkoutPerRound } = req.body;
        let setting;
        if (collectionSettingID && collectionSettingID !== '') {
          setting = await PlanExerciseCollectionSetting.findByIdAndUpdate(collectionSettingID, { round: round || 3, exerciseTime: exerciseTime || 45, numOfWorkoutPerRound: numOfWorkoutPerRound || 10 }, { new: true, upsert: true });
        } else {
          setting = await PlanExerciseCollectionSetting.create({ round: round || 3, exerciseTime: exerciseTime || 45, numOfWorkoutPerRound: numOfWorkoutPerRound || 10 });
        }
        const collection = await PlanExerciseCollection.create({ date: new Date(date), planID: planID || 0, collectionSettingID: setting._id.toString() });
        if (exerciseIDs && Array.isArray(exerciseIDs) && exerciseIDs.length > 0) {
          const exercises = exerciseIDs.map(exerciseID => ({ exerciseID, listID: collection._id.toString() }));
          await PlanExercise.insertMany(exercises);
        }
        const exercises = await PlanExercise.find({ listID: collection._id.toString() }).populate('exerciseID', 'name thumbnail');
        res.status(201).json({ success: true, data: { ...collection.toObject(), exercises: exercises } });
      } catch (error) { res.status(500).json({ success: false, message: error.message }); }
};

export const updatePlanExerciseCollection = async (req, res) => {
    // ... (Giữ nguyên code cũ của bạn)
    try {
        const { date, planID, collectionSettingID, exerciseIDs, round, exerciseTime, numOfWorkoutPerRound } = req.body;
        let collection = await PlanExerciseCollection.findById(req.params.id);
        if (!collection) return res.status(404).json({ success: false, message: 'Not found' });
        let setting;
        if (collectionSettingID && collectionSettingID !== '') {
          setting = await PlanExerciseCollectionSetting.findByIdAndUpdate(collectionSettingID, { round: round || collection.round || 3, exerciseTime: exerciseTime || collection.exerciseTime || 45, numOfWorkoutPerRound: numOfWorkoutPerRound || collection.numOfWorkoutPerRound || 10 }, { new: true, upsert: true });
        } else {
          setting = await PlanExerciseCollectionSetting.create({ round: round || 3, exerciseTime: exerciseTime || 45, numOfWorkoutPerRound: numOfWorkoutPerRound || 10 });
        }
        if (date) collection.date = new Date(date);
        if (planID !== undefined) collection.planID = planID;
        collection.collectionSettingID = setting._id.toString();
        await collection.save();
        if (exerciseIDs && Array.isArray(exerciseIDs)) {
          await PlanExercise.deleteMany({ listID: collection._id.toString() });
          if (exerciseIDs.length > 0) {
            const exercises = exerciseIDs.map(exerciseID => ({ exerciseID, listID: collection._id.toString() }));
            await PlanExercise.insertMany(exercises);
          }
        }
        const exercises = await PlanExercise.find({ listID: collection._id.toString() }).populate('exerciseID', 'name thumbnail');
        res.status(200).json({ success: true, data: { ...collection.toObject(), exercises: exercises } });
      } catch (error) { res.status(500).json({ success: false, message: error.message }); }
};

export const deletePlanExerciseCollection = async (req, res) => {
    // ... (Giữ nguyên code cũ của bạn)
    try {
        const collection = await PlanExerciseCollection.findById(req.params.id);
        if (!collection) return res.status(404).json({ success: false, message: 'Not found' });
        await PlanExercise.deleteMany({ listID: collection._id.toString() });
        const otherCollections = await PlanExerciseCollection.findOne({ collectionSettingID: collection.collectionSettingID, _id: { $ne: collection._id } });
        if (!otherCollections) await PlanExerciseCollectionSetting.findByIdAndDelete(collection.collectionSettingID);
        await PlanExerciseCollection.findByIdAndDelete(req.params.id);
        res.status(200).json({ success: true, message: 'Deleted successfully' });
      } catch (error) { res.status(500).json({ success: false, message: error.message }); }
};

export const deletePlanExerciseCollectionsByPlanID = async (req, res) => {
    // ... (Giữ nguyên code cũ của bạn)
    try {
        const { planID } = req.query;
        if (!planID) return res.status(400).json({ success: false, message: 'planID required' });
        const planIDNum = parseInt(planID);
        const collections = await PlanExerciseCollection.find({ planID: planIDNum });
        if (collections.length === 0) return res.status(200).json({ success: true, message: 'No collections found', deletedCount: 0 });
        const collectionIds = collections.map(col => col._id.toString());
        await PlanExercise.deleteMany({ listID: { $in: collectionIds } });
        const settingIds = [...new Set(collections.map(col => col.collectionSettingID))];
        const deleteSettingPromises = settingIds.map(async (settingId) => {
          const otherCollections = await PlanExerciseCollection.findOne({ collectionSettingID: settingId, planID: { $ne: planIDNum } });
          if (!otherCollections) await PlanExerciseCollectionSetting.findByIdAndDelete(settingId);
        });
        await Promise.all(deleteSettingPromises);
        const deleteResult = await PlanExerciseCollection.deleteMany({ planID: planIDNum });
        res.status(200).json({ success: true, message: `Deleted ${deleteResult.deletedCount} collections`, deletedCount: deleteResult.deletedCount });
      } catch (error) { res.status(500).json({ success: false, message: error.message }); }
};

// --- ĐÂY LÀ PHẦN SỬA ĐỔI QUAN TRỌNG NHẤT ---

/**
 * @desc    Get exercises by listID OR planID
 * @route   GET /api/plan-exercises?listID=xxx OR ?planID=xxx
 * @access  Public
 */
export const getPlanExercises = async (req, res) => {
  try {
    const { listID, planID } = req.query;
    let query = {};
    
    if (listID) {
      query.listID = listID;
    } 
    // SỬA: Thêm logic lấy theo planID
    else if (planID) {
        // Tìm tất cả collection của plan này trước
        const collections = await PlanExerciseCollection.find({ planID: parseInt(planID) }).select('_id');
        // Lấy danh sách ID của các collection
        const listIDs = collections.map(c => c._id.toString());
        // Tìm tất cả bài tập thuộc các collection đó
        query.listID = { $in: listIDs };
    }

    const exercises = await PlanExercise.find(query)
      .populate('exerciseID', 'name thumbnail metValue animation') // Lấy thêm animation
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