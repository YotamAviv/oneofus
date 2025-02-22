// TODO:
// Pressing:
// - Fix Yotam data corruption, would be nice to get support from export with ids (tokens)
// - Prototype performance enhancements on Oneofus (would be nice to have identical index.js functions file)
// - integration tests
//   - Implement, test: revokedAt
// Can be later:
// - Clean this up
// - Organize the file, use Javascript helpers and constants
// - try to unify Nerdster and Oneofus. Any reason they can't be identical?
//   - different verbs, but I can just include all verbs, no worries
// - JavaScript unit testing
// - Export clouddistinct to the HTTP interface (at least for debugging, demonstrating..) 
// - Rename "id" to "token"
// - Test boundary condition of empty// - 
// 
// I often forget and then see it in the logs.. (to run in the functions directory)
// - "npm install"
// - "npm install --save firebase-functions@latest"
// - "npm audit fix"
// 

const { logger } = require("firebase-functions");
const { onRequest } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const fetch = require("node-fetch");
const cheerio = require('cheerio'); // For HTML parsing

admin.initializeApp();


// This works and is used to develop fetchtitle below.
// Take the url parameter passed to this HTTP endpoint and insert it into
// Firestore under the path /urls/:documentId/url
exports.addurl = onRequest(async (req, res) => {
  const url = req.query.url;
  const db = admin.firestore();
  const writeResult = db
    .collection("urls")
    .add({ url: url });
  // Send back a message that we've successfully written the message
  res.json({ result: `Message with ID: ${writeResult.id} added.` });
});

// This is live and actively used by Nerdster to fetch HTML titles from URLs.
// Listens for new urls added to /urls/:documentId/url
// and saves the fetched title to /urls/:documentId/uppercase
exports.fetchtitle = onDocumentCreated("/urls/{documentId}", async (event) => {
  // Grab the current value of what was written to Firestore.
  const url = event.data.data().url;

  // Access the parameter `{documentId}` with `event.params`
  logger.log("fetching", event.params.documentId, url);
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`Failed to fetch URL: ${response.status}`);
  }

  const html = await response.text();
  const $ = cheerio.load(html);
  const title = $('title').text(); // .trim()?

  return event.data.ref.set({ title }, { merge: true });
});

// Jsonish'ish needs here in JavaScript:
// - sort keys in a doc (JS dictionary) for pretty exports for demo ("statement", "time", "I", "trust", "with", "previous", "signature")
// - sort keys in a JS dictionary for distinct based on subjects and keys ("contentType", "author", "title")
// Statement'ish needs here in JavaScript:
// - get subject of verb for  distinct based on subjects.

// Demo / debugging needs
// Export the cloud functions, include id/token

// Performance needs / desires
// - Distinct
//   Doesn't have to be complete and correct to be helpful
// - revokedAt 
//   required as applying distinct may clear the revokedAt token.
// - Filters, like say, fetch?verbs={censor:all, rate:month}.. complicated.. not necessarily helpful '
//   anyway considering where "dis" is, how I either should or shouldn't an entire subject..
// 

// JSON export
// from: Google AI: https://www.google.com/search?q=Firebase+function+HTTP+GET+export+collection&oq=Firebase+function+HTTP+GET+export+collection&gs_lcrp=EgZjaHJvbWUyBggAEEUYOTIGCAEQRRhA0gEIOTYzMmowajSoAgCwAgE&sourceid=chrome&ie=UTF-8
// - Emulator-Nerdster-Yotam: http://127.0.0.1:5001/nerdster/us-central1/export2?token=f4e45451dd663b6c9caf90276e366f57e573841b
// - Emulator-Oneofus-Yotam: http://127.0.0.1:5002/one-of-us-net/us-central1/export2?token=2c3142d16cac3c5aeb6d7d40a4ca6beb7bd92431
// - Prod-Nerdster-Yotam: https://us-central1-nerdster.cloudfunctions.net/export2?token=f4e45451dd663b6c9caf90276e366f57e573841b
// - Prod-Oneofus-Yotam: http://us-central1-one-of-us-net.cloudfunctions.net/export2?token=2c3142d16cac3c5aeb6d7d40a4ca6beb7bd92431
// 
// Updates from 10/18/24:
// - upgraded to v2 (in response to errors on command line)
// - mapped to https://export.nerdster.org/?token=f4e45451dd663b6c9caf90276e366f57e573841b
//   - https://console.cloud.google.com/run/domains?project=nerdster
//   - https://console.firebase.google.com/project/nerdster/functions/list
exports.export2 = onRequest(async (req, res) => {
  const token = req.query.token;
  if (!token) return res.status(400).send('Missing token');

  // I'm not commenting out the Oneofus verbs because I often run the emulator from the nerdster 
  // directory. Sloppy, not correct..
  const key2order = {
    'statement': 0, 'time': 1, 'I': 2,
    'clear': 7,
    // Oneofus verbs
    'trust': 3, 'block': 4, 'replace': 5, 'delegate': 6,
    // Nerdster verbs
    'rate': 8, 'censor': 9, 'relate': 10, 'dontRelate': 11, 'equate': 12, 'dontEquate': 13, 'follow': 14,
    'with': 16,
    // Oneofus with
    'moniker': 18, 'revokeAt': 19, 'domain': 20,
    // Nerdster with
    'tags': 21, 'recommend': 22, 'dismiss': 23, 'stars': 24, 'comment': 25, 'contentType': 26, 'other': 17,
    'previous': 27, 'signature': 28
  };

  // This works, but we're not recursing into the Maps or Lists, and so there's no need for it.
  // DEFER: Port more from Jsonish to sort the keys for display
  // function compareKeys(key1, key2) {
  //   // Keys we know have an order.
  //   // Keys we don't know are ordered alphabetically below keys we know except signature.
  //   const key1i = key2order[key1];
  //   const key2i = key2order[key2];
  //   var out;
  //   if (key1i != null && key2i != null) {
  //     out = key1i - key2i;
  //   } else if (key1i == null && key2i == null) {
  //     out =  key1.compareTo(key2);
  //   } else if (key1i != null) {
  //     out =  -1;
  //   } else {
  //     out =  1;
  //   }
  //   logger.log(`${key1} ${key2} ${out}`);
  //   return out;
  // }

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


// HTTP POST for QR signin (not 'signIn' (in camelCase) - that breaks things).
// The Nerdster should be listening for a new doc at collection /sessions/doc/<session>/
// The phone app should POST to this function (it used to write directly to the Nerdster Firebase collection.)
exports.signin = onRequest((req, res) => {
  const session = req.body.session;
  const db = admin.firestore();
  return db
    .collection("sessions")
    .doc("doc")
    .collection(session)
    .add(req.body).then(() => {
      res.status(201).json({});
    });
});

async function computeSHA1(str) {
  const buffer = new TextEncoder("utf-8").encode(str);
  const hash = await crypto.subtle.digest("SHA-1", buffer);
  return Array.from(new Uint8Array(hash))
    .map(x => x.toString(16).padStart(2, '0'))
    .join('');
}

function sortDictionaryByKey(dictionary) {
  const sortedKeys = Object.keys(dictionary).sort();
  const sortedDictionary = {};
  // TODO: Generalize this and merge with the export stuff
  if ("contentType" in dictionary) {
    sortedDictionary["contentType"] = dictionary["contentType"];
    // delete dictionary.contentType; // This delete makes it not be in sortedDictionary.
  }
  sortedKeys.forEach(key => {
    if (key != "contentType") {
      sortedDictionary[key] = dictionary[key];
    }
  });
  return sortedDictionary;
}

async function keyToken(input) {
  if (typeof input === 'string') {
    return input;
  } else {
    const sortedDict = sortDictionaryByKey(input);
    var ppJson = JSON.stringify(sortedDict, null, 2);
    var token = await computeSHA1(ppJson);
    return token;
  }
}


const verbs = [
  'rate',
  'clear',
  'follow',
  'censor',
  'relate',
  'dontRelate',
  'equate',
  'dontEquate',

  'trust',
  'delegate',
  'clear',
  'replace',
  'block',
];

function getVerbSubject(j) {
  for (var verb of verbs) {
    if (j[verb] != null) {
      return [verb, j[verb]];
    }
  }
  return null;
}

async function makedistinct(input) {
  var out = [];
  var already = new Set();
  for (var j of input) {
    var i = j['I'];
    const [verb, subject] = getVerbSubject(j);
    var key = await keyToken(subject);
    if (already.has(key)) continue;
    already.add(key);
    // Retain= 'clear' statements or not?
    // Pro: 
    // - Multiple delegates: use one to clear another's statement. 
    //   But we can make that the new semantics, have to censor something from your other 
    //   delegate, can't just clear.
    // Con:
    // - Performance.
    if (verb == 'clear') continue;
    delete j.I;
    delete j.statement;
    // TODO: Teach Dart Jsonish to accept our token so that we can delete [signature, previous]
    // delete j.signature;
    // delete j.previous;
    out.push(j);
  }
  return out;
}

/// Used to Work on emulator: http://127.0.0.1:5001/nerdster/us-central1/clouddistinct?token=f4e45451dd663b6c9caf90276e366f57e573841b
// exports.clouddistinct = onRequest(async (req, res) => {
exports.clouddistinct = onCall(async (request) => {
  // const token = req.query.token;
  const token = request.data.token;
  if (!token) return res.status(400).send('Missing token');

  try {
    const db = admin.firestore();
    const collectionRef = db.collection(token).doc('statements').collection('statements');
    const snapshot = await collectionRef.orderBy('time', 'desc').get();
    const data = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

    // Do this before distinct call below as the "delete" operations there affect the underlying objects.
    var iKey;
    var lastToken;
    if (data.length > 0) {
      iKey = data[0].I;
      lastToken = data[data.length - 1].id;
    }

    // Validate notary chain, decending order
    var first = true;
    var previousToken;
    var previousTime;
    for (var d of data) {
      if (first) {
        first = false; // no check
      } else {
        if (d.id != previousToken) {
          var error = `Notarization violation: ${d.id} != ${previousToken}`;
          logger.error(error);
          // TEMP: throw error;
        }

        if (d.time >= previousTime) {
          var error = `Not descending: ${d.time} >= ${previousTime}`;
          logger.error(error);
          // TEMP: throw error;
        }
      }
      previousToken = d.previous;
      previousTime = d.time;
    }

    var distinct = await makedistinct(data);

    return { "iKey": iKey, "lastToken": lastToken, "statements": distinct };
  } catch (error) {
    console.error(error);
    // res.status(500).send('Error exporting collection');
    throw new HttpsError(error);
  }
});
