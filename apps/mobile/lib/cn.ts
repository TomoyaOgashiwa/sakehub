import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

/** Merge NativeWind / Tailwind class names (web `cn` equivalent). */
export function cn(...inputs: ClassValue[]): string {
  return twMerge(clsx(inputs));
}
