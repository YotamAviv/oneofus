
/// 
/// I often forget and then see it in the logs.. (to run in the functions directory)
/// - "npm install"
/// - "npm install --save firebase-functions@latest"
/// - "npm audit fix"
/// 
/// TEST: Would be nice to see that these all produce output we expect:
/// http://127.0.0.1:5001/nerdster/us-central1/export2?token=f4e45451dd663b6c9caf90276e366f57e573841b
/// http://127.0.0.1:5001/nerdster/us-central1/export2?token=f4e45451dd663b6c9caf90276e366f57e573841b&includeId=true&&checkPrevious=true&revokeAt=254267baf5859ba52100f42c3df6aebc4be6dc56
/// http://127.0.0.1:5001/nerdster/us-central1/export2?token=f4e45451dd663b6c9caf90276e366f57e573841b&includeId=true&orderStatements=true&checkPrevious=true&revokeAt=sincealways
/// http://127.0.0.1:5001/nerdster/us-central1/export2?token=f4e45451dd663b6c9caf90276e366f57e573841b&includeId=true&orderStatements=true&distinct=true
/// http://127.0.0.1:5001/nerdster/us-central1/export2?token=f4e45451dd663b6c9caf90276e366f57e573841b&includeId=true&orderStatements=true
/// http://127.0.0.1:5001/nerdster/us-central1/export2?token=f4e45451dd663b6c9caf90276e366f57e573841b&includeId=true&orderStatements=true&clearClear=true
/// http://127.0.0.1:5001/nerdster/us-central1/export2?token=f4e45451dd663b6c9caf90276e366f57e573841b&includeId=true&orderStatements=true&distinct=true&clearClear=true&omit=[%22I%22,%22statement%22]

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

// ----------- copy/pasted from <nerdster>/js ---------------------------------------------------//

var key2order = {
  "statement": 0,
  "time": 1,
  "I": 2,
  "trust": 3,
  "block": 4,
  "replace": 5,
  "delegate": 6,
  "clear": 7,
  "rate": 8,
  "censor": 9,
  "relate": 10,
  "dontRelate": 11,
  "equate": 12,
  "dontEquate": 13,
  "follow": 14,
  "with": 16,
  "other": 17,
  "moniker": 18,
  "revokeAt": 19,
  "domain": 20,
  "tags": 21,
  "recommend": 22,
  "dismiss": 23,
  "stars": 24,
  "comment": 25,
  "contentType": 26,
  "previous": 27,
  "signature": 28
};

async function computeSHA1(str) {
  const buffer = new TextEncoder("utf-8").encode(str);
  const hash = await crypto.subtle.digest("SHA-1", buffer);
  return Array.from(new Uint8Array(hash))
    .map(x => x.toString(16).padStart(2, '0'))
    .join('');
}

function compareKeys(key1, key2) {
  // console.log(`compareKeys(${key1}, ${key2})`);
  // Keys we know have an order; others are ordered alphabetically below keys we know except signature.
  // TODO: Is that correct about 'signature' below unknown keys?
  const key1i = key2order[key1];
  const key2i = key2order[key2];
  var out;
  if (key1i != null && key2i != null) {
    out = key1i - key2i;
  } else if (key1i == null && key2i == null) {
    out = key1 < key2 ? -1 : 1;
  } else if (key1i != null) {
    out = -1;
  } else {
    out = 1;
  }
  // console.log(`compareKeys(${key1}, ${key2})=${out}`);
  return out;
}


function order(thing) {
  if (typeof thing === 'string') {
    return thing;
  } else if (typeof thing === 'boolean') {
    return thing;
  } else if (typeof thing === 'number') {
    return thing;
  } else if (Array.isArray(thing)) {
    return thing.map((x) => order(x));
  } else {
    const signature = thing.signature; // signature last
    const { ['signature']: excluded, ...signatureExcluded } = thing;
    var out = Object.keys(signatureExcluded)
      .sort((a, b) => compareKeys(a, b))
      .reduce((obj, key) => {
        obj[key] = order(thing[key]);
        return obj;
      }, {});
    if (signature) out.signature = signature;
    return out;
  }
}

async function keyToken(input) {
  if (typeof input === 'string') {
    return input;
  } else {
    const ordered = order(input);
    var ppJson = JSON.stringify(ordered, null, 2);
    var token = await computeSHA1(ppJson);
    return token;
  }
}

// -----------  --------------------------------------------------------//

const verbs = [
  'trust',
  'delegate',
  'clear',
  'rate',
  'follow',
  'censor',
  'relate',
  'dontRelate',
  'equate',
  'dontEquate',
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

// -----------  --------------------------------------------------------//

/// DEFER: Cloud distinct to regard "other" subject.
/// All the pieces are there, and it shouldn't be hard. That said, relate / equate are rarely used.

/// CONSIDER: Do we really need "I" or "lastToken"?
/// - revokedAt means we're revoked, and so we shouldn't be writing new statements anyway. But 
///   maybe we do.
/// - if we send "clear" statements, then we'll always send the last statement (even if it's clear, 
///   even if we make distinct)
/// - If we're omitting "I", we can still include it on the top statemement.
/// All this feels kludgey, and so I'll leave things as they are.

// clearClear only applicable with distinct
async function fetchh(token, params = {}, omit = {}) {
  const revokeAt = params.revokeAt;
  const checkPrevious = params.checkPrevious != null;
  const distinct = params.distinct != null;
  const orderStatements = params.orderStatements != 'false'; // On by default for demo.
  const clearClear = params.clearClear != null;
  const includeId = params.includeId != null;

  if (!token) throw 'Missing token';
  if (clearClear && !distinct) throw 'clearClear only applicable with distinct';

  const db = admin.firestore();
  const collectionRef = db.collection(token).doc('statements').collection('statements');

  var revokedAtTime;
  if (revokeAt) {
    const doc = collectionRef.doc(revokeAt);
    const docSnap = await doc.get();
    if (docSnap.data()) {
      logger.log(`found revokedAt doc`);
      revokedAtTime = docSnap.data().time;
      logger.log(`revokedAtTime=${revokedAtTime}`);
    } else {
      logger.log(`didn't find revokedAt doc`);
      // TODO: Boundary conditions testing.
      return { "statements": [] };
    }
  }

  var snapshot;
  if (revokedAtTime) {
    snapshot = await collectionRef.where('time', "<=", revokedAtTime).orderBy('time', 'desc').get();
  } else {
    snapshot = await collectionRef.orderBy('time', 'desc').get();
  }

  var statements;
  if (includeId) {
    statements = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  } else {
    statements = snapshot.docs.map(doc => doc.data());
  }

  // Do this early (first) before distinct and/or other calls below.
  var iKey;
  var lastToken;
  if (statements.length > 0) {
    iKey = statements[0].I;
    lastToken = statements[0].id; // BUG: We don't get lastToken unless we asked for ID.
  }

  if (checkPrevious) {
    // Validate notary chain, decending order
    var first = true;
    var previousToken;
    var previousTime;
    for (var d of statements) {
      if (first) {
        first = false; // no check
      } else {
        if (d.id != previousToken) {
          var error = `Notarization violation: ${d.id} != ${previousToken}`;
          logger.error(error);
          throw error;
        }

        if (d.time >= previousTime) {
          var error = `Not descending: ${d.time} >= ${previousTime}`;
          logger.error(error);
          throw error;
        }
      }
      previousToken = d.previous;
      previousTime = d.time;
    }
  }

  if (omit) {
    for (var s of statements) {
      for (const key of omit) {
        delete s[key];
      }
    }
  }

  if (distinct) {
    statements = await makedistinct(statements, clearClear);
  }

  // order statements
  if (orderStatements) {
    var list = [];
    for (const statement of statements) {
      const ordered = order(statement);
      list.push(ordered);
    }
    statements = list;
  }

  return { "statements": statements, "I": iKey, "lastToken": lastToken };
}


// JSON export
// from: Google AI: https://www.google.com/search?q=Firebase+function+HTTP+GET+export+collection&oq=Firebase+function+HTTP+GET+export+collection&gs_lcrp=EgZjaHJvbWUyBggAEEUYOTIGCAEQRRhA0gEIOTYzMmowajSoAgCwAgE&sourceid=chrome&ie=UTF-8
// - Emulator-Nerdster-Yotam: 
//   http://127.0.0.1:5001/nerdster/us-central1/export2?token=f4e45451dd663b6c9caf90276e366f57e573841b
// - Emulator-Oneofus-Yotam:
//   http://127.0.0.1:5002/one-of-us-net/us-central1/export2?token=2c3142d16cac3c5aeb6d7d40a4ca6beb7bd92431&includeId=true&orderStatements=true
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
  const omit = req.query.omit ? JSON.parse(req.query.omit) : null;
  try {
    const retval = await fetchh(token, req.query, omit);
    res.status(200).json(retval);
  } catch (error) {
    console.error(error);
    res.status(500).send(`Error: ${error}`);
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

// Only considers subject of verb, does not consider otherSubject.
async function makedistinct(input, clearClear = false) {
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
    if (clearClear) {
      if (verb == 'clear') continue;
    }
    // PERFORMANCE: Teach Dart Jsonish to accept our token so that we can delete [signature, previous]
    out.push(j);
  }
  return out;
}

/// Used to Work on emulator: http://127.0.0.1:5001/nerdster/us-central1/clouddistinct?token=f4e45451dd663b6c9caf90276e366f57e573841b
// exports.clouddistinct = onRequest(async (req, res) => {
exports.clouddistinct = onCall(async (request) => {
  // const token = req.query.token;
  const token = request.data.token;
  logger.log(request.data);
  try {
    return await fetchh(token, request.data, request.data.omit);
  } catch (error) {
    console.error(error);
    throw new HttpsError(error);
  }
});
