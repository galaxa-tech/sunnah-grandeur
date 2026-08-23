const { initializeApp } = require('firebase/app');
const { getFirestore, collection, getDocs, deleteDoc, doc } = require('firebase/firestore');

const firebaseConfig = {
  projectId: "sunnah-grandeur",
  appId: "1:6748865044:web:a50ab96d823a83bacd1d01",
  storageBucket: "sunnah-grandeur.firebasestorage.app",
  apiKey: "AIzaSyDX3H10keVelz9HppzN_Y0BKqhPWRCqV8U",
  authDomain: "sunnah-grandeur.firebaseapp.com",
  messagingSenderId: "6748865044",
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function cleanData() {
  console.log('Fetching Firestore products and orders...');
  const collections = ['products', 'orders'];
  
  for (const col of collections) {
    const snap = await getDocs(collection(db, col));
    console.log(`Collection ${col}: ${snap.size} documents.`);
    for (const d of snap.docs) {
      const data = d.data();
      console.log(`Document [${d.id}]:`, data.name || data.trackingCode || data.id);
    }
  }
}

cleanData().catch(console.error);
