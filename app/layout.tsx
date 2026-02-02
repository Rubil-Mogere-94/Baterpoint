"use client";

import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import {
  createTheme,
  ThemeProvider,
  CssBaseline,
} from "@mui/material";
import "./globals.css";
import Navigation from "@/components/Navigation";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

const theme = createTheme({
  palette: {
    primary: {
      main: "#003366", // Darker, more professional blue (similar to Amazon's branding)
    },
    secondary: {
      main: "#FF9900", // Vibrant orange (Amazon's signature orange)
    },
    text: {
      primary: "#000000",
    },
    background: {
      default: "#ffffff",
      paper: "#f6f6f6",
    },
  },
});

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <head>
        <link rel="manifest" href="/manifest.json" />
      </head>
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased`}
      >
        <ThemeProvider theme={theme}>
          <CssBaseline />
          <Navigation />
          <main>{children}</main>
        </ThemeProvider>
      </body>
    </html>
  );
}
