// Set only by the GitHub Pages deploy workflow, since that build is served
// from a subpath instead of the domain root. Firebase Hosting builds don't
// set this, so basePath stays empty there.
const basePath = process.env.GH_PAGES_BASE_PATH || '';

/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'export',
  basePath,
  images: {
    unoptimized: true,
  },
  eslint: {
    ignoreDuringBuilds: true,
  },
  typescript: {
    ignoreBuildErrors: true,
  },
};

export default nextConfig;
