"use strict";

const { HttpsError } = require("firebase-functions/v2/https");

/**
 * Validates request data against a schema.
 *
 * Schema field options:
 *   required : boolean
 *   type     : 'string' | 'number' | 'boolean' | 'object' | 'array'
 *   enum     : string[]         — allowed values
 *   min      : number           — minimum value (numbers) or min length (strings/arrays)
 *   max      : number           — maximum value (numbers) or max length
 *   pattern  : RegExp           — string pattern
 *   integer  : boolean          — number must be integer
 *   positive : boolean          — number must be > 0
 *
 * Throws HttpsError('invalid-argument', ...) on first failure.
 */
function validate(data, schema) {
  if (!data || typeof data !== "object") {
    throw new HttpsError("invalid-argument", "Request data must be an object.");
  }

  for (const [field, rules] of Object.entries(schema)) {
    const value = data[field];
    const missing = value === undefined || value === null || value === "";

    if (rules.required && missing) {
      throw new HttpsError("invalid-argument", `'${field}' is required.`);
    }
    if (missing) continue;

    if (rules.type === "array") {
      if (!Array.isArray(value)) {
        throw new HttpsError("invalid-argument", `'${field}' must be an array.`);
      }
      if (rules.min !== undefined && value.length < rules.min) {
        throw new HttpsError("invalid-argument", `'${field}' must contain at least ${rules.min} item(s).`);
      }
      if (rules.max !== undefined && value.length > rules.max) {
        throw new HttpsError("invalid-argument", `'${field}' must contain at most ${rules.max} item(s).`);
      }
    } else if (rules.type && typeof value !== rules.type) {
      throw new HttpsError("invalid-argument", `'${field}' must be a ${rules.type}.`);
    }

    if (rules.type === "number" || typeof value === "number") {
      if (rules.integer && !Number.isInteger(value)) {
        throw new HttpsError("invalid-argument", `'${field}' must be an integer.`);
      }
      if (rules.positive && value <= 0) {
        throw new HttpsError("invalid-argument", `'${field}' must be a positive number.`);
      }
      if (rules.min !== undefined && value < rules.min) {
        throw new HttpsError("invalid-argument", `'${field}' must be at least ${rules.min}.`);
      }
      if (rules.max !== undefined && value > rules.max) {
        throw new HttpsError("invalid-argument", `'${field}' must be at most ${rules.max}.`);
      }
    }

    if (rules.type === "string" || typeof value === "string") {
      if (rules.min !== undefined && value.length < rules.min) {
        throw new HttpsError("invalid-argument", `'${field}' must be at least ${rules.min} characters.`);
      }
      if (rules.max !== undefined && value.length > rules.max) {
        throw new HttpsError("invalid-argument", `'${field}' must be at most ${rules.max} characters.`);
      }
      if (rules.pattern && !rules.pattern.test(value)) {
        throw new HttpsError("invalid-argument", `'${field}' has an invalid format.`);
      }
    }

    if (rules.enum && !rules.enum.includes(value)) {
      throw new HttpsError("invalid-argument",
        `'${field}' must be one of: ${rules.enum.join(", ")}.`);
    }
  }
}

module.exports = { validate };
