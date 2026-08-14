import type { Metadata } from 'next';

import { requireAdminPage } from '@/lib/auth/app-role';

export const metadata: Metadata = {
  title: '運営',
  robots: { index: false, follow: false },
};

export default async function AdminLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  await requireAdminPage();
  return children;
}
