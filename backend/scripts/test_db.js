const admin = require("firebase-admin");
admin.initializeApp({
  projectId: "sunnah-grandeur"
});
const db = admin.firestore();
db.collection("products").get().then(snap => {
  console.log("Count:", snap.size);
  snap.forEach(doc => console.log(doc.id, doc.data().title || doc.data().name));
  process.exit(0);
}).catch(err => {
  console.error(err);
  process.exit(1);
});
