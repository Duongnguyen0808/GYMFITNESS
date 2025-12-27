/**
 * Script to create the first admin user
 * Run with: node scripts/createAdmin.js
 */

import mongoose from 'mongoose';
import dotenv from 'dotenv';
import User from '../models/User.model.js';

dotenv.config();

const createAdmin = async () => {
    try {
        // Connect to database
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('Connected to MongoDB');

        // Admin credentials - change these!
        const adminEmail = process.env.ADMIN_EMAIL || 'admin@gym.com';
        const adminPassword = process.env.ADMIN_PASSWORD || 'admin123456';
        const adminName = process.env.ADMIN_NAME || 'Super Admin';

        // Check if admin already exists
        const existingAdmin = await User.findOne({ email: adminEmail });
        
        if (existingAdmin) {
            if (existingAdmin.role === 'admin') {
                console.log('Admin user already exists!');
            } else {
                // Update existing user to admin
                existingAdmin.role = 'admin';
                await existingAdmin.save();
                console.log('Updated existing user to admin role!');
            }
        } else {
            // Create new admin user
            const admin = await User.create({
                email: adminEmail,
                password: adminPassword,
                name: adminName,
                role: 'admin'
            });
            console.log('Admin user created successfully!');
            console.log('Email:', adminEmail);
            console.log('Password:', adminPassword);
        }

        await mongoose.disconnect();
        console.log('Disconnected from MongoDB');
        process.exit(0);
    } catch (error) {
        console.error('Error creating admin:', error.message);
        process.exit(1);
    }
};

createAdmin();
