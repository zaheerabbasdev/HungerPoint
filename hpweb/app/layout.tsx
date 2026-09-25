import type { Metadata } from "next";
import { GeistSans } from "geist/font/sans";
import { GeistMono } from "geist/font/mono";
import "./globals.css";

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
      className={`${GeistSans.variable} ${GeistMono.variable} h-full antialiased`}
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
