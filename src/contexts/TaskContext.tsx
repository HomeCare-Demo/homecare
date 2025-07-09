'use client'

import { Task, TaskFilter } from '@/types/task'
import { sampleTasks } from '@/data/sampleTasks'
import { generateId } from '@/lib/utils'
import { createContext, useContext, useState, useEffect, ReactNode } from 'react'

interface TaskContextType {
  tasks: Task[]
  addTask: (task: Omit<Task, 'id' | 'completionHistory'>) => void
  updateTask: (id: string, updates: Partial<Task>) => void
  deleteTask: (id: string) => void
  completeTask: (id: string, notes?: string, rating?: number) => void
  filterTasks: (filter: TaskFilter) => Task[]
  getTaskById: (id: string) => Task | undefined
}

const TaskContext = createContext<TaskContextType | undefined>(undefined)

export function TaskProvider({ children }: { children: ReactNode }) {
  const [tasks, setTasks] = useState<Task[]>([])

  // Initialize with sample data
  useEffect(() => {
    setTasks(sampleTasks)
  }, [])

  const addTask = (taskData: Omit<Task, 'id' | 'completionHistory'>) => {
    const newTask: Task = {
      ...taskData,
      id: generateId(),
      completionHistory: []
    }
    setTasks(prev => [...prev, newTask])
  }

  const updateTask = (id: string, updates: Partial<Task>) => {
    setTasks(prev => prev.map(task => 
      task.id === id ? { ...task, ...updates } : task
    ))
  }

  const deleteTask = (id: string) => {
    setTasks(prev => prev.filter(task => task.id !== id))
  }

  const completeTask = (id: string, notes?: string, rating?: number) => {
    setTasks(prev => prev.map(task => {
      if (task.id === id) {
        const completionRecord = {
          id: generateId(),
          taskId: id,
          completedAt: new Date(),
          notes,
          rating
        }
        
        // Calculate next due date based on frequency
        const nextDueDate = calculateNextDueDate(task.frequency, new Date())
        
        return {
          ...task,
          completed: true,
          lastCompleted: new Date(),
          dueDate: nextDueDate,
          completionHistory: [...task.completionHistory, completionRecord]
        }
      }
      return task
    }))
  }

  const filterTasks = (filter: TaskFilter) => {
    return tasks.filter(task => {
      if (filter.category && task.category !== filter.category) return false
      if (filter.frequency && task.frequency !== filter.frequency) return false
      if (filter.completed !== undefined && task.completed !== filter.completed) return false
      if (filter.priority && task.priority !== filter.priority) return false
      if (filter.search) {
        const searchLower = filter.search.toLowerCase()
        return task.title.toLowerCase().includes(searchLower) || 
               task.description.toLowerCase().includes(searchLower)
      }
      return true
    })
  }

  const getTaskById = (id: string) => {
    return tasks.find(task => task.id === id)
  }

  return (
    <TaskContext.Provider value={{
      tasks,
      addTask,
      updateTask,
      deleteTask,
      completeTask,
      filterTasks,
      getTaskById
    }}>
      {children}
    </TaskContext.Provider>
  )
}

export function useTask() {
  const context = useContext(TaskContext)
  if (!context) {
    throw new Error('useTask must be used within a TaskProvider')
  }
  return context
}

function calculateNextDueDate(frequency: string, from: Date): Date {
  const date = new Date(from)
  
  switch (frequency) {
    case 'weekly':
      date.setDate(date.getDate() + 7)
      break
    case 'monthly':
      date.setMonth(date.getMonth() + 1)
      break
    case 'quarterly':
      date.setMonth(date.getMonth() + 3)
      break
    case 'biannually':
      date.setMonth(date.getMonth() + 6)
      break
    case 'yearly':
      date.setFullYear(date.getFullYear() + 1)
      break
    default:
      date.setMonth(date.getMonth() + 1) // Default to monthly
  }
  
  return date
}
