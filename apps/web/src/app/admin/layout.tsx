import type { Metadata } from 'next';

import { AdminNav } from '@/components/admin/admin-nav';
import { requireAdminPage } from '@/lib/auth/app-role';

export const metadata: Metadata = {
  title: '運営',
  robots: { index: false, follow: false },
};

export default async function AdminLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  await requireAdminPage();
  return (
    <div className="mx-auto max-w-3xl px-4 py-8">
      <AdminNav />
      {children}
    </div>
  );
}
