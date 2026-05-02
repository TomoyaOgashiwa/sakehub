import type { Metadata } from 'next';
import { Geist, Geist_Mono } from 'next/font/google';
import './globals.css';

const geistSans = Geist({
  variable: '--font-geist-sans',
  subsets: ['latin'],
});

const geistMono = Geist_Mono({
  variable: '--font-geist-mono',
  subsets: ['latin'],
});

export const metadata: Metadata = {
  title: {
    default: 'SakeHub - Discover & Share Your Favorite Spirits',
    template: '%s | SakeHub',
  },
  description:
    'Explore, review, and share your favorite spirits. From whisky to sake, beer to cocktails — find your next drink on SakeHub.',
  keywords: ['sake', 'whisky', 'beer', 'wine', 'cocktail', 'spirits', 'review', 'rating'],
  openGraph: {
    type: 'website',
    locale: 'ja_JP',
    siteName: 'SakeHub',
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ja" className={`${geistSans.variable} ${geistMono.variable} h-full antialiased`}>
      <body className="flex min-h-full flex-col">{children}</body>
    </html>
  );
}
