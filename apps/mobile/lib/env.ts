/**
 * Typed access to Expo public env vars without pulling in @types/node.
 * Values are inlined by Metro / Expo at bundle time.
 */
interface ExpoPublicEnv {
  EXPO_PUBLIC_SUPABASE_URL?: string;
  EXPO_PUBLIC_SUPABASE_ANON_KEY?: string;
  EXPO_PUBLIC_API_URL?: string;
}

declare const process: {
  env: ExpoPublicEnv;
};

declare const __DEV__: boolean | undefined;

function readEnv(name: keyof ExpoPublicEnv): string | undefined {
  return process.env[name];
}

function isDevRuntime(): boolean {
  return typeof __DEV__ !== 'undefined' && __DEV__;
}

/**
 * Required env vars fail fast in production builds.
 * In __DEV__, optional `devFallback` keeps local DX without masking prod misconfig.
 */
function requireEnv(name: keyof ExpoPublicEnv, devFallback?: string): string {
  const value = readEnv(name);
  if (value) return value;

  if (isDevRuntime() && devFallback !== undefined) {
    console.warn(`[env] Missing ${name}; using development fallback.`);
    return devFallback;
  }

  throw new Error(`Missing required env: ${name}`);
}

export const env = {
  supabaseUrl: requireEnv('EXPO_PUBLIC_SUPABASE_URL', 'http://localhost:54321'),
  supabaseAnonKey: requireEnv('EXPO_PUBLIC_SUPABASE_ANON_KEY'),
  apiUrl: requireEnv('EXPO_PUBLIC_API_URL', 'http://localhost:8080'),
} as const;
