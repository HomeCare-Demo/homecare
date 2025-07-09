'use client'

import { useState } from 'react'
import { useTask } from '@/contexts/TaskContext'
import { TaskCard } from '@/components/TaskCard'
import { TaskFilters } from '@/components/TaskFilters'
import { Header } from '@/components/Navigation'
import { TaskFilter } from '@/types/task'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { List, Grid, SortAsc, SortDesc } from 'lucide-react'

interface TasksViewProps {
  onEditTask: (task: any) => void
}

export function TasksView({ onEditTask }: TasksViewProps) {
  const { tasks, filterTasks } = useTask()
  const [filters, setFilters] = useState<TaskFilter>({})
  const [sortBy, setSortBy] = useState<string>('dueDate')
  const [sortOrder, setSortOrder] = useState<'asc' | 'desc'>('asc')
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid')

  const filteredTasks = filterTasks(filters)
  
  const sortedTasks = [...filteredTasks].sort((a, b) => {
    let aValue: any, bValue: any
    
    switch (sortBy) {
      case 'dueDate':
        aValue = a.dueDate.getTime()
        bValue = b.dueDate.getTime()
        break
      case 'title':
        aValue = a.title.toLowerCase()
        bValue = b.title.toLowerCase()
        break
      case 'priority':
        const priorityOrder = { high: 3, medium: 2, low: 1 }
        aValue = priorityOrder[a.priority]
        bValue = priorityOrder[b.priority]
        break
      case 'category':
        aValue = a.category
        bValue = b.category
        break
      case 'frequency':
        aValue = a.frequency
        bValue = b.frequency
        break
      default:
        aValue = a.dueDate.getTime()
        bValue = b.dueDate.getTime()
    }
    
    if (sortOrder === 'asc') {
      return aValue < bValue ? -1 : aValue > bValue ? 1 : 0
    } else {
      return aValue > bValue ? -1 : aValue < bValue ? 1 : 0
    }
  })

  const toggleSortOrder = () => {
    setSortOrder(prev => prev === 'asc' ? 'desc' : 'asc')
  }

  const pendingTasks = sortedTasks.filter(task => !task.completed)
  const completedTasks = sortedTasks.filter(task => task.completed)

  return (
    <div className="space-y-6">
      <Header 
        title="All Tasks" 
        description="Manage all your home maintenance tasks"
      />

      <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
        {/* Filters Sidebar */}
        <div className="lg:col-span-1">
          <TaskFilters filters={filters} onFiltersChange={setFilters} />
        </div>

        {/* Main Content */}
        <div className="lg:col-span-3 space-y-6">
          {/* Controls */}
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <CardTitle className="text-lg">
                  Tasks ({sortedTasks.length})
                </CardTitle>
                <div className="flex items-center gap-2">
                  {/* View Mode Toggle */}
                  <div className="flex items-center border rounded-lg">
                    <Button
                      variant={viewMode === 'grid' ? 'default' : 'ghost'}
                      size="sm"
                      onClick={() => setViewMode('grid')}
                    >
                      <Grid className="h-4 w-4" />
                    </Button>
                    <Button
                      variant={viewMode === 'list' ? 'default' : 'ghost'}
                      size="sm"
                      onClick={() => setViewMode('list')}
                    >
                      <List className="h-4 w-4" />
                    </Button>
                  </div>

                  {/* Sort Controls */}
                  <div className="flex items-center gap-2">
                    <Select value={sortBy} onValueChange={setSortBy}>
                      <SelectTrigger className="w-32">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="dueDate">Due Date</SelectItem>
                        <SelectItem value="title">Title</SelectItem>
                        <SelectItem value="priority">Priority</SelectItem>
                        <SelectItem value="category">Category</SelectItem>
                        <SelectItem value="frequency">Frequency</SelectItem>
                      </SelectContent>
                    </Select>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={toggleSortOrder}
                    >
                      {sortOrder === 'asc' ? <SortAsc className="h-4 w-4" /> : <SortDesc className="h-4 w-4" />}
                    </Button>
                  </div>
                </div>
              </div>
            </CardHeader>
          </Card>

          {/* Tasks List */}
          {sortedTasks.length === 0 ? (
            <Card>
              <CardContent className="py-12 text-center">
                <List className="h-16 w-16 mx-auto mb-4 text-muted-foreground" />
                <h3 className="text-lg font-semibold mb-2">No tasks found</h3>
                <p className="text-muted-foreground">
                  {Object.keys(filters).length > 0 
                    ? 'Try adjusting your filters to see more tasks.'
                    : 'Create your first task to get started!'
                  }
                </p>
              </CardContent>
            </Card>
          ) : (
            <div className="space-y-6">
              {/* Pending Tasks */}
              {pendingTasks.length > 0 && (
                <div className="space-y-4">
                  <div className="flex items-center gap-2">
                    <h3 className="text-lg font-semibold">Pending Tasks</h3>
                    <Badge variant="secondary">{pendingTasks.length}</Badge>
                  </div>
                  <div className={viewMode === 'grid' 
                    ? 'grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4' 
                    : 'space-y-3'
                  }>
                    {pendingTasks.map(task => (
                      <TaskCard
                        key={task.id}
                        task={task}
                        onEdit={onEditTask}
                        showDetails={viewMode === 'list'}
                      />
                    ))}
                  </div>
                </div>
              )}

              {/* Completed Tasks */}
              {completedTasks.length > 0 && (
                <div className="space-y-4">
                  <div className="flex items-center gap-2">
                    <h3 className="text-lg font-semibold">Completed Tasks</h3>
                    <Badge variant="secondary">{completedTasks.length}</Badge>
                  </div>
                  <div className={viewMode === 'grid' 
                    ? 'grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4' 
                    : 'space-y-3'
                  }>
                    {completedTasks.map(task => (
                      <TaskCard
                        key={task.id}
                        task={task}
                        onEdit={onEditTask}
                        showDetails={viewMode === 'list'}
                      />
                    ))}
                  </div>
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
