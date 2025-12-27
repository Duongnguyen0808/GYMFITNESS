import mongoose from 'mongoose';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

dotenv.config({ path: path.join(__dirname, '..', '.env') });

// Import models
import Workout from '../models/Workout.model.js';
import PlanExerciseCollection from '../models/PlanExerciseCollection.model.js';
import PlanExercise from '../models/PlanExercise.model.js';
import PlanExerciseCollectionSetting from '../models/PlanExerciseCollectionSetting.model.js';

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/vipt';

async function seedWorkoutPlan() {
  try {
    console.log('🔗 Đang kết nối MongoDB...');
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Đã kết nối MongoDB');

    // 1. Lấy tất cả workouts hiện có
    const workouts = await Workout.find({});
    console.log(`📋 Tìm thấy ${workouts.length} bài tập:`);
    workouts.forEach(w => console.log(`   - ${w.name} (ID: ${w._id})`));

    if (workouts.length === 0) {
      console.log('❌ Không có bài tập nào. Vui lòng tạo bài tập trước.');
      process.exit(1);
    }

    // 2. Xóa dữ liệu cũ của plan mặc định (planID = 0)
    console.log('\n🗑️ Xóa dữ liệu workout plan cũ (planID = 0)...');
    const oldCollections = await PlanExerciseCollection.find({ planID: 0 });
    for (const col of oldCollections) {
      await PlanExercise.deleteMany({ listID: col._id.toString() });
      if (col.collectionSettingID) {
        await PlanExerciseCollectionSetting.findByIdAndDelete(col.collectionSettingID);
      }
    }
    await PlanExerciseCollection.deleteMany({ planID: 0 });
    console.log('✅ Đã xóa dữ liệu cũ');

    // 3. Tạo workout plan cho 7 ngày tiếp theo
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    console.log('\n📅 Tạo lịch tập luyện cho 7 ngày...');

    for (let i = 0; i < 7; i++) {
      const planDate = new Date(today);
      planDate.setDate(today.getDate() + i);

      // Tạo setting cho collection
      const setting = await PlanExerciseCollectionSetting.create({
        round: 3,
        exerciseTime: 45,
        numOfWorkoutPerRound: workouts.length,
        isStartWithWarmUp: true,
        isShuffle: false,
        transitionTime: 10,
        restTime: 30,
        restFrequency: 3
      });

      // Tạo collection cho ngày này
      const collection = await PlanExerciseCollection.create({
        date: planDate,
        planID: 0, // Default plan
        collectionSettingID: setting._id.toString()
      });

      // Thêm tất cả bài tập vào collection
      const exercises = workouts.map(workout => ({
        exerciseID: workout._id.toString(),
        listID: collection._id.toString()
      }));

      await PlanExercise.insertMany(exercises);

      const dateStr = planDate.toLocaleDateString('vi-VN');
      console.log(`   ✅ Ngày ${i + 1} (${dateStr}): ${workouts.length} bài tập`);
    }

    console.log('\n🎉 Hoàn tất tạo dữ liệu mẫu!');
    console.log('\n📱 Hãy reload app Flutter để xem lộ trình tập luyện.');

    // Hiển thị dữ liệu đã tạo
    const createdCollections = await PlanExerciseCollection.find({ planID: 0 }).sort({ date: 1 });
    console.log(`\n📊 Đã tạo ${createdCollections.length} ngày tập luyện:`);
    
    for (const col of createdCollections) {
      const exercises = await PlanExercise.find({ listID: col._id.toString() }).populate('exerciseID', 'name');
      const dateStr = col.date.toLocaleDateString('vi-VN');
      const exerciseNames = exercises.map(e => e.exerciseID?.name || 'Unknown').join(', ');
      console.log(`   ${dateStr}: ${exerciseNames}`);
    }

  } catch (error) {
    console.error('❌ Lỗi:', error.message);
  } finally {
    await mongoose.disconnect();
    console.log('\n🔌 Đã ngắt kết nối MongoDB');
    process.exit(0);
  }
}

seedWorkoutPlan();
