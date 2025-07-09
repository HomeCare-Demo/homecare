'use client'

import { Task, TaskCategory, TaskFrequency } from '@/types/task'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Checkbox } from '@/components/ui/checkbox'
import { taskCategories, taskFrequencies } from '@/data/sampleTasks'
import { getTaskPriority } from '@/lib/utils'
import { useState, useEffect } from 'react'
import { useTask } from '@/contexts/TaskContext'

interface TaskFormDialogProps {
  task?: Task
  open: boolean
  onOpenChange: (open: boolean) => void
}

export function TaskFormDialog({ task, open, onOpenChange }: TaskFormDialogProps) {
  const { addTask, updateTask } = useTask()
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    category: 'general' as TaskCategory,
    frequency: 'monthly' as TaskFrequency,
    dueDate: new Date(),
    estimatedDuration: 30,
    completed: false
  })

  useEffect(() => {
    if (task) {
      setFormData({
        title: task.title,
        description: task.description,
        category: task.category,
        frequency: task.frequency,
        dueDate: task.dueDate,
        estimatedDuration: task.estimatedDuration,
        completed: task.completed
      })
    } else {
      setFormData({
        title: '',
        description: '',
        category: 'general',
        frequency: 'monthly',
        dueDate: new Date(),
        estimatedDuration: 30,
        completed: false
      })
    }
  }, [task])

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    
    const priority = getTaskPriority(formData.dueDate)
    
    if (task) {
      updateTask(task.id, {
        ...formData,
        priority,
        lastCompleted: task.lastCompleted
      })
    } else {
      addTask({
        ...formData,
        priority
      })
    }
    
    onOpenChange(false)
  }

  const handleDateChange = (value: string) => {
    setFormData(prev => ({ ...prev, dueDate: new Date(value) }))
  }

  const formatDateForInput = (date: Date) => {
    return date.toISOString().split('T')[0]
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>
            {task ? 'Edit Task' : 'Add New Task'}
          </DialogTitle>
        </DialogHeader>
        
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="title">Task Title</Label>
            <Input
              id="title"
              value={formData.title}
              onChange={(e) => setFormData(prev => ({ ...prev, title: e.target.value }))}
              placeholder="Enter task title"
              required
            />
          </div>
          
          <div className="space-y-2">
            <Label htmlFor="description">Description</Label>
            <Input
              id="description"
              value={formData.description}
              onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
              placeholder="Enter task description"
              required
            />
          </div>
          
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="category">Category</Label>
              <Select
                value={formData.category}
                onValueChange={(value: TaskCategory) => setFormData(prev => ({ ...prev, category: value }))}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select category" />
                </SelectTrigger>
                <SelectContent>
                  {taskCategories.map(category => (
                    <SelectItem key={category.value} value={category.value}>
                      {category.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            
            <div className="space-y-2">
              <Label htmlFor="frequency">Frequency</Label>
              <Select
                value={formData.frequency}
                onValueChange={(value: TaskFrequency) => setFormData(prev => ({ ...prev, frequency: value }))}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select frequency" />
                </SelectTrigger>
                <SelectContent>
                  {taskFrequencies.map(freq => (
                    <SelectItem key={freq.value} value={freq.value}>
                      {freq.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>
          
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="dueDate">Due Date</Label>
              <Input
                id="dueDate"
                type="date"
                value={formatDateForInput(formData.dueDate)}
                onChange={(e) => handleDateChange(e.target.value)}
                required
              />
            </div>
            
            <div className="space-y-2">
              <Label htmlFor="duration">Duration (minutes)</Label>
              <Input
                id="duration"
                type="number"
                value={formData.estimatedDuration}
                onChange={(e) => setFormData(prev => ({ ...prev, estimatedDuration: Number(e.target.value) }))}
                min="1"
                required
              />
            </div>
          </div>
          
          {task && (
            <div className="flex items-center space-x-2">
              <Checkbox
                id="completed"
                checked={formData.completed}
                onCheckedChange={(checked) => setFormData(prev => ({ ...prev, completed: !!checked }))}
              />
              <Label htmlFor="completed">Mark as completed</Label>
            </div>
          )}
          
          <DialogFooter>
            <Button type="button" variant="outline" onClick={() => onOpenChange(false)}>
              Cancel
            </Button>
            <Button type="submit">
              {task ? 'Update Task' : 'Add Task'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
