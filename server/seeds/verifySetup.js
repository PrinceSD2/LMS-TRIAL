const mongoose = require('mongoose');
const User = require('../models/User');
require('dotenv').config();

const verifySetup = async () => {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // Check all users
    const users = await User.find({}, 'name email role isActive').sort({ email: 1 });
    
    console.log('\n=== DATABASE VERIFICATION ===');
    console.log(`Total users found: ${users.length}`);
    
    if (users.length === 0) {
      console.log('❌ No users found! Run the seed script first.');
    } else {
      console.log('\n📋 Current Users:');
      users.forEach((user, index) => {
        console.log(`${index + 1}. ${user.name} (${user.email}) - ${user.role.toUpperCase()} - ${user.isActive ? 'Active' : 'Inactive'}`);
      });

      // Verify specific accounts
      const vishal = await User.findOne({ email: 'vishal@lms.com' }).select('+password');
      const jitin = await User.findOne({ email: 'jitin@lms.com' }).select('+password');

      console.log('\n🔍 Account Verification:');
      console.log(`✅ Vishal Account: ${vishal ? 'EXISTS' : 'MISSING'}`);
      if (vishal) {
        try {
          const passwordCheck = await vishal.comparePassword('@dm!n123');
          console.log(`   Password Test: ${passwordCheck ? '✅ CORRECT' : '❌ INCORRECT'}`);
        } catch (error) {
          console.log(`   Password Test: ❌ ERROR - ${error.message}`);
        }
      }

      console.log(`✅ Jitin Account: ${jitin ? 'EXISTS' : 'MISSING'}`);
      if (jitin) {
        try {
          const passwordCheck = await jitin.comparePassword('@dm!n123');
          console.log(`   Password Test: ${passwordCheck ? '✅ CORRECT' : '❌ INCORRECT'}`);
        } catch (error) {
          console.log(`   Password Test: ❌ ERROR - ${error.message}`);
        }
      }
    }

    console.log('\n🎯 SETUP STATUS: ✅ READY TO USE');
    console.log('You can now login with:');
    console.log('- vishal@lms.com / @dm!n123');
    console.log('- jitin@lms.com / @dm!n123');

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await mongoose.connection.close();
    process.exit(0);
  }
};

verifySetup();
