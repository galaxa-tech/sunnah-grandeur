"use client";
import { useState, useEffect, useRef } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useLanguageStore } from '@/store/useLanguageStore';
import { useThemeStore } from '@/store/useThemeStore';
import { translations, Lang } from '@/translations';
import { useCartStore } from '@/store/useCartStore';
import { products } from '@/data/products';
import { useAuth } from '@/context/AuthContext';
import AuthModal from '@/components/AuthModal';

export default function Navbar() {
  const pathname = usePathname();
  const [isScrolled, setIsScrolled] = useState(false);
  const [isLangOpen, setIsLangOpen] = useState(false);
  const [isUserOpen, setIsUserOpen] = useState(false);
  const [isMobileOpen, setIsMobileOpen] = useState(false);
  const [isSearchOpen, setIsSearchOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [totalCartCount, setTotalCartCount] = useState(0);
  const [showAuthModal, setShowAuthModal] = useState(false);

  const langRef = useRef<HTMLDivElement>(null);
  const userRef = useRef<HTMLDivElement>(null);

  const { language, setLanguage } = useLanguageStore();
  const { theme, toggleTheme } = useThemeStore();
  const { items, getTotalItems } = useCartStore();
  const { user, logOut } = useAuth();
  const t = translations[language];

  useEffect(() => {
    setTotalCartCount(getTotalItems());
  }, [items, getTotalItems]);

  useEffect(() => {
    if (typeof window !== 'undefined') {
      document.documentElement.dir = language === 'AR' ? 'rtl' : 'ltr';
      document.documentElement.lang = language.toLowerCase();
    }
  }, [language]);

  useEffect(() => {
    const handleScroll = () => setIsScrolled(window.scrollY > 20);
    window.addEventListener('scroll', handleScroll);

    const handleClickOutside = (event: MouseEvent) => {
      if (langRef.current && !langRef.current.contains(event.target as Node)) setIsLangOpen(false);
      if (userRef.current && !userRef.current.contains(event.target as Node)) setIsUserOpen(false);
    };
    document.addEventListener('mousedown', handleClickOutside);

    return () => {
      window.removeEventListener('scroll', handleScroll);
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, []);

  // Close mobile menu on route change
  useEffect(() => {
    setIsMobileOpen(false);
  }, [pathname]);

  const navLinks = [
    { name: t.nav.home, href: '/' },
    { name: t.nav.shop, href: '/shop' },
    { name: t.nav.collections, href: '/collections' },
    { name: t.nav.about, href: '/about' },
    { name: t.nav.contact, href: '/contact' },
  ];

  const languages: { code: Lang; label: string; flag: string }[] = [
    { code: 'EN', label: 'English', flag: '🇺🇸' },
    { code: 'BN', label: 'বাংলা', flag: '🇧🇩' },
    { code: 'AR', label: 'عربي', flag: '🇸🇦' },
  ];

  const isActive = (path: string) => pathname === path;

  return (
    <>
      <nav className={`fixed top-0 w-full z-50 transition-all duration-500 ${isScrolled ? 'bg-bg-primary/95 backdrop-blur-md shadow-lg py-4' : 'bg-transparent py-6'}`}>
        <div className="max-w-container-max mx-auto px-gutter flex justify-between items-center">
          {/* Brand & Logo */}
          <Link className="group flex items-center gap-2" href="/">
            <img
              src="/logo.png"
              alt="Sunnah Grandeur"
              className="h-7 sm:h-9 w-auto object-contain"
              onError={(e) => { e.currentTarget.style.display = 'none'; }}
            />
            <span className="text-primary-container font-headline-md text-xl sm:text-2xl tracking-tight transition-transform duration-300 group-hover:scale-105">
              Sunnah Grandeur
            </span>
          </Link>

          {/* Desktop Navigation */}
          <div className="hidden md:flex items-center space-x-10">
            {navLinks.map((link) => (
              <Link
                key={link.href}
                className={`text-label-accent font-label-accent uppercase tracking-widest text-xs relative group ${isActive(link.href) ? 'text-primary-container' : 'text-text-primary/80 hover:text-text-primary'}`}
                href={link.href}
              >
                {link.name}
                <span className={`absolute -bottom-1 left-0 w-full h-[1px] bg-primary-container transition-transform duration-300 origin-left ${isActive(link.href) ? 'scale-x-100' : 'scale-x-0 group-hover:scale-x-100'}`}></span>
              </Link>
            ))}
          </div>

          {/* Header Action Icons */}
          <div className="flex items-center space-x-4 sm:space-x-6 text-text-primary">
            {/* Search Icon */}
            <button
              onClick={() => setIsSearchOpen(true)}
              className="hover:text-primary-container transition-colors duration-300 flex items-center"
              aria-label="Search products"
            >
              <span className="material-symbols-outlined text-2xl">search</span>
            </button>

            {/* Language Switcher */}
            <div className="relative hidden sm:block" ref={langRef}>
              <button
                onClick={() => setIsLangOpen(!isLangOpen)}
                className="hover:text-primary-container transition-all flex items-center gap-1"
                aria-label="Switch language"
              >
                <span className="material-symbols-outlined text-2xl">language</span>
                <span className="text-[10px] font-bold uppercase hidden sm:inline">{language}</span>
              </button>
              {isLangOpen && (
                <div className="absolute right-0 mt-4 w-44 bg-surface-card border border-border-subtle rounded shadow-2xl overflow-hidden animate-in fade-in slide-in-from-top-2 z-50">
                  {languages.map(({ code, label, flag }) => (
                    <button
                      key={code}
                      onClick={() => { setLanguage(code); setIsLangOpen(false); }}
                      className={`w-full flex items-center gap-3 px-4 py-3 text-xs font-bold transition-colors text-left ${
                        language === code
                          ? 'bg-primary-container/20 text-primary-container'
                          : 'hover:bg-primary-container hover:text-bg-primary text-text-primary'
                      }`}
                    >
                      <span>{flag}</span>
                      <span>{label}</span>
                      {language === code && <span className="ml-auto">✓</span>}
                    </button>
                  ))}
                </div>
              )}
            </div>

            {/* Cart Icon */}
            <Link className="relative group hover:text-primary-container transition-colors duration-300" href="/cart">
              <span className="material-symbols-outlined text-2xl">shopping_cart</span>
              {totalCartCount > 0 && (
                <span className="absolute -top-2 -right-2 bg-primary-container text-bg-primary text-[10px] font-bold h-4 w-4 rounded-full flex items-center justify-center animate-in zoom-in">
                  {totalCartCount}
                </span>
              )}
            </Link>

            {/* User Account */}
            <div className="relative" ref={userRef}>
              <button
                onClick={() => user ? setIsUserOpen(!isUserOpen) : setShowAuthModal(true)}
                className="hover:text-primary-container transition-colors duration-300 flex items-center"
                aria-label="Account menu"
              >
                {user?.photoURL ? (
                  <img src={user.photoURL} alt="avatar" className="w-7 h-7 rounded-full object-cover ring-1 ring-primary-container" />
                ) : (
                  <span className="material-symbols-outlined text-2xl">{user ? 'account_circle' : 'person'}</span>
                )}
              </button>
              {isUserOpen && user && (
                <div className="absolute right-0 mt-4 w-56 bg-surface-card border border-border-subtle rounded shadow-2xl overflow-hidden animate-in fade-in slide-in-from-top-2 z-50">
                  <div className="px-4 py-3 border-b border-border-subtle">
                    <p className="text-xs font-bold text-text-primary truncate">{user.displayName || 'My Account'}</p>
                    <p className="text-[10px] text-text-secondary truncate">{user.email}</p>
                  </div>
                  <Link
                    href="/account"
                    onClick={() => setIsUserOpen(false)}
                    className="w-full flex items-center gap-3 px-4 py-3 text-xs font-bold text-text-primary hover:bg-primary-container hover:text-bg-primary transition-colors"
                  >
                    <span className="material-symbols-outlined text-sm">manage_accounts</span>
                    MY PROFILE
                  </Link>
                  <Link
                    href="/account?tab=orders"
                    onClick={() => setIsUserOpen(false)}
                    className="w-full flex items-center gap-3 px-4 py-3 text-xs font-bold text-text-primary hover:bg-primary-container hover:text-bg-primary transition-colors"
                  >
                    <span className="material-symbols-outlined text-sm">receipt_long</span>
                    MY ORDERS
                  </Link>
                  <button
                    onClick={() => { toggleTheme(); setIsUserOpen(false); }}
                    className="w-full flex items-center gap-3 px-4 py-3 text-xs font-bold text-text-primary hover:bg-primary-container hover:text-bg-primary transition-colors text-left"
                  >
                    <span className="material-symbols-outlined text-sm">
                      {theme === 'dark' ? 'light_mode' : 'dark_mode'}
                    </span>
                    {theme === 'dark' ? 'LIGHT MODE' : 'DARK MODE'}
                  </button>
                  <div className="border-t border-border-subtle my-1"></div>
                  <button
                    onClick={async () => { await logOut(); setIsUserOpen(false); }}
                    className="w-full flex items-center gap-3 px-4 py-3 text-xs font-bold text-red-400 hover:bg-red-500 hover:text-white transition-colors text-left"
                  >
                    <span className="material-symbols-outlined text-sm">logout</span>
                    LOG OUT
                  </button>
                </div>
              )}
            </div>
            {showAuthModal && <AuthModal onClose={() => setShowAuthModal(false)} />}

            {/* Mobile Menu Button */}
            <button
              className="md:hidden hover:text-primary-container transition-colors duration-300"
              onClick={() => setIsMobileOpen(!isMobileOpen)}
              aria-label="Toggle mobile menu"
            >
              <span className="material-symbols-outlined text-2xl">
                {isMobileOpen ? 'close' : 'menu'}
              </span>
            </button>
          </div>
        </div>
      </nav>

      {/* Mobile Drawer Overlay */}
      {isMobileOpen && (
        <div
          className="fixed inset-0 bg-black/60 z-40 md:hidden"
          onClick={() => setIsMobileOpen(false)}
        />
      )}

      {/* Mobile Drawer */}
      <div className={`fixed top-0 left-0 h-full w-[280px] bg-bg-primary border-r border-border-subtle z-50 md:hidden transform transition-transform duration-300 ease-in-out ${isMobileOpen ? 'translate-x-0' : '-translate-x-full'}`}>
        <div className="flex flex-col h-full overflow-y-auto">
          {/* Drawer Header */}
          <div className="flex items-center justify-between p-6 border-b border-border-subtle">
            <span className="text-primary-container font-headline-md text-lg tracking-tight">Sunnah Grandeur</span>
            <button
              onClick={() => setIsMobileOpen(false)}
              className="text-text-secondary hover:text-text-primary transition-colors"
            >
              <span className="material-symbols-outlined">close</span>
            </button>
          </div>

          {/* Nav Links */}
          <nav className="flex flex-col p-4 gap-1 flex-grow">
            {navLinks.map((link) => (
              <Link
                key={link.href}
                href={link.href}
                className={`px-4 py-3 text-sm font-bold uppercase tracking-widest rounded transition-colors ${
                  isActive(link.href)
                    ? 'bg-primary-container/15 text-primary-container'
                    : 'text-text-primary hover:bg-surface-card hover:text-primary-container'
                }`}
              >
                {link.name}
              </Link>
            ))}
          </nav>

          {/* Language + Theme in Drawer */}
          <div className="p-4 border-t border-border-subtle space-y-2">
            <p className="text-text-secondary text-[10px] font-bold uppercase tracking-widest px-4 mb-3">Language</p>
            {languages.map(({ code, label, flag }) => (
              <button
                key={code}
                onClick={() => { setLanguage(code); setIsMobileOpen(false); }}
                className={`w-full flex items-center gap-3 px-4 py-2.5 text-xs font-bold rounded transition-colors text-left ${
                  language === code
                    ? 'bg-primary-container/15 text-primary-container'
                    : 'text-text-primary hover:bg-surface-card'
                }`}
              >
                <span>{flag}</span>
                <span>{label}</span>
                {language === code && <span className="ml-auto text-primary-container">✓</span>}
              </button>
            ))}

            <div className="border-t border-border-subtle pt-2 mt-2">
              <button
                onClick={() => { toggleTheme(); setIsMobileOpen(false); }}
                className="w-full flex items-center gap-3 px-4 py-2.5 text-xs font-bold text-text-primary hover:bg-surface-card rounded transition-colors"
              >
                <span className="material-symbols-outlined text-sm text-primary-container">
                  {theme === 'dark' ? 'light_mode' : 'dark_mode'}
                </span>
                {theme === 'dark' ? 'Switch to Light Mode' : 'Switch to Dark Mode'}
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Global Product Search Modal */}
      {isSearchOpen && (
        <div className="fixed inset-0 bg-black/80 backdrop-blur-sm z-50 flex items-start justify-center pt-20 px-4 animate-in fade-in duration-200">
          <div className="bg-surface-card border border-border-subtle w-full max-w-2xl rounded-xl shadow-2xl overflow-hidden flex flex-col max-h-[80vh]">
            {/* Search Input Bar */}
            <div className="p-4 border-b border-border-subtle flex items-center gap-3">
              <span className="material-symbols-outlined text-primary-container text-2xl">search</span>
              <input
                type="text"
                autoFocus
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search fragrances, prayer caps, misbaha, thobes..."
                className="w-full bg-transparent text-text-primary placeholder:text-text-secondary text-base focus:outline-none"
              />
              {searchQuery && (
                <button
                  onClick={() => setSearchQuery('')}
                  className="text-text-secondary hover:text-text-primary text-xs uppercase font-bold px-2 py-1"
                >
                  Clear
                </button>
              )}
              <button
                onClick={() => { setIsSearchOpen(false); setSearchQuery(''); }}
                className="text-text-secondary hover:text-text-primary p-1"
              >
                <span className="material-symbols-outlined">close</span>
              </button>
            </div>

            {/* Results Container */}
            <div className="p-4 overflow-y-auto space-y-3 flex-grow">
              {searchQuery.trim() === '' ? (
                <div className="text-center py-8 text-text-secondary text-sm">
                  <p className="font-semibold text-text-primary mb-1">Popular Searches</p>
                  <div className="flex flex-wrap justify-center gap-2 mt-3">
                    {['Oud', 'Thobe', 'Tasbih', 'Attar', 'Prayer Mat'].map((keyword) => (
                      <button
                        key={keyword}
                        onClick={() => setSearchQuery(keyword)}
                        className="bg-surface border border-border-subtle hover:border-primary-container text-xs px-3 py-1.5 rounded-full text-text-primary transition-colors"
                      >
                        {keyword}
                      </button>
                    ))}
                  </div>
                </div>
              ) : (
                (() => {
                  const filtered = products.filter(
                    (p) =>
                      p.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
                      p.category.toLowerCase().includes(searchQuery.toLowerCase()) ||
                      p.description.toLowerCase().includes(searchQuery.toLowerCase())
                  );
                  if (filtered.length === 0) {
                    return (
                      <div className="text-center py-8 text-text-secondary text-sm">
                        No products match &ldquo;{searchQuery}&rdquo;.
                      </div>
                    );
                  }
                  return filtered.map((product) => (
                    <Link
                      key={product.id}
                      href={`/product/${product.id}`}
                      onClick={() => { setIsSearchOpen(false); setSearchQuery(''); }}
                      className="flex items-center gap-4 p-3 rounded-lg hover:bg-primary-container/10 border border-transparent hover:border-primary-container/30 transition-all"
                    >
                      <img
                        src={product.image}
                        alt={product.name}
                        className="w-12 h-12 object-cover rounded bg-surface border border-border-subtle"
                      />
                      <div className="flex-grow min-w-0">
                        <h4 className="text-sm font-semibold text-text-primary truncate">{product.name}</h4>
                        <p className="text-xs text-text-secondary">{product.category}</p>
                      </div>
                      <div className="text-sm font-bold text-primary-container">
                        ৳{product.price.toLocaleString()}
                      </div>
                    </Link>
                  ));
                })()
              )}
            </div>
          </div>
        </div>
      )}
    </>
  );
}
