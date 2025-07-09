import type { Metadata } from 'next'
import { TaskProvider } from '@/contexts/TaskContext'
import './globals.css'

export const metadata: Metadata = {
  title: 'HomeCare - Home Maintenance Tracker',
  description: 'Keep your home in perfect condition with smart maintenance tracking and scheduling',
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="en">
      <body className="min-h-screen font-sans antialiased" style={{ backgroundColor: 'hsl(var(--background))', color: 'hsl(var(--foreground))' }}>
        <TaskProvider>
          {children}
        </TaskProvider>
      </body>
    </html>
  )
}
