import { type ClassValue, clsx } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function formatDate(date: Date): string {
  return new Intl.DateTimeFormat('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  }).format(date)
}

export function formatRelativeDate(date: Date): string {
  const now = new Date()
  const diffInDays = Math.floor((date.getTime() - now.getTime()) / (1000 * 60 * 60 * 24))
  
  if (diffInDays === 0) return 'Today'
  if (diffInDays === 1) return 'Tomorrow'
  if (diffInDays === -1) return 'Yesterday'
  if (diffInDays > 0) return `In ${diffInDays} days`
  return `${Math.abs(diffInDays)} days ago`
}

export function getTaskPriority(dueDate: Date): 'high' | 'medium' | 'low' {
  const now = new Date()
  const diffInDays = Math.floor((dueDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24))
  
  if (diffInDays < 0) return 'high' // Overdue
  if (diffInDays <= 3) return 'high' // Due soon
  if (diffInDays <= 7) return 'medium' // Due this week
  return 'low' // Due later
}

export function generateId(): string {
  return Math.random().toString(36).substr(2, 9)
}
