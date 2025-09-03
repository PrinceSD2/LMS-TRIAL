const mongoose = require('mongoose');
require('dotenv').config();

// Define connection string
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb+srv://dbhayani:YOhN7p%2A%21zJ1XbM@cluster0.jo25hav.mongodb.net/LMSdata%2B?retryWrites=true&w=majority&appName=Cluster0';

async function addDuplicateFields() {
  try {
    console.log('Connecting to MongoDB...');
    await mongoose.connect(MONGODB_URI);
    console.log('Connected successfully!');

    const db = mongoose.connection.db;
    const collection = db.collection('leads');

    console.log('Adding duplicate detection fields to existing leads...');

    // Add duplicate fields to all existing leads (set as false/null by default)
    const result = await collection.updateMany(
      {}, // Update all documents
      {
        $set: {
          isDuplicate: false,
          duplicateOf: null,
          duplicateReason: null,
          duplicateDetectedAt: null,
          duplicateDetectedBy: null
        }
      }
    );

    console.log(`Successfully updated ${result.modifiedCount} leads with duplicate fields`);

    // Now let's detect and mark actual duplicates
    console.log('Detecting duplicate leads...');
    
    const leads = await collection.find({}).toArray();
    console.log(`Found ${leads.length} total leads to check for duplicates`);

    let duplicatesFound = 0;
    const processedEmails = new Set();
    const processedPhones = new Set();

    for (const lead of leads) {
      let isDuplicate = false;
      let duplicateOf = null;
      let duplicateReason = null;

      // Check for email duplicates
      if (lead.email && processedEmails.has(lead.email)) {
        // Find the original lead with this email
        const originalLead = await collection.findOne({
          email: lead.email,
          _id: { $lt: lead._id }, // Earlier created lead
          isDuplicate: false
        });
        
        if (originalLead) {
          isDuplicate = true;
          duplicateOf = originalLead._id;
          duplicateReason = 'email';
        }
      }

      // Check for phone duplicates
      if (lead.phone && processedPhones.has(lead.phone)) {
        const originalLead = await collection.findOne({
          phone: lead.phone,
          _id: { $lt: lead._id }, // Earlier created lead
          isDuplicate: false
        });
        
        if (originalLead) {
          if (isDuplicate && duplicateOf.equals(originalLead._id)) {
            // Same original lead for both email and phone
            duplicateReason = 'both';
          } else if (!isDuplicate) {
            // Only phone duplicate
            isDuplicate = true;
            duplicateOf = originalLead._id;
            duplicateReason = 'phone';
          }
        }
      }

      // Update the lead if it's a duplicate
      if (isDuplicate) {
        await collection.updateOne(
          { _id: lead._id },
          {
            $set: {
              isDuplicate: true,
              duplicateOf: duplicateOf,
              duplicateReason: duplicateReason,
              duplicateDetectedAt: new Date()
            }
          }
        );
        duplicatesFound++;
        console.log(`Marked lead ${lead.leadId || lead._id} as duplicate (${duplicateReason})`);
      }

      // Add to processed sets
      if (lead.email) processedEmails.add(lead.email);
      if (lead.phone) processedPhones.add(lead.phone);
    }

    console.log(`Found and marked ${duplicatesFound} duplicate leads`);
    console.log('Migration completed successfully!');

  } catch (error) {
    console.error('Migration failed:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

// Run the migration
if (require.main === module) {
  addDuplicateFields()
    .then(() => {
      console.log('Migration script finished');
      process.exit(0);
    })
    .catch((error) => {
      console.error('Migration script failed:', error);
      process.exit(1);
    });
}

module.exports = addDuplicateFields;
