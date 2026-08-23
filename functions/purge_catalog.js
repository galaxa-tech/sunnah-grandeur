const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

// Initialize with ADC / GCP project configuration
initializeApp({
  projectId: 'sunnah-grandeur',
});

const db = getFirestore();

async function purgeCatalog() {
  console.log('Fetching all product documents from Firestore...');
  const snapshot = await db.collection('products').get();
  console.log(`Found ${snapshot.size} product documents in /products collection.`);

  let deletedCount = 0;
  for (const doc of snapshot.docs) {
    console.log(`Deleting product ID ${doc.id} (${doc.data().name})...`);
    await doc.ref.delete();
    deletedCount++;
  }

  console.log(`Successfully purged ${deletedCount} product documents from Firestore!`);
}

purgeCatalog().catch((err) => {
  console.error('Purge error:', err);
  process.exit(1);
});
