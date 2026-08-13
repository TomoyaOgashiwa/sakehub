import type { Metadata } from 'next';
import Link from 'next/link';
import { ArrowLeft } from 'lucide-react';

import { DrinkLogBatchForm } from '@/components/drink-logs/drink-log-batch-form';
import { Heading } from '@/components/ui/heading';

export const metadata: Metadata = {
  title: '飲んだ記録を追加',
};

export default async function NewDrinkLogPage() {
  return (
    <div className="mx-auto max-w-2xl px-4 py-12">
      <nav className="mb-6">
        <Link
          href="/my-logs"
          className="text-muted-foreground hover:text-foreground inline-flex items-center gap-1 text-sm transition-colors"
        >
          <ArrowLeft className="size-4" aria-hidden="true" />
          記録一覧に戻る
        </Link>
      </nav>

      <Heading level="h1" className="mb-2">
        飲んだ記録を追加
      </Heading>
      <p className="text-muted-foreground mb-8 text-sm">
        いつ・何を・どこで飲んだかをまとめて残せます。カタログに無い銘柄もそのまま追加できます。
      </p>

      <DrinkLogBatchForm mode="create" />
    </div>
  );
}
