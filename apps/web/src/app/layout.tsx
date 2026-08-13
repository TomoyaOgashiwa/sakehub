import type { Metadata } from 'next';
import { Geist, Geist_Mono } from 'next/font/google';

import { Footer } from '@/components/layouts/footer';
import { Header } from '@/components/layouts/header';

import { SWRProvider } from './swr-config';
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
    default: 'SakeHub - 銘柄を特定する',
    template: '%s | SakeHub',
  },
  description: 'ラベルや名前の手がかりから、商品単位で銘柄を探す。',
  keywords: ['sake', 'whisky', 'beer', 'wine', 'cocktail', 'spirits', 'identify', 'catalog'],
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
      <body className="flex min-h-full flex-col">
        <SWRProvider>
          <Header />
          <main className="flex-1">{children}</main>
          <Footer />
        </SWRProvider>
      </body>
    </html>
  );
}
