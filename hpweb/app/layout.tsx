import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

import { AuthProvider } from "../context/AuthContext";
import { CartProvider } from "../context/CartContext";
import { BranchProvider } from "../context/BranchContext";

export const metadata: Metadata = {
  title: "HungerPoint — Gourmet Food & Fast Delivery",
  description: "Order handcrafted burgers, artisan pizzas, and gourmet shakes delivered fast in Islamabad.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html
      lang="en"
      className={`${geistSans.variable} ${geistMono.variable} h-full antialiased`}
    >
      <body className="min-h-full flex flex-col bg-stone-950 text-stone-100">
        <AuthProvider>
          <BranchProvider>
            <CartProvider>
              {children}
            </CartProvider>
          </BranchProvider>
        </AuthProvider>
      </body>
    </html>
  );
}
