import type { NextConfig } from 'next';

const isLocalDev = process.env.NODE_ENV !== 'production';

/** Single hosted Supabase project host for next/image (avoid `*.supabase.co`). */
function supabaseStorageHostname(): string | null {
  const raw = process.env.NEXT_PUBLIC_SUPABASE_URL;
  if (!raw) return null;
  try {
    const { hostname } = new URL(raw);
    return hostname.endsWith('.supabase.co') ? hostname : null;
  } catch {
    return null;
  }
}

const supabaseHost = supabaseStorageHostname();

const nextConfig: NextConfig = {
  images: {
    // Next.js 16 は SSRF 対策で private IP（127.0.0.1 等）への画像取得を拒否する。
    // ローカル Supabase Storage（http://127.0.0.1:54321/...）を next/image で出すため、
    // 開発時のみ許可する。本番では単一プロジェクトの public URL を使うので不要。
    ...(isLocalDev ? { dangerouslyAllowLocalIP: true } : {}),
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'ui-avatars.com',
        pathname: '/api/**',
      },
      // Supabase Storage (prod catalog-images / cocktail-images public URLs)
      ...(supabaseHost
        ? ([
            {
              protocol: 'https',
              hostname: supabaseHost,
              pathname: '/storage/v1/object/public/**',
            },
          ] as const)
        : []),
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
