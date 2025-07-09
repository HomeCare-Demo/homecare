'use client'

import { useTask } from '@/contexts/TaskContext'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Header } from '@/components/Navigation'
import { taskCategories } from '@/data/sampleTasks'
import { 
  BarChart3, 
  TrendingUp, 
  TrendingDown,
  Calendar,
  Clock,
  CheckCircle,
  AlertCircle,
  Target,
  Award
} from 'lucide-react'

export function AnalyticsView() {
  const { tasks } = useTask()
  
  const now = new Date()
  const oneWeekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000)
  const oneMonthAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000)

  // Basic Stats
  const totalTasks = tasks.length
  const completedTasks = tasks.filter(t => t.completed).length
  const pendingTasks = totalTasks - completedTasks
  const overdueTasks = tasks.filter(t => t.dueDate < now && !t.completed).length
  const completionRate = totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0

  // Time-based Analytics
  const completedThisWeek = tasks.filter(t => 
    t.lastCompleted && t.lastCompleted >= oneWeekAgo
  ).length
  
  const completedThisMonth = tasks.filter(t => 
    t.lastCompleted && t.lastCompleted >= oneMonthAgo
  ).length

  // Category Analytics
  const categoryStats = taskCategories.map(category => {
    const categoryTasks = tasks.filter(t => t.category === category.value)
    const completed = categoryTasks.filter(t => t.completed).length
    const pending = categoryTasks.length - completed
    const overdue = categoryTasks.filter(t => t.dueDate < now && !t.completed).length
    
    return {
      ...category,
      total: categoryTasks.length,
      completed,
      pending,
      overdue,
      completionRate: categoryTasks.length > 0 ? (completed / categoryTasks.length) * 100 : 0
    }
  }).filter(cat => cat.total > 0)

  // Frequency Analytics
  const frequencyStats = ['weekly', 'monthly', 'quarterly', 'biannually', 'yearly'].map(freq => {
    const freqTasks = tasks.filter(t => t.frequency === freq)
    const completed = freqTasks.filter(t => t.completed).length
    
    return {
      frequency: freq,
      total: freqTasks.length,
      completed,
      pending: freqTasks.length - completed,
      completionRate: freqTasks.length > 0 ? (completed / freqTasks.length) * 100 : 0
    }
  }).filter(freq => freq.total > 0)

  // Priority Analytics
  const priorityStats = ['high', 'medium', 'low'].map(priority => {
    const priorityTasks = tasks.filter(t => t.priority === priority)
    const completed = priorityTasks.filter(t => t.completed).length
    const overdue = priorityTasks.filter(t => t.dueDate < now && !t.completed).length
    
    return {
      priority,
      total: priorityTasks.length,
      completed,
      pending: priorityTasks.length - completed,
      overdue,
      completionRate: priorityTasks.length > 0 ? (completed / priorityTasks.length) * 100 : 0
    }
  }).filter(p => p.total > 0)

  // Recent Activity
  const recentCompletions = tasks
    .filter(t => t.completionHistory.length > 0)
    .flatMap(t => t.completionHistory.map(c => ({ ...c, task: t })))
    .sort((a, b) => new Date(b.completedAt).getTime() - new Date(a.completedAt).getTime())
    .slice(0, 5)

  // Average completion time by category
  const avgCompletionTime = taskCategories.map(category => {
    const categoryTasks = tasks.filter(t => t.category === category.value)
    const totalTime = categoryTasks.reduce((sum, task) => sum + task.estimatedDuration, 0)
    
    return {
      category: category.label,
      color: category.color,
      avgTime: categoryTasks.length > 0 ? Math.round(totalTime / categoryTasks.length) : 0,
      totalTasks: categoryTasks.length
    }
  }).filter(cat => cat.totalTasks > 0)

  return (
    <div className="space-y-6">
      <Header 
        title="Analytics" 
        description="Track your home maintenance performance and insights"
      />

      {/* Overview Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card className="bg-white border border-slate-200">
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-slate-600">Completion Rate</p>
                <p className="text-3xl font-bold text-slate-900">{completionRate.toFixed(1)}%</p>
              </div>
              <Target className="h-8 w-8 text-slate-400" />
            </div>
          </CardContent>
        </Card>

        <Card className="bg-white border border-slate-200">
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-slate-600">This Week</p>
                <p className="text-3xl font-bold text-slate-900">{completedThisWeek}</p>
                <p className="text-xs text-slate-500">completed</p>
              </div>
              <TrendingUp className="h-8 w-8 text-green-500" />
            </div>
          </CardContent>
        </Card>

        <Card className="bg-white border border-slate-200">
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-slate-600">Overdue</p>
                <p className="text-3xl font-bold text-slate-900">{overdueTasks}</p>
                <p className="text-xs text-slate-500">tasks</p>
              </div>
              <AlertCircle className="h-8 w-8 text-red-500" />
            </div>
          </CardContent>
        </Card>

        <Card className="bg-white border border-slate-200">
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-slate-600">This Month</p>
                <p className="text-3xl font-bold text-slate-900">{completedThisMonth}</p>
                <p className="text-xs text-slate-500">completed</p>
              </div>
              <Award className="h-8 w-8 text-blue-500" />
            </div>
          </CardContent>
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Category Performance */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <BarChart3 className="h-5 w-5" />
              Category Performance
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {categoryStats.map(category => (
                <div key={category.value} className="space-y-2">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <Badge className={category.color}>{category.label}</Badge>
                      <span className="text-sm text-muted-foreground">
                        {category.total} tasks
                      </span>
                    </div>
                    <span className="text-sm font-medium">
                      {category.completionRate.toFixed(1)}%
                    </span>
                  </div>
                  <div className="w-full bg-gray-200 rounded-full h-2">
                    <div 
                      className="bg-primary h-2 rounded-full transition-all"
                      style={{ width: `${category.completionRate}%` }}
                    />
                  </div>
                  <div className="flex justify-between text-xs text-muted-foreground">
                    <span>Completed: {category.completed}</span>
                    <span>Pending: {category.pending}</span>
                    {category.overdue > 0 && (
                      <span className="text-red-600">Overdue: {category.overdue}</span>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* Priority Distribution */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Target className="h-5 w-5" />
              Priority Distribution
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {priorityStats.map(priority => (
                <div key={priority.priority} className="space-y-2">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <Badge 
                        className={
                          priority.priority === 'high' ? 'bg-red-100 text-red-800' :
                          priority.priority === 'medium' ? 'bg-yellow-100 text-yellow-800' :
                          'bg-green-100 text-green-800'
                        }
                      >
                        {priority.priority} priority
                      </Badge>
                      <span className="text-sm text-muted-foreground">
                        {priority.total} tasks
                      </span>
                    </div>
                    <span className="text-sm font-medium">
                      {priority.completionRate.toFixed(1)}%
                    </span>
                  </div>
                  <div className="w-full bg-gray-200 rounded-full h-2">
                    <div 
                      className={`h-2 rounded-full transition-all ${
                        priority.priority === 'high' ? 'bg-red-500' :
                        priority.priority === 'medium' ? 'bg-yellow-500' :
                        'bg-green-500'
                      }`}
                      style={{ width: `${priority.completionRate}%` }}
                    />
                  </div>
                  <div className="flex justify-between text-xs text-muted-foreground">
                    <span>Completed: {priority.completed}</span>
                    <span>Pending: {priority.pending}</span>
                    {priority.overdue > 0 && (
                      <span className="text-red-600">Overdue: {priority.overdue}</span>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* Frequency Analysis */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Calendar className="h-5 w-5" />
              Frequency Analysis
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {frequencyStats.map(freq => (
                <div key={freq.frequency} className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <span className="text-sm font-medium capitalize">{freq.frequency}</span>
                    <Badge variant="secondary">{freq.total} tasks</Badge>
                  </div>
                  <div className="text-right">
                    <div className="text-sm font-medium">{freq.completionRate.toFixed(1)}%</div>
                    <div className="text-xs text-muted-foreground">
                      {freq.completed}/{freq.total} completed
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* Average Time by Category */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Clock className="h-5 w-5" />
              Average Time by Category
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {avgCompletionTime.map(cat => (
                <div key={cat.category} className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <Badge className={cat.color}>{cat.category}</Badge>
                  </div>
                  <div className="text-right">
                    <div className="text-sm font-medium">{cat.avgTime} min</div>
                    <div className="text-xs text-muted-foreground">
                      {cat.totalTasks} tasks
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Recent Activity */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <CheckCircle className="h-5 w-5" />
            Recent Completions
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            {recentCompletions.length === 0 ? (
              <p className="text-center text-muted-foreground py-8">
                No recent completions
              </p>
            ) : (
              recentCompletions.map(completion => (
                <div key={completion.id} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                  <div className="flex items-center gap-3">
                    <div className="flex items-center justify-center w-8 h-8 rounded-full bg-green-100">
                      <CheckCircle className="h-4 w-4 text-green-600" />
                    </div>
                    <div>
                      <div className="font-medium text-sm">{completion.task.title}</div>
                      <div className="text-xs text-muted-foreground">
                        {new Date(completion.completedAt).toLocaleDateString()}
                      </div>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    {completion.rating && (
                      <div className="flex items-center gap-1">
                        {[...Array(5)].map((_, i) => (
                          <div
                            key={i}
                            className={`w-2 h-2 rounded-full ${
                              i < completion.rating! ? 'bg-yellow-400' : 'bg-gray-300'
                            }`}
                          />
                        ))}
                      </div>
                    )}
                    <Badge variant="secondary" className="text-xs">
                      {completion.task.category}
                    </Badge>
                  </div>
                </div>
              ))
            )}
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
