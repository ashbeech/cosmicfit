import {
  compactVerify,
  decodeProtectedHeader,
  importX509,
} from "https://esm.sh/jose@5";
import { X509Certificate } from "https://esm.sh/@peculiar/x509@1";

// Apple Root CA - G3 (EC P-384), pinned for certificate chain validation.
// Download/verify: https://www.apple.com/certificateauthority/
// Serial: 2DC5FC88D2C54B95 | Expires: 2039-04-30
// SHA-256: 63343ABFB89A6A03EBB57E9B3F5FA7BE7C4FBE273862E828C84C6A302AE77147
const APPLE_ROOT_CA_G3_BASE64 =
  "MIICQzCCAcmgAwIBAgIILcX8iNLFS5UwCgYIKoZIzj0EAwMwZzEbMBkGA1UEAwwS" +
  "QXBwbGUgUm9vdCBDQSAtIEczMSYwJAYDVQQLDB1BcHBsZSBDZXJ0aWZpY2F0aW9u" +
  "IEF1dGhvcml0eTETMBEGA1UECgwKQXBwbGUgSW5jLjELMAkGA1UEBhMCVVMwHhcN" +
  "MTQwNDMwMTgxOTA2WhcNMzkwNDMwMTgxOTA2WjBnMRswGQYDVQQDDBJBcHBsZSBS" +
  "b290IENBIC0gRzMxJjAkBgNVBAsMHUFwcGxlIENlcnRpZmljYXRpb24gQXV0aG9y" +
  "aXR5MRMwEQYDVQQKDApBcHBsZSBJbmMuMQswCQYDVQQGEwJVUzB2MBAGByqGSM49" +
  "AgEGBSuBBAAiA2IABJjpLz1AcqTtkyJygRMc3RCV8cWjTnHcFBbZDuWmBSp3ZHtf" +
  "TjjTuxxEtX/1H7YyYl3J6YRbTzBPEVoA/VhYDKX1DyxNB0cTddqXl5dvMVztK515" +
  "1Du0RmKi5jsIb3RRRKNC9CAwHhYPMjAxNDA0MzAxODE5MDZaFw0zOTA0MzAxODE5" +
  "MDZaMCEwHwYDVR0jBBgwFoAUu7DeoVgziJqkipnevr3rr9rLJKswCgYIKoZIzj0E" +
  "AwMDaAAwZQIxAIPpwcQWCIjGUNgiCvRgRXw3aBIRyGNm/S2+ZEGLinVWKTBpEvnh" +
  "vtwWalEK2JhBNQIwHFjNoC2t6FuLfQGQ2SEjBcUAMENOAT47p3pmj0FdOn5SjYlk" +
  "SQuODgmJXt7CiGBi";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface NotificationConfig {
  bundleId: string;
  appAppleId?: string;
  allowedProductIds: string[];
}

export interface VerifiedNotification {
  notificationType: string;
  subtype: string | undefined;
  notificationUUID: string;
  environment: string;
  bundleId: string;
  appAppleId: number | undefined;
  originalTransactionId: string | undefined;
  transactionId: string | undefined;
  productId: string | undefined;
  eventSignedAt: string | undefined;
}

export class VerificationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "VerificationError";
  }
}

interface NotificationPayload {
  notificationType: string;
  subtype?: string;
  notificationUUID: string;
  data: {
    appAppleId?: number;
    bundleId: string;
    bundleVersion?: string;
    environment: string;
    signedTransactionInfo?: string;
    signedRenewalInfo?: string;
  };
  version?: string;
  signedDate?: number;
}

interface TransactionPayload {
  originalTransactionId?: string;
  transactionId?: string;
  productId?: string;
  bundleId?: string;
}

// ---------------------------------------------------------------------------
// Main entry point
// ---------------------------------------------------------------------------

export async function verifyAndDecodeNotification(
  signedPayload: string,
  config: NotificationConfig,
): Promise<VerifiedNotification> {
  const notification = await verifySignedPayload<NotificationPayload>(signedPayload);

  if (!notification.notificationUUID || !notification.notificationType || !notification.data) {
    throw new VerificationError("Malformed notification payload");
  }

  if (notification.data.bundleId !== config.bundleId) {
    throw new VerificationError(
      `Bundle ID mismatch: got ${notification.data.bundleId}, expected ${config.bundleId}`,
    );
  }

  if (
    config.appAppleId &&
    notification.data.appAppleId !== undefined &&
    String(notification.data.appAppleId) !== config.appAppleId
  ) {
    throw new VerificationError("App Apple ID mismatch");
  }

  let transaction: TransactionPayload | undefined;
  if (notification.data.signedTransactionInfo) {
    transaction = await verifySignedPayload<TransactionPayload>(
      notification.data.signedTransactionInfo,
    );

    if (
      transaction.productId &&
      config.allowedProductIds.length > 0 &&
      !config.allowedProductIds.includes(transaction.productId)
    ) {
      throw new VerificationError(`Unknown product ID: ${transaction.productId}`);
    }
  }

  return {
    notificationType: notification.notificationType,
    subtype: notification.subtype,
    notificationUUID: notification.notificationUUID,
    environment: notification.data.environment,
    bundleId: notification.data.bundleId,
    appAppleId: notification.data.appAppleId,
    originalTransactionId: transaction?.originalTransactionId,
    transactionId: transaction?.transactionId,
    productId: transaction?.productId,
    eventSignedAt: notification.signedDate
      ? new Date(notification.signedDate).toISOString()
      : undefined,
  };
}

// ---------------------------------------------------------------------------
// JWS signature verification
// ---------------------------------------------------------------------------

async function verifySignedPayload<T>(jws: string): Promise<T> {
  const header = decodeProtectedHeader(jws);
  const x5c = header.x5c;
  if (!x5c || x5c.length < 2) {
    throw new VerificationError("Missing or insufficient x5c certificate chain in JWS header");
  }
  if (!header.alg) {
    throw new VerificationError("Missing alg in JWS header");
  }

  await verifyCertificateChain(x5c);

  const leafPem = derToPem(x5c[0]);
  const leafKey = await importX509(leafPem, header.alg);
  const { payload } = await compactVerify(jws, leafKey);
  return JSON.parse(new TextDecoder().decode(payload)) as T;
}

// ---------------------------------------------------------------------------
// Certificate chain validation against pinned Apple Root CA - G3.
// Handles chains of 2 certs (leaf + intermediate, root omitted)
// or 3 certs (leaf + intermediate + root).
// ---------------------------------------------------------------------------

async function verifyCertificateChain(x5c: string[]): Promise<void> {
  const certs = x5c.map((b64) => new X509Certificate(base64ToUint8Array(b64)));
  const pinnedRoot = new X509Certificate(base64ToUint8Array(APPLE_ROOT_CA_G3_BASE64));

  const now = new Date();
  for (let i = 0; i < certs.length; i++) {
    if (now < certs[i].notBefore || now > certs[i].notAfter) {
      throw new VerificationError(`Certificate at index ${i} is outside its validity period`);
    }
  }

  for (let i = 0; i < certs.length - 1; i++) {
    const issuerKey = await exportVerifyKey(certs[i + 1]);
    const ok = await certs[i].verify({ publicKey: issuerKey });
    if (!ok) {
      throw new VerificationError(`Certificate chain broken at index ${i}`);
    }
  }

  const anchor = certs[certs.length - 1];
  const anchorRaw = new Uint8Array(anchor.rawData);
  const pinnedRaw = new Uint8Array(pinnedRoot.rawData);
  if (uint8ArrayEquals(anchorRaw, pinnedRaw)) {
    return;
  }

  const rootKey = await exportVerifyKey(pinnedRoot);
  const signedByRoot = await anchor.verify({ publicKey: rootKey });
  if (!signedByRoot) {
    throw new VerificationError("Certificate chain does not terminate at Apple Root CA - G3");
  }
}

async function exportVerifyKey(cert: X509Certificate): Promise<CryptoKey> {
  return cert.publicKey.export(cert.publicKey.algorithm, ["verify"]);
}

// ---------------------------------------------------------------------------
// Utilities
// ---------------------------------------------------------------------------

function base64ToUint8Array(b64: string): Uint8Array {
  const bin = atob(b64);
  const arr = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) arr[i] = bin.charCodeAt(i);
  return arr;
}

function derToPem(b64Der: string): string {
  const lines: string[] = [];
  for (let i = 0; i < b64Der.length; i += 64) {
    lines.push(b64Der.substring(i, i + 64));
  }
  return `-----BEGIN CERTIFICATE-----\n${lines.join("\n")}\n-----END CERTIFICATE-----`;
}

function uint8ArrayEquals(a: Uint8Array, b: Uint8Array): boolean {
  if (a.length !== b.length) return false;
  for (let i = 0; i < a.length; i++) {
    if (a[i] !== b[i]) return false;
  }
  return true;
}
