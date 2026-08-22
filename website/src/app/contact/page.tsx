"use client";
import { useState } from 'react';
import { useLanguageStore } from '@/store/useLanguageStore';
import { translations } from '@/translations';
import { collection, addDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '@/lib/firebase';

export default function ContactPage() {
  const { language } = useLanguageStore();
  const t = translations[language];
  const [formData, setFormData] = useState({ name: '', email: '', subject: '', message: '' });
  const [status, setStatus] = useState<'idle' | 'sending' | 'sent' | 'error'>('idle');

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    setFormData(prev => ({ ...prev, [e.target.name]: e.target.value }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setStatus('sending');
    try {
      await addDoc(collection(db, 'contactMessages'), {
        ...formData,
        createdAt: serverTimestamp(),
        read: false,
      });
      setStatus('sent');
      setFormData({ name: '', email: '', subject: '', message: '' });
    } catch {
      setStatus('error');
    }
  };

  return (
    <>
      {/* Subtle Geometric Watermark Background */}
      <div className="absolute inset-0 z-0 pointer-events-none bg-pattern"></div>

      <div className="flex-grow pt-32 pb-section-padding relative z-10">
        <div className="max-w-container-max mx-auto px-gutter">
          <div className="text-center mb-16">
            <h1 className="font-headline-xl text-headline-xl text-primary mb-4">{t.contact.title}</h1>
            <p className="font-body-lg text-body-lg text-on-surface-variant max-w-2xl mx-auto">
              {t.contact.subtitle}
            </p>
          </div>
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-card-gap lg:gap-16 items-start">
            {/* Contact Form Column */}
            <div className="bg-surface-card rounded-lg p-8 lg:p-12 border border-border-subtle shadow-2xl">
              {status === 'sent' ? (
                <div className="text-center py-12 space-y-4">
                  <span className="material-symbols-outlined text-5xl text-emerald-400">check_circle</span>
                  <h3 className="text-lg font-bold text-text-primary font-serif">Message Sent!</h3>
                  <p className="text-sm text-text-secondary">We&apos;ll get back to you at <strong>{formData.email || 'your email'}</strong> as soon as possible.</p>
                  <button onClick={() => setStatus('idle')} className="text-xs text-primary-container hover:underline">Send another message</button>
                </div>
              ) : (
              <form className="space-y-6" onSubmit={handleSubmit}>
                <div>
                  <label className="block font-label-accent text-label-accent text-primary mb-2 uppercase tracking-widest" htmlFor="name">{t.contact.name}</label>
                  <input className="w-full bg-background border border-border-subtle rounded text-text-primary px-4 py-3 focus:outline-none focus:border-primary-container focus:ring-1 focus:ring-primary-container transition-colors duration-300 font-body-md text-body-md" id="name" name="name" placeholder={t.contact.namePlaceholder} type="text" required value={formData.name} onChange={handleChange} />
                </div>
                <div>
                  <label className="block font-label-accent text-label-accent text-primary mb-2 uppercase tracking-widest" htmlFor="email">{t.contact.email}</label>
                  <input className="w-full bg-background border border-border-subtle rounded text-text-primary px-4 py-3 focus:outline-none focus:border-primary-container focus:ring-1 focus:ring-primary-container transition-colors duration-300 font-body-md text-body-md" id="email" name="email" placeholder={t.contact.emailPlaceholder} type="email" required value={formData.email} onChange={handleChange} />
                </div>
                <div>
                  <label className="block font-label-accent text-label-accent text-primary mb-2 uppercase tracking-widest" htmlFor="subject">{t.contact.subject}</label>
                  <select className="w-full bg-background border border-border-subtle rounded text-text-primary px-4 py-3 focus:outline-none focus:border-primary-container focus:ring-1 focus:ring-primary-container transition-colors duration-300 font-body-md text-body-md appearance-none" id="subject" name="subject" required value={formData.subject} onChange={handleChange}>
                    <option disabled value="">{t.contact.subjectPlaceholder}</option>
                    <option value="order">Order Support</option>
                    <option value="product">Product Information</option>
                    <option value="wholesale">Wholesale Inquiries</option>
                    <option value="other">Other</option>
                  </select>
                </div>
                <div>
                  <label className="block font-label-accent text-label-accent text-primary mb-2 uppercase tracking-widest" htmlFor="message">{t.contact.message}</label>
                  <textarea className="w-full bg-background border border-border-subtle rounded text-text-primary px-4 py-3 focus:outline-none focus:border-primary-container focus:ring-1 focus:ring-primary-container transition-colors duration-300 font-body-md text-body-md resize-none" id="message" name="message" placeholder={t.contact.messagePlaceholder} rows={5} required value={formData.message} onChange={handleChange}></textarea>
                </div>
                {status === 'error' && (
                  <p className="text-xs text-red-400 text-center">Something went wrong. Please try emailing us at <a href="mailto:info@sunnahgrandeur.com" className="underline">info@sunnahgrandeur.com</a>.</p>
                )}
                <button className="w-full bg-primary-container text-bg-primary font-label-accent text-label-accent py-4 rounded uppercase tracking-widest hover:bg-primary transition-all duration-300 hover:shadow-[0_0_15px_rgba(201,168,76,0.5)] disabled:opacity-50" type="submit" disabled={status === 'sending'}>
                  {status === 'sending' ? 'Sending...' : t.contact.send}
                </button>
              </form>
              )}
            </div>
            {/* Contact Details & Image Column */}
            <div className="flex flex-col space-y-12">
              <div className="relative overflow-hidden rounded-lg shadow-2xl aspect-square w-full">
                <img
                  alt="Sunnah Grandeur"
                  className="object-cover w-full h-full opacity-90 hover:scale-105 transition-transform duration-700 ease-in-out"
                  src="/contact-image.jpg.png"
                  onError={(e) => {
                    e.currentTarget.src = 'https://lh3.googleusercontent.com/aida/ADBb0uhEEleu7KmJZIDy9o-R0e1n7ajgAMkENyQ4eHjdI4eQF3vTywhBkToaiHR9Wri96NN64i7sdHclPPVpRNUdvoSXdF59d4qSzwG1w_XHiLUvh838-UE1Woog14E6V3-19LDckStk_xuTsJvqDFf8BImFbh4GEmcgYt0syVIceAwHl2ugiPShK_VRzf64WhUtYCrvcfSypyUI1y-s1uKaTV92l8YhScZsofow7Y4QZLUxOOnthfZ42XzihYkrDRq3yIq2VB1P14_jsNs';
                  }}
                />
                <div className="absolute inset-0 bg-gradient-to-t from-bg-primary via-transparent to-transparent opacity-80 pointer-events-none"></div>
              </div>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                <div className="bg-surface-card p-6 rounded-lg border border-border-subtle hover:border-primary-container transition-colors duration-300">
                  <span className="material-symbols-outlined text-primary text-3xl mb-4 block" style={{ fontVariationSettings: "'FILL' 1" }}>location_on</span>
                  <h3 className="font-headline-md text-headline-md text-primary mb-2">{t.contact.boutique}</h3>
                  <p className="font-body-md text-body-md text-on-surface-variant whitespace-pre-line">
                    {t.contact.boutiqueAddress}
                  </p>
                </div>
                <div className="bg-surface-card p-6 rounded-lg border border-border-subtle hover:border-primary-container transition-colors duration-300">
                  <span className="material-symbols-outlined text-primary text-3xl mb-4 block" style={{ fontVariationSettings: "'FILL' 1" }}>mail</span>
                  <h3 className="font-headline-md text-headline-md text-primary mb-2">{t.contact.directContact}</h3>
                  <p className="font-body-md text-body-md text-on-surface-variant mb-2">
                    <a className="hover:text-primary transition-colors" href="mailto:info@sunnahgrandeur.com">info@sunnahgrandeur.com</a>
                  </p>
                  <p className="font-body-md text-body-md text-on-surface-variant flex items-center gap-1.5 mt-4">
                    <span className="material-symbols-outlined text-sm">public</span>
                    <a className="hover:text-primary transition-colors" href="https://www.facebook.com/sunnahgrandeurnyc" target="_blank" rel="noopener noreferrer">Facebook Page</a>
                  </p>
                </div>
              </div>
              {/* Brand Logo */}
              <div className="w-full flex justify-center mt-8">
                <img
                  alt="Sunnah Grandeur brand emblem"
                  className="opacity-70 max-w-[120px] h-auto"
                  src="/logo.png"
                  onError={(e) => { e.currentTarget.style.display = 'none'; }}
                />
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  );
}
