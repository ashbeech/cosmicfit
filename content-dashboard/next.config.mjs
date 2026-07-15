/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  experimental: {
    // The service-role Supabase client and argon2 are Node-only. Keep the native
    // argon2 addon out of the server bundle so it loads as a normal require().
    // Only middleware runs on the edge, and it uses jose (edge-safe) exclusively.
    serverComponentsExternalPackages: ['@node-rs/argon2'],
  },
};

export default nextConfig;
