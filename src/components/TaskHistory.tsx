'use client'

import { Task, CompletionRecord } from '@/types/task'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog'
import { formatDate } from '@/lib/utils'
import { History, Star, Calendar, Clock, CheckCircle } from 'lucide-react'
import { useTask } from '@/contexts/TaskContext'

interface TaskHistoryProps {
  task: Task
}

export function TaskHistory({ task }: TaskHistoryProps) {
  const completionHistory = task.completionHistory.sort((a, b) => 
    new Date(b.completedAt).getTime() - new Date(a.completedAt).getTime()
  )

  const renderStars = (rating?: number) => {
    if (!rating) return null
    
    return (
      <div className="flex items-center gap-1">
        {[1, 2, 3, 4, 5].map(star => (
          <Star
            key={star}
            className={`h-3 w-3 ${star <= rating ? 'fill-yellow-400 text-yellow-400' : 'text-gray-300'}`}
          />
        ))}
      </div>
    )
  }

  return (
    <Dialog>
      <DialogTrigger asChild>
        <Button variant="outline" size="sm">
          <History className="h-4 w-4 mr-2" />
          History ({completionHistory.length})
        </Button>
      </DialogTrigger>
      <DialogContent className="sm:max-w-[600px]">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <History className="h-5 w-5" />
            Task History: {task.title}
          </DialogTitle>
        </DialogHeader>
        
        <div className="space-y-4">
          {/* Task Summary */}
          <Card>
            <CardContent className="pt-6">
              <div className="grid grid-cols-3 gap-4 text-center">
                <div>
                  <div className="text-2xl font-bold text-blue-600">{completionHistory.length}</div>
                  <div className="text-sm text-muted-foreground">Completions</div>
                </div>
                <div>
                  <div className="text-2xl font-bold text-green-600">
                    {completionHistory.filter(c => c.rating && c.rating >= 4).length}
                  </div>
                  <div className="text-sm text-muted-foreground">High Rated</div>
                </div>
                <div>
                  <div className="text-2xl font-bold text-purple-600">
                    {Math.round(completionHistory.reduce((acc, c) => acc + (c.rating || 0), 0) / completionHistory.length * 10) / 10 || 0}
                  </div>
                  <div className="text-sm text-muted-foreground">Avg Rating</div>
                </div>
              </div>
            </CardContent>
          </Card>
          
          {/* Completion History */}
          <div className="space-y-2 max-h-96 overflow-y-auto">
            {completionHistory.length === 0 ? (
              <div className="text-center py-8 text-muted-foreground">
                <CheckCircle className="h-12 w-12 mx-auto mb-2 opacity-50" />
                <p>No completion history yet</p>
                <p className="text-sm">Complete this task to see history here</p>
              </div>
            ) : (
              completionHistory.map(completion => (
                <Card key={completion.id} className="transition-all hover:shadow-md">
                  <CardContent className="pt-4">
                    <div className="flex items-start justify-between">
                      <div className="flex items-center gap-3">
                        <div className="flex items-center justify-center w-8 h-8 rounded-full bg-green-100">
                          <CheckCircle className="h-4 w-4 text-green-600" />
                        </div>
                        <div>
                          <div className="flex items-center gap-2">
                            <span className="font-medium text-sm">
                              {formatDate(completion.completedAt)}
                            </span>
                            {completion.rating && renderStars(completion.rating)}
                          </div>
                          <div className="flex items-center gap-1 text-xs text-muted-foreground">
                            <Calendar className="h-3 w-3" />
                            {completion.completedAt.toLocaleDateString()}
                            <Clock className="h-3 w-3 ml-2" />
                            {completion.completedAt.toLocaleTimeString()}
                          </div>
                        </div>
                      </div>
                      <Badge variant="secondary" className="text-xs">
                        Completed
                      </Badge>
                    </div>
                    
                    {completion.notes && (
                      <div className="mt-3 p-3 bg-gray-50 rounded-md">
                        <p className="text-sm text-gray-700">{completion.notes}</p>
                      </div>
                    )}
                  </CardContent>
                </Card>
              ))
            )}
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}

export function TaskHistoryList() {
  const { tasks } = useTask()
  
  const allCompletions = tasks
    .flatMap(task => 
      task.completionHistory.map(completion => ({ ...completion, task }))
    )
    .sort((a, b) => new Date(b.completedAt).getTime() - new Date(a.completedAt).getTime())
    .slice(0, 10) // Show last 10 completions

  const renderStars = (rating?: number) => {
    if (!rating) return null
    
    return (
      <div className="flex items-center gap-1">
        {[1, 2, 3, 4, 5].map(star => (
          <Star
            key={star}
            className={`h-3 w-3 ${star <= rating ? 'fill-yellow-400 text-yellow-400' : 'text-gray-300'}`}
          />
        ))}
      </div>
    )
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <History className="h-5 w-5" />
          Recent Completions
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-3">
          {allCompletions.length === 0 ? (
            <div className="text-center py-8 text-muted-foreground">
              <CheckCircle className="h-12 w-12 mx-auto mb-2 opacity-50" />
              <p>No completed tasks yet</p>
              <p className="text-sm">Complete some tasks to see history here</p>
            </div>
          ) : (
            allCompletions.map(completion => (
              <div key={completion.id} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                <div className="flex items-center gap-3">
                  <div className="flex items-center justify-center w-8 h-8 rounded-full bg-green-100">
                    <CheckCircle className="h-4 w-4 text-green-600" />
                  </div>
                  <div>
                    <div className="font-medium text-sm">{completion.task.title}</div>
                    <div className="flex items-center gap-2 text-xs text-muted-foreground">
                      <span>{formatDate(completion.completedAt)}</span>
                      {completion.rating && renderStars(completion.rating)}
                    </div>
                  </div>
                </div>
                <Badge variant="secondary" className="text-xs">
                  {completion.task.category}
                </Badge>
              </div>
            ))
          )}
        </div>
      </CardContent>
    </Card>
  )
}
