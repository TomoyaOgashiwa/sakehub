import { TimezoneSync } from './timezone-sync';

export default function MyLogsLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <>
      <TimezoneSync />
      {children}
    </>
  );
}
