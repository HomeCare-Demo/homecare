'use client'

import { useState } from 'react'
import { useTask } from '@/contexts/TaskContext'
import { CalendarView } from '@/components/CalendarView'
import { TaskFormDialog } from '@/components/TaskFormDialog'
import { Header } from '@/components/Navigation'
import { Card, CardContent } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { taskCategories } from '@/data/sampleTasks'
import { formatDate } from '@/lib/utils'
import { Calendar, Clock, MapPin } from 'lucide-react'

interface CalendarViewPageProps {
  onEditTask: (task: any) => void
}

export function CalendarViewPage({ onEditTask }: CalendarViewPageProps) {
  const { tasks } = useTask()
  const [selectedTask, setSelectedTask] = useState<any>(null)
  const [showTaskDialog, setShowTaskDialog] = useState(false)

  const handleTaskClick = (task: any) => {
    setSelectedTask(task)
    setShowTaskDialog(true)
  }

  const handleEditTask = (task: any) => {
    setShowTaskDialog(false)
    onEditTask(task)
  }

  const upcomingTasks = tasks
    .filter(task => !task.completed && task.dueDate >= new Date())
    .sort((a, b) => a.dueDate.getTime() - b.dueDate.getTime())
    .slice(0, 5)

  return (
    <div className="space-y-6">
      <Header 
        title="Calendar View" 
        description="View your maintenance tasks in a calendar format"
      />

      <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
        {/* Calendar */}
        <div className="lg:col-span-3">
          <CalendarView tasks={tasks} onTaskClick={handleTaskClick} />
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Upcoming Tasks */}
          <Card>
            <CardContent className="p-6">
              <div className="flex items-center gap-2 mb-4">
                <Clock className="h-5 w-5 text-primary" />
                <h3 className="font-semibold">Upcoming Tasks</h3>
              </div>
              <div className="space-y-3">
                {upcomingTasks.length === 0 ? (
                  <p className="text-sm text-muted-foreground text-center py-4">
                    No upcoming tasks
                  </p>
                ) : (
                  upcomingTasks.map(task => {
                    const categoryInfo = taskCategories.find(cat => cat.value === task.category)
                    
                    return (
                      <div
                        key={task.id}
                        className="p-3 border rounded-lg cursor-pointer hover:bg-gray-50 transition-colors"
                        onClick={() => handleTaskClick(task)}
                      >
                        <div className="flex items-start justify-between">
                          <div className="flex-1">
                            <h4 className="font-medium text-sm">{task.title}</h4>
                            <p className="text-xs text-muted-foreground mt-1">
                              {formatDate(task.dueDate)}
                            </p>
                          </div>
                          <Badge className="text-xs bg-slate-100 text-slate-700 border-slate-200">
                            {categoryInfo?.label}
                          </Badge>
                        </div>
                      </div>
                    )
                  })
                )}
              </div>
            </CardContent>
          </Card>

          {/* Legend */}
          <Card>
            <CardContent className="p-6">
              <div className="flex items-center gap-2 mb-4">
                <MapPin className="h-5 w-5 text-primary" />
                <h3 className="font-semibold">Legend</h3>
              </div>
              <div className="space-y-2">
                <div className="flex items-center gap-2">
                  <div className="w-3 h-3 bg-blue-100 border border-blue-200 rounded"></div>
                  <span className="text-sm">Pending Tasks</span>
                </div>
                <div className="flex items-center gap-2">
                  <div className="w-3 h-3 bg-red-100 border border-red-200 rounded"></div>
                  <span className="text-sm">Overdue Tasks</span>
                </div>
                <div className="flex items-center gap-2">
                  <div className="w-3 h-3 bg-green-100 border border-green-200 rounded"></div>
                  <span className="text-sm">Completed Tasks</span>
                </div>
                <div className="flex items-center gap-2">
                  <div className="w-3 h-3 bg-blue-500 border border-blue-600 rounded"></div>
                  <span className="text-sm">Today</span>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Quick Stats */}
          <Card>
            <CardContent className="p-6">
              <div className="flex items-center gap-2 mb-4">
                <Calendar className="h-5 w-5 text-primary" />
                <h3 className="font-semibold">This Month</h3>
              </div>
              <div className="space-y-2">
                <div className="flex justify-between">
                  <span className="text-sm">Total Tasks</span>
                  <span className="text-sm font-medium">{tasks.length}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm">Completed</span>
                  <span className="text-sm font-medium">{tasks.filter(t => t.completed).length}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm">Pending</span>
                  <span className="text-sm font-medium">{tasks.filter(t => !t.completed).length}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm">Overdue</span>
                  <span className="text-sm font-medium text-red-600">
                    {tasks.filter(t => t.dueDate < new Date() && !t.completed).length}
                  </span>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>

      {/* Task Detail Dialog */}
      {selectedTask && (
        <TaskFormDialog
          task={selectedTask}
          open={showTaskDialog}
          onOpenChange={(open) => {
            if (!open) {
              setSelectedTask(null)
            }
            setShowTaskDialog(open)
          }}
        />
      )}
    </div>
  )
}
