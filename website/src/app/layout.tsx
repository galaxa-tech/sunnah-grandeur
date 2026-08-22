import type { Metadata } from "next";
import "./globals.css";
import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";
import ThemeInitializer from "@/components/ThemeInitializer";
import AppDownloadBanner from "@/components/AppDownloadBanner";
import { AuthProvider } from "@/context/AuthContext";

export const metadata: Metadata = {
  title: "Sunnah Grandeur | Premium Islamic Lifestyle",
  description: "Inspired by the Ummah. Discover premium artisanal fragrances and lifestyle artifacts.",
  icons: {
    icon: "/favicon.ico",
    shortcut: "/favicon.ico",
    apple: "/icon.png",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="min-h-screen flex flex-col">
        <AuthProvider>
          <ThemeInitializer />
          <Navbar />
          <main className="flex-grow">
            {children}
          </main>
          <AppDownloadBanner />
          <Footer />
        </AuthProvider>
      </body>
    </html>
  );
}

