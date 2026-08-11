/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
  trailingSlash: false,
  output: 'standalone',
  distDir: '.next'  // 明确指定输出目录
}

module.exports = nextConfig
