'use client'

import { Task } from '@/types/task'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Checkbox } from '@/components/ui/checkbox'
import { taskCategories } from '@/data/sampleTasks'
import { formatDate, formatRelativeDate } from '@/lib/utils'
import { Calendar, Clock, CheckCircle, AlertCircle, Edit, Trash2 } from 'lucide-react'
import { useTask } from '@/contexts/TaskContext'
import { useState } from 'react'

interface TaskCardProps {
  task: Task
  onEdit: (task: Task) => void
  showDetails?: boolean
}

export function TaskCard({ task, onEdit, showDetails = false }: TaskCardProps) {
  const { completeTask, deleteTask } = useTask()
  const [isCompleting, setIsCompleting] = useState(false)
  
  const categoryInfo = taskCategories.find(cat => cat.value === task.category)
  const isOverdue = task.dueDate < new Date() && !task.completed
  
  const handleComplete = () => {
    setIsCompleting(true)
    completeTask(task.id, 'Completed via task card')
    setTimeout(() => setIsCompleting(false), 1000)
  }

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'high': return 'bg-red-50 text-red-700 border-red-200'
      case 'medium': return 'bg-yellow-50 text-yellow-700 border-yellow-200'
      case 'low': return 'bg-green-50 text-green-700 border-green-200'
      default: return 'bg-gray-50 text-gray-700 border-gray-200'
    }
  }

  return (
    <Card className={`transition-all hover:shadow-md border ${task.completed ? 'opacity-75 bg-gray-50' : 'bg-white'} ${isOverdue ? 'border-red-200 bg-red-50' : 'border-gray-200'}`}>
      <CardHeader className="pb-2">
        <div className="flex items-start justify-between">
          <div className="flex items-center gap-2">
            <Checkbox
              checked={task.completed}
              onCheckedChange={handleComplete}
              disabled={isCompleting}
            />
            <CardTitle className={`text-lg ${task.completed ? 'line-through text-muted-foreground' : ''}`}>
              {task.title}
            </CardTitle>
          </div>
          <div className="flex items-center gap-2">
            <Badge variant="outline" className={getPriorityColor(task.priority)}>
              {task.priority}
            </Badge>
            {isOverdue && (
              <AlertCircle className="h-4 w-4 text-red-500" />
            )}
          </div>
        </div>
      </CardHeader>
      
      <CardContent className="space-y-3">
        {showDetails && (
          <p className="text-sm text-muted-foreground">
            {task.description}
          </p>
        )}
        
        <div className="flex items-center justify-between text-sm">
          <div className="flex items-center gap-4">
            <Badge className="bg-slate-100 text-slate-700 border-slate-200">
              {categoryInfo?.label}
            </Badge>
            <span className="flex items-center gap-1">
              <Calendar className="h-3 w-3" />
              {formatRelativeDate(task.dueDate)}
            </span>
          </div>
          <span className="flex items-center gap-1 text-muted-foreground">
            <Clock className="h-3 w-3" />
            {task.estimatedDuration}min
          </span>
        </div>
        
        <div className="flex items-center justify-between">
          <div className="text-xs text-muted-foreground">
            <span>Due: {formatDate(task.dueDate)}</span>
            {task.lastCompleted && (
              <span className="ml-2">
                Last: {formatDate(task.lastCompleted)}
              </span>
            )}
          </div>
          
          <div className="flex items-center gap-1">
            <Button
              variant="ghost"
              size="sm"
              onClick={() => onEdit(task)}
              disabled={isCompleting}
            >
              <Edit className="h-3 w-3" />
            </Button>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => deleteTask(task.id)}
              disabled={isCompleting}
            >
              <Trash2 className="h-3 w-3" />
            </Button>
          </div>
        </div>
        
        {task.completionHistory.length > 0 && (
          <div className="flex items-center gap-2 text-xs text-muted-foreground">
            <CheckCircle className="h-3 w-3 text-green-500" />
            <span>Completed {task.completionHistory.length} times</span>
          </div>
        )}
      </CardContent>
    </Card>
  )
}
