const mongoose = require('mongoose');
const User = require('../models/User');
require('dotenv').config();

const createSuperAdmins = async () => {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // Clear all existing users
    await User.deleteMany({});
    console.log('Cleared all existing users');

    // Create the two specified super admin accounts
    const superAdmins = [
      {
        name: 'Vishal Admin',
        email: 'vishal@lms.com',
        password: '@dm!n123',
        role: 'superadmin',
        isActive: true
      },
      {
        name: 'Jitin Admin', 
        email: 'jitin@lms.com',
        password: '@dm!n123',
        role: 'superadmin',
        isActive: true
      }
    ];

    for (const adminData of superAdmins) {
      // Use create method which properly triggers pre-save middleware
      const superAdmin = await User.create(adminData);
      console.log(`SuperAdmin created: ${adminData.name} (${adminData.email}) - ID: ${superAdmin._id}`);
    }

    console.log('\n=== SETUP COMPLETE ===');
    console.log('Two SuperAdmin accounts created:');
    console.log('1. Email: vishal@lms.com, Password: @dm!n123');
    console.log('2. Email: jitin@lms.com, Password: @dm!n123');
    console.log('\nYou can now create organizations and other users through the dashboard.');

  } catch (error) {
    console.error('Error creating superadmins:', error);
  } finally {
    await mongoose.connection.close();
    process.exit(0);
  }
};

createSuperAdmins();
