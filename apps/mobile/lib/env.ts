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

function readEnv(name: keyof ExpoPublicEnv): string | undefined {
  return process.env[name];
}

export const env = {
  supabaseUrl: readEnv('EXPO_PUBLIC_SUPABASE_URL') ?? 'http://localhost:54321',
  supabaseAnonKey: readEnv('EXPO_PUBLIC_SUPABASE_ANON_KEY') ?? '',
  apiUrl: readEnv('EXPO_PUBLIC_API_URL') ?? 'http://localhost:8080',
} as const;
