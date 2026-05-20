// Cosmic Fit Inspector — Session + IndexedDB profile storage
'use strict';

const DB_NAME = 'cosmicfit-inspector';
const DB_VERSION = 1;
const STORE_PROFILES = 'profiles';
const SESSION_KEY = 'cosmicfit-inspector.session';

let dbPromise = null;

function openDB() {
  if (dbPromise) return dbPromise;
  dbPromise = new Promise((resolve, reject) => {
    const req = indexedDB.open(DB_NAME, DB_VERSION);
    req.onerror = () => reject(req.error);
    req.onupgradeneeded = () => {
      const db = req.result;
      if (!db.objectStoreNames.contains(STORE_PROFILES)) {
        const store = db.createObjectStore(STORE_PROFILES, { keyPath: 'id' });
        store.createIndex('updatedAt', 'updatedAt');
        store.createIndex('name', 'name', { unique: false });
      }
    };
    req.onsuccess = () => resolve(req.result);
  });
  return dbPromise;
}

function tx(storeName, mode, fn) {
  return openDB().then(db => new Promise((resolve, reject) => {
    const transaction = db.transaction(storeName, mode);
    const store = transaction.objectStore(storeName);
    let result;
    try {
      result = fn(store);
    } catch (e) {
      reject(e);
      return;
    }
    transaction.oncomplete = () => resolve(result);
    transaction.onerror = () => reject(transaction.error);
    transaction.onabort = () => reject(transaction.error);
  }));
}

export async function listProfiles() {
  const db = await openDB();
  return new Promise((resolve, reject) => {
    const tx = db.transaction(STORE_PROFILES, 'readonly');
    const store = tx.objectStore(STORE_PROFILES);
    const req = store.getAll();
    req.onsuccess = () => {
      const profiles = req.result || [];
      profiles.sort((a, b) => (b.updatedAt || 0) - (a.updatedAt || 0));
      resolve(profiles);
    };
    req.onerror = () => reject(req.error);
  });
}

export async function getProfile(id) {
  if (!id) return null;
  return tx(STORE_PROFILES, 'readonly', store => {
    return new Promise((resolve, reject) => {
      const req = store.get(id);
      req.onsuccess = () => resolve(req.result || null);
      req.onerror = () => reject(req.error);
    });
  });
}

export async function putProfile(profile) {
  return tx(STORE_PROFILES, 'readwrite', store => {
    store.put(profile);
  }).then(() => profile);
}

export async function deleteProfile(id) {
  if (!id) return;
  return tx(STORE_PROFILES, 'readwrite', store => {
    store.delete(id);
  });
}

export function newProfileId() {
  if (typeof crypto !== 'undefined' && crypto.randomUUID) {
    return crypto.randomUUID();
  }
  return `p_${Date.now()}_${Math.random().toString(36).slice(2, 10)}`;
}

export function readSession() {
  try {
    const raw = localStorage.getItem(SESSION_KEY);
    if (!raw) return null;
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

export function writeSession(session) {
  try {
    localStorage.setItem(SESSION_KEY, JSON.stringify(session));
  } catch (e) {
    console.warn('Failed to persist inspector session', e);
  }
}

export function clearSession() {
  try {
    localStorage.removeItem(SESSION_KEY);
  } catch { /* ignore */ }
}
