"use strict";
/**
 * Reuses the local Firebase CLI's OAuth session (from `firebase login`) to
 * mint a Google access token, so admin scripts can run without a separate
 * service account key. Requires the machine to already be `firebase login`'d.
 */
const fs = require("fs");
const os = require("os");
const path = require("path");
const { UserRefreshClient } = require("google-auth-library");

// Public OAuth client used by the open-source firebase-tools CLI itself.
const CLIENT_ID = "563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com";
const CLIENT_SECRET = "j9iVZfS8kkCEFUPaAeJV0sAi";

function loadRefreshToken() {
  const candidates = [
    path.join(os.homedir(), ".config", "configstore", "firebase-tools.json"),
    process.env.APPDATA ? path.join(process.env.APPDATA, "configstore", "firebase-tools.json") : null,
  ].filter(Boolean);
  const file = candidates.find((f) => fs.existsSync(f));
  if (!file) throw new Error("Could not find firebase-tools.json in " + candidates.join(" or "));
  const data = JSON.parse(fs.readFileSync(file, "utf8"));
  const token = data.tokens && data.tokens.refresh_token;
  if (!token) throw new Error("No cached Firebase CLI refresh token found. Run `firebase login` first.");
  return token;
}

async function getAccessToken() {
  const refreshToken = loadRefreshToken();
  const client = new UserRefreshClient(CLIENT_ID, CLIENT_SECRET, refreshToken);
  const { token } = await client.getAccessToken();
  return token;
}

/** Credential object compatible with firebase-admin's initializeApp({credential}). */
function cliCredential() {
  return {
    getAccessToken: async () => {
      const access_token = await getAccessToken();
      return { access_token, expires_in: 3000 };
    },
  };
}

module.exports = { getAccessToken, cliCredential };
