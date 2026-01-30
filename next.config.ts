import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  images: {
    domains: ['images.barterpoint.co.ke'],
    deviceSizes: [320, 480, 768, 1024, 1280],
    imageSizes: [64, 96, 128, 256],
  },
  compress: true,
  poweredByHeader: false,
  experimental: {
    optimizeCss: true,
    scrollRestoration: true,
  },
  webpack(config) {
    config.module.rules.push({
      test: /\.svg$/,
      use: ['@svgr/webpack'],
    });

    return config;
  },
};

export default nextConfig;
