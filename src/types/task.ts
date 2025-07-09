export interface Task {
  id: string
  title: string
  description: string
  category: TaskCategory
  frequency: TaskFrequency
  dueDate: Date
  lastCompleted?: Date
  completed: boolean
  priority: 'high' | 'medium' | 'low'
  estimatedDuration: number // in minutes
  completionHistory: CompletionRecord[]
}

export interface CompletionRecord {
  id: string
  taskId: string
  completedAt: Date
  notes?: string
  rating?: number // 1-5 stars
}

export type TaskCategory = 
  | 'electrical'
  | 'plumbing'
  | 'hvac'
  | 'appliances'
  | 'cleaning'
  | 'seasonal'
  | 'security'
  | 'garden'
  | 'general'

export type TaskFrequency = 
  | 'weekly'
  | 'monthly'
  | 'quarterly'
  | 'biannually'
  | 'yearly'
  | 'custom'

export interface TaskFilter {
  category?: TaskCategory
  frequency?: TaskFrequency
  completed?: boolean
  search?: string
  priority?: 'high' | 'medium' | 'low'
}
