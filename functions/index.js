// [aviv] Copied from Nerdster

const { logger } = require("firebase-functions");
const { onRequest } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Deployed! Try at: https://us-central1-one-of-us-net.cloudfunctions.net/export?token=2c3142d16cac3c5aeb6d7d40a4ca6beb7bd92431
exports.export = functions.https.onRequest(async (req, res) => {
  const token = req.query.token;

  if (!token) {
    return res.status(400).send('Missing collection name');
  }

  try {
    const db = admin.firestore();
    const collectionRef = db.collection(token).doc('statements').collection('statements');
    const snapshot = await collectionRef.get();

    const data = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

    res.status(200).json(data);
  } catch (error) {
    console.error(error);
    res.status(500).send('Error exporting collection');
  }
});
