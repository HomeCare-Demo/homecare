import { Task, CompletionRecord } from '@/types/task'

// Sample completion records
const sampleCompletions: CompletionRecord[] = [
  {
    id: 'comp1',
    taskId: 'task1',
    completedAt: new Date('2024-12-15'),
    notes: 'Cleaned and replaced filter. Filter was quite dirty.',
    rating: 4
  },
  {
    id: 'comp2',
    taskId: 'task2',
    completedAt: new Date('2024-11-20'),
    notes: 'Battery levels good. Cleaned terminals.',
    rating: 5
  },
  {
    id: 'comp3',
    taskId: 'task3',
    completedAt: new Date('2024-10-01'),
    notes: 'Serviced AC unit. Cleaned coils and checked refrigerant.',
    rating: 4
  }
]

// Sample tasks with realistic home maintenance items
export const sampleTasks: Task[] = [
  {
    id: 'task1',
    title: 'Replace Water Filter',
    description: 'Replace the main water filter in the kitchen. Check for leaks and ensure proper seal.',
    category: 'plumbing',
    frequency: 'quarterly',
    dueDate: new Date('2025-03-15'),
    lastCompleted: new Date('2024-12-15'),
    completed: false,
    priority: 'medium',
    estimatedDuration: 30,
    completionHistory: [sampleCompletions[0]]
  },
  {
    id: 'task2',
    title: 'Check Inverter Battery',
    description: 'Inspect inverter battery levels, clean terminals, and check connections.',
    category: 'electrical',
    frequency: 'monthly',
    dueDate: new Date('2025-07-20'),
    lastCompleted: new Date('2024-11-20'),
    completed: false,
    priority: 'high',
    estimatedDuration: 45,
    completionHistory: [sampleCompletions[1]]
  },
  {
    id: 'task3',
    title: 'HVAC System Maintenance',
    description: 'Clean air filters, check thermostat, and inspect ductwork for any issues.',
    category: 'hvac',
    frequency: 'quarterly',
    dueDate: new Date('2025-01-01'),
    lastCompleted: new Date('2024-10-01'),
    completed: false,
    priority: 'high',
    estimatedDuration: 120,
    completionHistory: [sampleCompletions[2]]
  },
  {
    id: 'task4',
    title: 'Clean Dishwasher Filter',
    description: 'Remove and clean the dishwasher filter. Check spray arms for clogs.',
    category: 'appliances',
    frequency: 'monthly',
    dueDate: new Date('2025-07-15'),
    lastCompleted: new Date('2024-12-15'),
    completed: false,
    priority: 'low',
    estimatedDuration: 20,
    completionHistory: []
  },
  {
    id: 'task5',
    title: 'Gutter Cleaning',
    description: 'Clean gutters and downspouts. Check for damage and ensure proper drainage.',
    category: 'seasonal',
    frequency: 'biannually',
    dueDate: new Date('2025-09-01'),
    lastCompleted: new Date('2024-04-01'),
    completed: false,
    priority: 'medium',
    estimatedDuration: 180,
    completionHistory: []
  },
  {
    id: 'task6',
    title: 'Test Smoke Detectors',
    description: 'Test all smoke detectors and replace batteries if needed.',
    category: 'security',
    frequency: 'monthly',
    dueDate: new Date('2025-07-10'),
    lastCompleted: new Date('2024-12-10'),
    completed: true,
    priority: 'high',
    estimatedDuration: 15,
    completionHistory: []
  },
  {
    id: 'task7',
    title: 'Deep Clean Carpets',
    description: 'Professional carpet cleaning or thorough vacuuming and spot cleaning.',
    category: 'cleaning',
    frequency: 'biannually',
    dueDate: new Date('2025-08-01'),
    lastCompleted: new Date('2024-02-01'),
    completed: false,
    priority: 'low',
    estimatedDuration: 240,
    completionHistory: []
  },
  {
    id: 'task8',
    title: 'Inspect Roof and Tiles',
    description: 'Visual inspection of roof tiles, gutters, and flashing for damage.',
    category: 'seasonal',
    frequency: 'yearly',
    dueDate: new Date('2025-10-01'),
    lastCompleted: new Date('2024-10-01'),
    completed: false,
    priority: 'medium',
    estimatedDuration: 60,
    completionHistory: []
  },
  {
    id: 'task9',
    title: 'Service Washing Machine',
    description: 'Clean drum, check hoses, and run maintenance cycle.',
    category: 'appliances',
    frequency: 'quarterly',
    dueDate: new Date('2025-07-05'),
    lastCompleted: new Date('2024-04-05'),
    completed: false,
    priority: 'high',
    estimatedDuration: 45,
    completionHistory: []
  },
  {
    id: 'task10',
    title: 'Prune Garden Trees',
    description: 'Trim and prune trees and large shrubs for healthy growth.',
    category: 'garden',
    frequency: 'yearly',
    dueDate: new Date('2025-12-01'),
    lastCompleted: new Date('2024-12-01'),
    completed: false,
    priority: 'low',
    estimatedDuration: 300,
    completionHistory: []
  }
]

export const taskCategories = [
  { value: 'electrical', label: 'Electrical', color: 'bg-slate-100 text-slate-700' },
  { value: 'plumbing', label: 'Plumbing', color: 'bg-slate-100 text-slate-700' },
  { value: 'hvac', label: 'HVAC', color: 'bg-slate-100 text-slate-700' },
  { value: 'appliances', label: 'Appliances', color: 'bg-slate-100 text-slate-700' },
  { value: 'cleaning', label: 'Cleaning', color: 'bg-slate-100 text-slate-700' },
  { value: 'seasonal', label: 'Seasonal', color: 'bg-slate-100 text-slate-700' },
  { value: 'security', label: 'Security', color: 'bg-slate-100 text-slate-700' },
  { value: 'garden', label: 'Garden', color: 'bg-slate-100 text-slate-700' },
  { value: 'general', label: 'General', color: 'bg-slate-100 text-slate-700' }
]

export const taskFrequencies = [
  { value: 'weekly', label: 'Weekly' },
  { value: 'monthly', label: 'Monthly' },
  { value: 'quarterly', label: 'Quarterly' },
  { value: 'biannually', label: 'Bi-annually' },
  { value: 'yearly', label: 'Yearly' },
  { value: 'custom', label: 'Custom' }
]
