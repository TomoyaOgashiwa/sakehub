import { createElement, type ComponentPropsWithoutRef, type ElementType, type ReactNode } from 'react';

import { cn } from '@/utils/utils';

type HeadingLevel = Extract<ElementType, 'h1' | 'h2' | 'h3' | 'h4' | 'h5' | 'h6'>;

type HeadingProps = {
  level: HeadingLevel;
  children: ReactNode;
  className?: string;
} & Omit<ComponentPropsWithoutRef<'h1'>, 'className' | 'children'>;

export function Heading({ level, children, className, ...props }: HeadingProps) {
  return createElement(
    level,
    {
      ...props,
      className: cn(
        level === 'h1' && 'text-3xl font-bold tracking-tight text-balance sm:text-4xl',
        level === 'h2' && 'text-2xl font-bold tracking-tight text-balance sm:text-3xl',
        level === 'h3' && 'text-xl font-bold tracking-tight text-balance sm:text-2xl',
        level === 'h4' && 'text-lg font-bold tracking-tight text-balance sm:text-xl',
        level === 'h5' && 'text-base font-bold tracking-tight text-balance sm:text-lg',
        level === 'h6' && 'text-sm font-bold tracking-tight text-balance sm:text-base',
        className,
      ),
    },
    children,
  );
}
