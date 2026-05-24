'use client';

import { useState } from 'react';

import { Star } from 'lucide-react';

import { cn } from '@/utils/utils';

interface StarRatingDisplayProps {
  value: number;
  max?: number;
  size?: 'sm' | 'md' | 'lg';
  showValue?: boolean;
  count?: number;
  className?: string;
}

interface StarRatingInputProps {
  value: number | null;
  onChange: (rating: number) => void;
  max?: number;
  size?: 'sm' | 'md' | 'lg';
  disabled?: boolean;
  className?: string;
}

const sizeClasses = {
  sm: 'size-4',
  md: 'size-5',
  lg: 'size-6',
};

/**
 * StarRatingDisplay — read-only star display for average ratings.
 * Renders filled / partially-filled / empty stars based on `value`.
 */
export function StarRatingDisplay({
  value,
  max = 5,
  size = 'md',
  showValue = true,
  count,
  className,
}: StarRatingDisplayProps) {
  const clampedValue = Math.max(0, Math.min(value, max));

  return (
    <div
      className={cn('flex items-center gap-1.5', className)}
      aria-label={`評価: ${clampedValue.toFixed(1)} / ${max}`}
      role="img"
    >
      <div className="flex items-center gap-0.5">
        {Array.from({ length: max }, (_, i) => {
          const fill = Math.max(0, Math.min(1, clampedValue - i));
          return <StarIcon key={i} fill={fill} size={size} index={i} />;
        })}
      </div>
      {showValue && (
        <span className="text-muted-foreground text-sm tabular-nums">
          {clampedValue > 0 ? (
            <>
              <span className="text-foreground font-medium">{clampedValue.toFixed(1)}</span>
              {count != null && <span className="ml-1">({count}件)</span>}
            </>
          ) : (
            <span>まだ評価がありません</span>
          )}
        </span>
      )}
    </div>
  );
}

/**
 * StarRatingInput — interactive 1-5 star selector.
 * Calls onChange immediately on click for a one-tap UX.
 * Supports keyboard navigation (arrow keys, Home, End).
 */
export function StarRatingInput({
  value,
  onChange,
  max = 5,
  size = 'md',
  disabled = false,
  className,
}: StarRatingInputProps) {
  const [hover, setHover] = useState<number | null>(null);

  const activeValue = hover ?? value;

  const handleKeyDown = (e: React.KeyboardEvent<HTMLButtonElement>, current: number) => {
    if (disabled) return;
    switch (e.key) {
      case 'ArrowRight':
      case 'ArrowUp':
        e.preventDefault();
        onChange(Math.min(max, current + 1));
        break;
      case 'ArrowLeft':
      case 'ArrowDown':
        e.preventDefault();
        onChange(Math.max(1, current - 1));
        break;
      case 'Home':
        e.preventDefault();
        onChange(1);
        break;
      case 'End':
        e.preventDefault();
        onChange(max);
        break;
    }
  };

  return (
    <div
      className={cn('flex items-center gap-0.5', className)}
      role="radiogroup"
      aria-label="評価を選択"
      onMouseLeave={() => setHover(null)}
    >
      {Array.from({ length: max }, (_, i) => {
        const starValue = i + 1;
        const isActive = activeValue != null && starValue <= activeValue;

        return (
          <button
            key={starValue}
            type="button"
            role="radio"
            aria-checked={value === starValue}
            aria-label={`${starValue}つ星`}
            disabled={disabled}
            tabIndex={value === starValue || (value == null && starValue === 1) ? 0 : -1}
            className={cn(
              'focus-visible:ring-ring rounded-sm transition-transform focus-visible:ring-2 focus-visible:outline-none',
              disabled
                ? 'cursor-default opacity-50'
                : 'cursor-pointer hover:scale-110 active:scale-95',
            )}
            onClick={() => !disabled && onChange(starValue)}
            onMouseEnter={() => !disabled && setHover(starValue)}
            onKeyDown={(e) => handleKeyDown(e, value ?? 0)}
          >
            <Star
              className={cn(
                sizeClasses[size],
                'transition-colors',
                isActive ? 'fill-amber-400 stroke-amber-400' : 'stroke-muted-foreground fill-none',
              )}
              aria-hidden="true"
            />
          </button>
        );
      })}
    </div>
  );
}

/** Internal helper that renders a single star with a fractional fill level. */
function StarIcon({
  fill,
  size,
  index,
}: {
  fill: number;
  size: 'sm' | 'md' | 'lg';
  index: number;
}) {
  const id = `star-clip-${index}`;

  if (fill >= 1) {
    return (
      <Star
        className={cn(sizeClasses[size], 'fill-amber-400 stroke-amber-400')}
        aria-hidden="true"
      />
    );
  }
  if (fill <= 0) {
    return (
      <Star
        className={cn(sizeClasses[size], 'stroke-muted-foreground/40 fill-none')}
        aria-hidden="true"
      />
    );
  }

  // Partial fill via SVG clipPath
  return (
    <svg
      className={sizeClasses[size]}
      viewBox="0 0 24 24"
      aria-hidden="true"
      xmlns="http://www.w3.org/2000/svg"
    >
      <defs>
        <clipPath id={id}>
          <rect x="0" y="0" width={24 * fill} height="24" />
        </clipPath>
      </defs>
      {/* Empty star outline */}
      <path
        d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"
        fill="none"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
        className="text-muted-foreground/40"
      />
      {/* Filled portion */}
      <path
        d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"
        fill="#fbbf24"
        stroke="#fbbf24"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
        clipPath={`url(#${id})`}
      />
    </svg>
  );
}
