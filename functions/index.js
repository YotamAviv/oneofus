// [aviv] Copied from Nerdster

const { logger } = require("firebase-functions");
const { onRequest } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Deployed! Try at: https://us-central1-one-of-us-net.cloudfunctions.net/export?token=2c3142d16cac3c5aeb6d7d40a4ca6beb7bd92431
// This sort of works when running from the Nerdster directory, and should be here with the updated config file:
// http://127.0.0.1:5002/one-of-us-net/us-central1/export2?token=<token>
exports.export2 = onRequest(async (req, res) => {
  const token = req.query.token;
  if (!token) return res.status(400).send('Missing token');

  const key2order = {
    'statement': 0, 'time': 1, 'I': 2,
    'clear': 7,
    // Oneofus verbs
     'trust': 3, 'block': 4, 'replace': 5, 'delegate': 6,
    // Nerdster verbs
    // 'rate': 8, 'censor': 9, 'relate': 10, 'dontRelate': 11, 'equate': 12, 'dontEquate': 13, 'follow': 14,
    'with': 16,
    // Oneofus with
     'moniker': 18, 'revokeAt': 19, 'domain': 20,
    // Nerdster with
    // 'tags': 21, 'recommend': 22, 'dismiss': 23, 'stars': 24, 'comment': 25, 'contentType': 26, 'other': 17,
    'previous': 27, 'signature': 28
  };

  try {
    const db = admin.firestore();
    const collectionRef = db.collection(token).doc('statements').collection('statements');
    const snapshot = await collectionRef.orderBy('time', 'desc').get();
    const data = snapshot.docs.map(doc => doc.data());

    var data2 = [];
    for (const datum of data) {
      const orderedDatum = Object.keys(datum)
        .sort((a, b) => ((key2order[a] ?? 40) - (key2order[b] ?? 40)))
        // .sort((a, b) => compareKeys(a, b))
        .reduce((obj, key) => {
          obj[key] = datum[key];
          return obj;
        }, {});
      data2.push(orderedDatum);
    }

    res.status(200).json(data2);
  } catch (error) {
    console.error(error);
    res.status(500).send('Error exporting collection');
  }
});
