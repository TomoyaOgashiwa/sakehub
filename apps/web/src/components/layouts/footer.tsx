export function Footer() {
  return (
    <footer className="border-t">
      <div className="mx-auto flex h-16 max-w-7xl items-center justify-center px-4">
        <p className="text-muted-foreground text-sm">
          &copy; {new Date().getFullYear()} SakeHub. All rights reserved.
        </p>
      </div>
    </footer>
  );
}
