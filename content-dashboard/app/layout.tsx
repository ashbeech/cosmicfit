import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'Cosmic Fit — Content Dashboard',
  description: 'Edit and version the Cosmic Fit app copy.',
  robots: { index: false, follow: false },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <head>
        {/* Same fonts as tools/review_tool.py so the UI stays familiar to Maria. */}
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link
          href="https://fonts.googleapis.com/css2?family=DM+Serif+Text&family=PT+Serif:wght@400;700&display=swap"
          rel="stylesheet"
        />
      </head>
      <body>{children}</body>
    </html>
  );
}
