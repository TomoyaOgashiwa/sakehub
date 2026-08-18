import type { ReactNode } from 'react';
import Link from 'next/link';
import { ChevronRight } from 'lucide-react';

import { cn } from '@/utils/utils';

import { profileHubRowClassName } from './profile-hub-styles';

interface ProfileHubLinkProps {
  href: string;
  children: ReactNode;
  className?: string;
}

export function ProfileHubLink({ href, children, className }: ProfileHubLinkProps) {
  return (
    <Link href={href} className={cn(profileHubRowClassName, className)}>
      <span>{children}</span>
      <ChevronRight className="text-muted-foreground size-4 shrink-0" aria-hidden="true" />
    </Link>
  );
}
