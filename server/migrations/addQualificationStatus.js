const mongoose = require('mongoose');
require('dotenv').config();

// Lead model schema (simplified for migration)
const LeadSchema = new mongoose.Schema({
  leadProgressStatus: String,
  qualificationStatus: {
    type: String,
    enum: ['qualified', 'unqualified', 'pending'],
    default: 'pending'
  }
});

const Lead = mongoose.model('Lead', LeadSchema);

async function addQualificationStatus() {
  try {
    console.log('🔄 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Get all leads that don't have qualificationStatus or have it as null
    const leads = await Lead.find({
      $or: [
        { qualificationStatus: { $exists: false } },
        { qualificationStatus: null }
      ]
    });

    console.log(`📊 Found ${leads.length} leads to update`);

    if (leads.length === 0) {
      console.log('✅ No leads need updating');
      return;
    }

    let updatedCount = 0;

    for (const lead of leads) {
      let qualificationStatus = 'pending'; // default

      if (lead.leadProgressStatus) {
        const qualifiedStatuses = [
          'Appointment Scheduled',
          'Immediate Enrollment',
          'Info Provided – Awaiting Decision',
          'Qualified – Meets Criteria',
          'Pre-Qualified – Docs Needed'
        ];
        
        const unqualifiedStatuses = [
          'Disqualified – Debt Too Low',
          'Disqualified – Secured Debt Only',
          'Disqualified – Non-Service State',
          'Disqualified – Active with Competitor',
          'Not Interested',
          'DNC (Do Not Contact)'
        ];
        
        if (qualifiedStatuses.includes(lead.leadProgressStatus)) {
          qualificationStatus = 'qualified';
        } else if (unqualifiedStatuses.includes(lead.leadProgressStatus)) {
          qualificationStatus = 'unqualified';
        }
      }

      await Lead.updateOne(
        { _id: lead._id },
        { qualificationStatus: qualificationStatus }
      );

      updatedCount++;
      
      if (updatedCount % 100 === 0) {
        console.log(`📝 Updated ${updatedCount}/${leads.length} leads...`);
      }
    }

    console.log(`✅ Successfully updated ${updatedCount} leads with qualification status`);

    // Add index for better performance
    await Lead.collection.createIndex({ qualificationStatus: 1 });
    console.log('✅ Added index for qualificationStatus field');

  } catch (error) {
    console.error('❌ Migration failed:', error);
    throw error;
  } finally {
    await mongoose.disconnect();
    console.log('🔌 Disconnected from MongoDB');
  }
}

// Run migration if called directly
if (require.main === module) {
  addQualificationStatus()
    .then(() => {
      console.log('🎉 Migration completed successfully');
      process.exit(0);
    })
    .catch((error) => {
      console.error('💥 Migration failed:', error);
      process.exit(1);
    });
}

module.exports = addQualificationStatus;
