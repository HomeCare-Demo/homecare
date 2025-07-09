'use client'

import { useTask } from '@/contexts/TaskContext'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { TaskCard } from '@/components/TaskCard'
import { MiniCalendar } from '@/components/CalendarView'
import { TaskHistoryList } from '@/components/TaskHistory'
import { 
  Home, 
  AlertCircle, 
  CheckCircle, 
  Clock, 
  Calendar,
  TrendingUp,
  Zap
} from 'lucide-react'

interface DashboardProps {
  onEditTask: (task: any) => void
}

export function Dashboard({ onEditTask }: DashboardProps) {
  const { tasks } = useTask()
  
  const now = new Date()
  const todayTasks = tasks.filter(task => {
    const taskDate = new Date(task.dueDate)
    return taskDate.toDateString() === now.toDateString()
  })
  
  const overdueTasks = tasks.filter(task => 
    task.dueDate < now && !task.completed
  )
  
  const upcomingTasks = tasks.filter(task => {
    const diffDays = Math.ceil((task.dueDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24))
    return diffDays > 0 && diffDays <= 7 && !task.completed
  })
  
  const completedThisWeek = tasks.filter(task => {
    const weekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000)
    return task.lastCompleted && task.lastCompleted >= weekAgo
  })

  const totalTasks = tasks.length
  const completedTasks = tasks.filter(t => t.completed).length
  const completionRate = totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0

  const priorityTasks = tasks.filter(task => task.priority === 'high' && !task.completed)

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-slate-900">
            HomeCare Dashboard
          </h1>
          <p className="text-muted-foreground mt-2">
            Keep your home in perfect condition with smart maintenance tracking
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Home className="h-8 w-8 text-primary" />
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card className="bg-white border border-slate-200">
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-slate-600">Total Tasks</p>
                <p className="text-3xl font-bold text-slate-900">{totalTasks}</p>
              </div>
              <Home className="h-8 w-8 text-slate-400" />
            </div>
          </CardContent>
        </Card>

        <Card className="bg-white border border-slate-200">
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-slate-600">Completed</p>
                <p className="text-3xl font-bold text-slate-900">{completedTasks}</p>
                <p className="text-xs text-slate-500">{completionRate.toFixed(1)}% rate</p>
              </div>
              <CheckCircle className="h-8 w-8 text-green-500" />
            </div>
          </CardContent>
        </Card>

        <Card className="bg-white border border-slate-200">
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-slate-600">Overdue</p>
                <p className="text-3xl font-bold text-slate-900">{overdueTasks.length}</p>
              </div>
              <AlertCircle className="h-8 w-8 text-red-500" />
            </div>
          </CardContent>
        </Card>

        <Card className="bg-white border border-slate-200">
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-slate-600">Due Today</p>
                <p className="text-3xl font-bold text-slate-900">{todayTasks.length}</p>
              </div>
              <Clock className="h-8 w-8 text-blue-500" />
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Main Content Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left Column - Tasks */}
        <div className="lg:col-span-2 space-y-6">
          {/* High Priority Tasks */}
          {priorityTasks.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2 text-red-600">
                  <Zap className="h-5 w-5" />
                  High Priority Tasks
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  {priorityTasks.slice(0, 3).map(task => (
                    <TaskCard 
                      key={task.id} 
                      task={task} 
                      onEdit={onEditTask}
                      showDetails={false}
                    />
                  ))}
                </div>
              </CardContent>
            </Card>
          )}

          {/* Overdue Tasks */}
          {overdueTasks.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2 text-red-600">
                  <AlertCircle className="h-5 w-5" />
                  Overdue Tasks ({overdueTasks.length})
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  {overdueTasks.slice(0, 3).map(task => (
                    <TaskCard 
                      key={task.id} 
                      task={task} 
                      onEdit={onEditTask}
                      showDetails={false}
                    />
                  ))}
                  {overdueTasks.length > 3 && (
                    <p className="text-sm text-muted-foreground text-center">
                      +{overdueTasks.length - 3} more overdue tasks
                    </p>
                  )}
                </div>
              </CardContent>
            </Card>
          )}

          {/* Today's Tasks */}
          {todayTasks.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Calendar className="h-5 w-5" />
                  Due Today ({todayTasks.length})
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  {todayTasks.map(task => (
                    <TaskCard 
                      key={task.id} 
                      task={task} 
                      onEdit={onEditTask}
                      showDetails={false}
                    />
                  ))}
                </div>
              </CardContent>
            </Card>
          )}

          {/* Upcoming Tasks */}
          {upcomingTasks.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <TrendingUp className="h-5 w-5" />
                  Upcoming This Week ({upcomingTasks.length})
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  {upcomingTasks.slice(0, 5).map(task => (
                    <TaskCard 
                      key={task.id} 
                      task={task} 
                      onEdit={onEditTask}
                      showDetails={false}
                    />
                  ))}
                </div>
              </CardContent>
            </Card>
          )}

          {/* When no urgent tasks */}
          {overdueTasks.length === 0 && todayTasks.length === 0 && priorityTasks.length === 0 && (
            <Card className="text-center p-8">
              <CheckCircle className="h-16 w-16 mx-auto mb-4 text-green-500" />
              <h3 className="text-xl font-semibold mb-2">All caught up!</h3>
              <p className="text-muted-foreground">
                No overdue or urgent tasks. Great job keeping your home maintained!
              </p>
            </Card>
          )}
        </div>

        {/* Right Column - Sidebar */}
        <div className="space-y-6">
          {/* Mini Calendar */}
          <MiniCalendar />

          {/* Quick Stats */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Quick Stats</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="flex justify-between items-center">
                <span className="text-sm text-muted-foreground">Completion Rate</span>
                <Badge variant="secondary">{completionRate.toFixed(1)}%</Badge>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm text-muted-foreground">This Week</span>
                <Badge variant="secondary">{completedThisWeek.length} completed</Badge>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm text-muted-foreground">Upcoming</span>
                <Badge variant="secondary">{upcomingTasks.length} tasks</Badge>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm text-muted-foreground">High Priority</span>
                <Badge variant="secondary">{priorityTasks.length} tasks</Badge>
              </div>
            </CardContent>
          </Card>

          {/* Task History */}
          <TaskHistoryList />
        </div>
      </div>
    </div>
  )
}
