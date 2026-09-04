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
import CartDrawer from '@/components/CartDrawer';

export default function Navbar() {
  const pathname = usePathname();
  const [isScrolled, setIsScrolled] = useState(false);
  const [isLangOpen, setIsLangOpen] = useState(false);
  const [isUserOpen, setIsUserOpen] = useState(false);
  const [isMobileOpen, setIsMobileOpen] = useState(false);
  const [isSearchOpen, setIsSearchOpen] = useState(false);
  const [isCartDrawerOpen, setIsCartDrawerOpen] = useState(false);
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
      <nav 
        className={`fixed top-0 w-full z-50 transition-all duration-500 ${
          isScrolled 
            ? 'bg-[#080706]/90 backdrop-blur-xl border-b border-primary/20 shadow-[0_8px_32px_rgba(0,0,0,0.8)] py-3.5' 
            : 'bg-gradient-to-b from-black/80 via-black/40 to-transparent py-5'
        }`}
      >
        <div className="max-w-container-max mx-auto px-gutter flex justify-between items-center">
          {/* Brand & Logo */}
          <Link className="group flex items-center gap-2.5" href="/">
            <div className="relative flex items-center justify-center">
              <img
                src="/logo.png"
                alt="Sunnah Grandeur"
                className="h-8 sm:h-9 w-auto object-contain drop-shadow-[0_0_12px_rgba(201,168,76,0.3)] transition-transform duration-300 group-hover:scale-105"
                onError={(e) => { e.currentTarget.style.display = 'none'; }}
              />
            </div>
            <div className="flex flex-col">
              <span className="font-cinzel text-lg sm:text-xl font-bold tracking-widest text-gold-gradient transition-all duration-300 group-hover:brightness-110">
                SUNNAH GRANDEUR
              </span>
              <span className="text-[8px] font-mono tracking-[0.3em] uppercase text-[#9E9789] -mt-1 hidden sm:block">
                Artisanal Islamic Luxury
              </span>
            </div>
          </Link>

          {/* Desktop Navigation */}
          <div className="hidden md:flex items-center space-x-8 bg-[#12100C]/70 px-6 py-2 rounded-full border border-primary/15 backdrop-blur-md">
            {navLinks.map((link) => (
              <Link
                key={link.href}
                className={`font-mono text-xs uppercase tracking-widest relative py-1 transition-colors duration-300 ${
                  isActive(link.href) ? 'text-primary font-bold' : 'text-text-secondary hover:text-text-primary'
                }`}
                href={link.href}
              >
                {link.name}
                {isActive(link.href) && (
                  <span className="absolute bottom-0 left-0 w-full h-[1.5px] bg-gradient-to-r from-transparent via-[#E6C364] to-transparent" />
                )}
              </Link>
            ))}
          </div>

          {/* Header Action Icons */}
          <div className="flex items-center space-x-3 sm:space-x-5 text-text-primary">
            {/* Search Icon */}
            <button
              onClick={() => setIsSearchOpen(true)}
              className="w-9 h-9 rounded-full border border-border-subtle hover:border-primary/50 hover:bg-primary/10 transition-all duration-300 flex items-center justify-center text-text-secondary hover:text-primary"
              aria-label="Search products"
            >
              <span className="material-symbols-outlined text-xl">search</span>
            </button>

            {/* Language Switcher */}
            <div className="relative hidden sm:block" ref={langRef}>
              <button
                onClick={() => setIsLangOpen(!isLangOpen)}
                className="h-9 px-3 rounded-full border border-border-subtle hover:border-primary/50 hover:bg-primary/10 transition-all duration-300 flex items-center gap-1.5 text-text-secondary hover:text-primary"
                aria-label="Switch language"
              >
                <span className="material-symbols-outlined text-lg">language</span>
                <span className="text-[10px] font-bold uppercase font-mono">{language}</span>
              </button>
              {isLangOpen && (
                <div className="absolute right-0 mt-3 w-44 bg-[#0F0E0C] border border-primary/20 rounded-lg shadow-2xl overflow-hidden animate-in fade-in slide-in-from-top-2 z-50 backdrop-blur-xl">
                  {languages.map(({ code, label, flag }) => (
                    <button
                      key={code}
                      onClick={() => { setLanguage(code); setIsLangOpen(false); }}
                      className={`w-full flex items-center gap-3 px-4 py-3 text-xs font-bold transition-colors text-left ${
                        language === code
                          ? 'bg-primary/20 text-primary'
                          : 'hover:bg-primary/10 text-text-primary hover:text-primary'
                      }`}
                    >
                      <span>{flag}</span>
                      <span>{label}</span>
                      {language === code && <span className="ml-auto text-primary">✓</span>}
                    </button>
                  ))}
                </div>
              )}
            </div>

            {/* Cart Icon -> Opens Slide-Over Drawer */}
            <button 
              onClick={() => setIsCartDrawerOpen(true)}
              className="relative w-9 h-9 rounded-full border border-border-subtle hover:border-primary/50 hover:bg-primary/10 transition-all duration-300 flex items-center justify-center text-text-secondary hover:text-primary group"
              aria-label="Open Cart Drawer"
            >
              <span className="material-symbols-outlined text-xl">shopping_bag</span>
              {totalCartCount > 0 && (
                <span className="absolute -top-1.5 -right-1.5 bg-gradient-to-r from-[#E6C364] to-[#C9A84C] text-black text-[10px] font-bold font-mono h-4 w-4 rounded-full flex items-center justify-center shadow-[0_0_8px_rgba(201,168,76,0.6)] animate-pulse">
                  {totalCartCount}
                </span>
              )}
            </button>

            {/* User Account */}
            <div className="relative" ref={userRef}>
              <button
                onClick={() => user ? setIsUserOpen(!isUserOpen) : setShowAuthModal(true)}
                className="w-9 h-9 rounded-full border border-border-subtle hover:border-primary/50 hover:bg-primary/10 transition-all duration-300 flex items-center justify-center text-text-secondary hover:text-primary"
                aria-label="Account menu"
              >
                {user?.photoURL ? (
                  <img src={user.photoURL} alt="avatar" className="w-7 h-7 rounded-full object-cover ring-1 ring-primary" />
                ) : (
                  <span className="material-symbols-outlined text-xl">{user ? 'account_circle' : 'person'}</span>
                )}
              </button>
              {isUserOpen && user && (
                <div className="absolute right-0 mt-3 w-56 bg-[#0F0E0C] border border-primary/20 rounded-lg shadow-2xl overflow-hidden animate-in fade-in slide-in-from-top-2 z-50 backdrop-blur-xl">
                  <div className="px-4 py-3 border-b border-border-subtle">
                    <p className="text-xs font-bold text-text-primary truncate">{user.displayName || 'My Account'}</p>
                    <p className="text-[10px] text-text-secondary truncate font-mono">{user.email}</p>
                  </div>
                  <Link
                    href="/account"
                    onClick={() => setIsUserOpen(false)}
                    className="w-full flex items-center gap-3 px-4 py-3 text-xs font-bold text-text-primary hover:bg-primary/10 hover:text-primary transition-colors"
                  >
                    <span className="material-symbols-outlined text-sm">manage_accounts</span>
                    MY PROFILE
                  </Link>
                  <Link
                    href="/account?tab=orders"
                    onClick={() => setIsUserOpen(false)}
                    className="w-full flex items-center gap-3 px-4 py-3 text-xs font-bold text-text-primary hover:bg-primary/10 hover:text-primary transition-colors"
                  >
                    <span className="material-symbols-outlined text-sm">receipt_long</span>
                    MY ORDERS
                  </Link>
                  <button
                    onClick={() => { toggleTheme(); setIsUserOpen(false); }}
                    className="w-full flex items-center gap-3 px-4 py-3 text-xs font-bold text-text-primary hover:bg-primary/10 hover:text-primary transition-colors text-left"
                  >
                    <span className="material-symbols-outlined text-sm">
                      {theme === 'dark' ? 'light_mode' : 'dark_mode'}
                    </span>
                    {theme === 'dark' ? 'LIGHT MODE' : 'DARK MODE'}
                  </button>
                  <div className="border-t border-border-subtle my-1"></div>
                  <button
                    onClick={async () => { await logOut(); setIsUserOpen(false); }}
                    className="w-full flex items-center gap-3 px-4 py-3 text-xs font-bold text-red-400 hover:bg-red-500/10 hover:text-red-300 transition-colors text-left"
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
              className="md:hidden w-9 h-9 rounded-full border border-border-subtle flex items-center justify-center hover:text-primary transition-colors duration-300"
              onClick={() => setIsMobileOpen(!isMobileOpen)}
              aria-label="Toggle mobile menu"
            >
              <span className="material-symbols-outlined text-xl">
                {isMobileOpen ? 'close' : 'menu'}
              </span>
            </button>
          </div>
        </div>
      </nav>

      {/* Slide-Over Cart Drawer */}
      <CartDrawer 
        isOpen={isCartDrawerOpen} 
        onClose={() => setIsCartDrawerOpen(false)} 
      />

      {/* Mobile Drawer Overlay */}
      {isMobileOpen && (
        <div
          className="fixed inset-0 bg-black/75 backdrop-blur-sm z-40 md:hidden"
          onClick={() => setIsMobileOpen(false)}
        />
      )}

      {/* Mobile Drawer */}
      <div className={`fixed top-0 left-0 h-full w-[280px] bg-[#0A0907] border-r border-primary/20 z-50 md:hidden transform transition-transform duration-300 ease-in-out ${isMobileOpen ? 'translate-x-0' : '-translate-x-full'}`}>
        <div className="flex flex-col h-full overflow-y-auto">
          {/* Drawer Header */}
          <div className="flex items-center justify-between p-6 border-b border-border-subtle">
            <span className="font-cinzel text-base font-bold text-gold-gradient">Sunnah Grandeur</span>
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
                className={`px-4 py-3 text-xs font-mono font-bold uppercase tracking-widest rounded-lg transition-colors ${
                  isActive(link.href)
                    ? 'bg-primary/15 text-primary border border-primary/30'
                    : 'text-text-primary hover:bg-[#14120E] hover:text-primary'
                }`}
              >
                {link.name}
              </Link>
            ))}
          </nav>

          {/* Language + Theme in Drawer */}
          <div className="p-4 border-t border-border-subtle space-y-2">
            <p className="text-text-secondary text-[10px] font-bold uppercase tracking-widest px-4 mb-3 font-mono">Language</p>
            {languages.map(({ code, label, flag }) => (
              <button
                key={code}
                onClick={() => { setLanguage(code); setIsMobileOpen(false); }}
                className={`w-full flex items-center gap-3 px-4 py-2.5 text-xs font-bold rounded-lg transition-colors text-left ${
                  language === code
                    ? 'bg-primary/15 text-primary'
                    : 'text-text-primary hover:bg-[#14120E]'
                }`}
              >
                <span>{flag}</span>
                <span>{label}</span>
                {language === code && <span className="ml-auto text-primary">✓</span>}
              </button>
            ))}

            <div className="border-t border-border-subtle pt-2 mt-2">
              <button
                onClick={() => { toggleTheme(); setIsMobileOpen(false); }}
                className="w-full flex items-center gap-3 px-4 py-2.5 text-xs font-bold text-text-primary hover:bg-[#14120E] rounded-lg transition-colors"
              >
                <span className="material-symbols-outlined text-sm text-primary">
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
        <div className="fixed inset-0 bg-black/80 backdrop-blur-md z-50 flex items-start justify-center pt-20 px-4 animate-in fade-in duration-200">
          <div className="bg-[#0F0E0C] border border-primary/30 w-full max-w-2xl rounded-2xl shadow-[0_20px_50px_rgba(0,0,0,0.9)] overflow-hidden flex flex-col max-h-[80vh]">
            {/* Search Input Bar */}
            <div className="p-5 border-b border-border-subtle flex items-center gap-3.5 bg-[#14120E]">
              <span className="material-symbols-outlined text-primary text-2xl">search</span>
              <input
                type="text"
                autoFocus
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search rare attars, velvet sajadah, misbaha, thobes..."
                className="w-full bg-transparent text-text-primary placeholder:text-text-secondary text-sm sm:text-base focus:outline-none"
              />
              {searchQuery && (
                <button
                  onClick={() => setSearchQuery('')}
                  className="text-text-secondary hover:text-text-primary text-[10px] uppercase font-bold font-mono px-2 py-1"
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
            <div className="p-5 overflow-y-auto space-y-3 flex-grow">
              {searchQuery.trim() === '' ? (
                <div className="text-center py-10 text-text-secondary text-xs">
                  <p className="font-bold text-text-primary mb-2 uppercase tracking-widest font-mono">Popular Searches</p>
                  <div className="flex flex-wrap justify-center gap-2 mt-4">
                    {['Oud Al-Majd', 'Amber Attar', 'Gold Velvet Sajadah', 'Black Onyx Misbaha', 'Royal Musk'].map((keyword) => (
                      <button
                        key={keyword}
                        onClick={() => setSearchQuery(keyword)}
                        className="bg-[#181510] border border-border-subtle hover:border-primary/60 text-xs px-3.5 py-1.5 rounded-full text-text-secondary hover:text-primary transition-all"
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
                      <div className="text-center py-10 text-text-secondary text-xs">
                        No artisanal products match &ldquo;{searchQuery}&rdquo;.
                      </div>
                    );
                  }
                  return filtered.map((product) => (
                    <Link
                      key={product.id}
                      href={`/product/${product.id}`}
                      onClick={() => { setIsSearchOpen(false); setSearchQuery(''); }}
                      className="flex items-center gap-4 p-3 rounded-xl hover:bg-primary/10 border border-transparent hover:border-primary/30 transition-all group"
                    >
                      <img
                        src={product.image}
                        alt={product.name}
                        className="w-14 h-14 object-cover rounded-lg bg-[#14120E] border border-border-subtle group-hover:scale-105 transition-transform"
                      />
                      <div className="flex-grow min-w-0">
                        <span className="text-[9px] text-primary/70 uppercase tracking-widest font-mono font-bold block">{product.category}</span>
                        <h4 className="text-sm font-bold text-text-primary group-hover:text-primary transition-colors truncate">{product.name}</h4>
                        <p className="text-xs text-text-secondary line-clamp-1">{product.description}</p>
                      </div>
                      <div className="text-sm font-bold font-mono text-primary">
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
