import type { NextConfig } from 'next';

const isLocalDev = process.env.NODE_ENV !== 'production';

const nextConfig: NextConfig = {
  images: {
    // Next.js 16 は SSRF 対策で private IP（127.0.0.1 等）への画像取得を拒否する。
    // ローカル Supabase Storage（http://127.0.0.1:54321/...）を next/image で出すため、
    // 開発時のみ許可する。本番では *.supabase.co の public URL を使うので不要。
    ...(isLocalDev ? { dangerouslyAllowLocalIP: true } : {}),
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'ui-avatars.com',
        pathname: '/api/**',
      },
      // Supabase Storage (prod catalog-images / cocktail-images public URLs)
      {
        protocol: 'https',
        hostname: '*.supabase.co',
        pathname: '/storage/v1/object/public/**',
      },
      // Local Supabase Storage（開発時のみ。remotePatterns だけでは private IP 拒否を越えられない）
      ...(isLocalDev
        ? ([
            {
              protocol: 'http',
              hostname: '127.0.0.1',
              port: '54321',
              pathname: '/storage/v1/object/public/**',
            },
            {
              protocol: 'http',
              hostname: 'localhost',
              port: '54321',
              pathname: '/storage/v1/object/public/**',
            },
          ] as const)
        : []),
    ],
  },
};

export default nextConfig;
