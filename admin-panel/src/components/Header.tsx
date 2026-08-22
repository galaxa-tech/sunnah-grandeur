"use client";

interface HeaderProps {
  title: string;
}

export default function Header({ title }: HeaderProps) {
  return (
    <header className="flex justify-between items-center w-full px-8 py-4 sticky top-0 z-40 bg-background/80 backdrop-blur-md border-b border-outline-variant">
      <h2 className="font-headline-md text-headline-md text-primary">{title}</h2>
      <div className="flex items-center gap-6">
        <div className="relative hidden lg:block">
          <input
            className="bg-surface-container border-outline-variant text-on-surface-variant px-4 py-2 pl-10 focus:ring-primary focus:border-primary w-64 rounded-none text-sm"
            placeholder="Search data..."
            type="text"
          />
          <span className="material-symbols-outlined absolute left-3 top-2.5 text-on-surface-variant text-sm">
            search
          </span>
        </div>
        <div className="flex items-center gap-4">
          <button className="text-on-surface-variant hover:text-primary transition-colors scale-95 active:scale-90">
            <span className="material-symbols-outlined">notifications</span>
          </button>
          <button className="text-on-surface-variant hover:text-primary transition-colors scale-95 active:scale-90">
            <span className="material-symbols-outlined">account_circle</span>
          </button>
        </div>
      </div>
    </header>
  );
}
