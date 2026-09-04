"use strict";
const { getAccessToken } = require("./_cli_auth");

const BASE = "https://firestore.googleapis.com/v1/projects/sunnah-grandeur/databases/(default)/documents";

function toValue(v) {
  if (v === null || v === undefined) return { nullValue: null };
  if (typeof v === "string") return { stringValue: v };
  if (typeof v === "boolean") return { booleanValue: v };
  if (typeof v === "number") return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(toValue) } };
  if (typeof v === "object") return { mapValue: { fields: toFields(v) } };
  throw new Error("Unsupported value type: " + typeof v);
}

function toFields(obj) {
  const fields = {};
  for (const [k, v] of Object.entries(obj)) {
    if (v === undefined) continue;
    fields[k] = toValue(v);
  }
  return fields;
}

async function req(method, path, body) {
  const token = await getAccessToken();
  const res = await fetch(BASE + path, {
    method,
    headers: { Authorization: "Bearer " + token, "Content-Type": "application/json" },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let json;
  try { json = JSON.parse(text); } catch { json = text; }
  if (!res.ok) throw new Error(`${method} ${path} -> ${res.status}: ${JSON.stringify(json)}`);
  return json;
}

async function listCollection(name) {
  const json = await req("GET", `/${name}?pageSize=300`);
  return json.documents || [];
}

async function deleteDoc(collection, id) {
  await req("DELETE", `/${collection}/${id}`);
}

const DELETE_FIELD = Symbol("delete-field");

async function patchDoc(collection, id, data) {
  const mask = Object.keys(data).map((k) => `updateMask.fieldPaths=${encodeURIComponent(k)}`).join("&");
  const kept = {};
  for (const [k, v] of Object.entries(data)) {
    if (v !== DELETE_FIELD) kept[k] = v;
  }
  await req("PATCH", `/${collection}/${id}?${mask}`, { fields: toFields(kept) });
}

async function createDoc(collection, data) {
  return req("POST", `/${collection}`, { fields: toFields(data) });
}

module.exports = { listCollection, deleteDoc, patchDoc, createDoc, DELETE_FIELD };
