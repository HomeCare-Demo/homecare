'use client'

import { Task } from '@/types/task'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { taskCategories } from '@/data/sampleTasks'
import { format, startOfMonth, endOfMonth, eachDayOfInterval, isSameDay, isToday, isSameMonth } from 'date-fns'
import { ChevronLeft, ChevronRight, Calendar as CalendarIcon } from 'lucide-react'
import { useState } from 'react'
import { useTask } from '@/contexts/TaskContext'

interface CalendarViewProps {
  tasks: Task[]
  onTaskClick: (task: Task) => void
}

export function CalendarView({ tasks, onTaskClick }: CalendarViewProps) {
  const [currentDate, setCurrentDate] = useState(new Date())
  
  const monthStart = startOfMonth(currentDate)
  const monthEnd = endOfMonth(currentDate)
  const days = eachDayOfInterval({ start: monthStart, end: monthEnd })
  
  const goToPreviousMonth = () => {
    setCurrentDate(new Date(currentDate.getFullYear(), currentDate.getMonth() - 1, 1))
  }
  
  const goToNextMonth = () => {
    setCurrentDate(new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 1))
  }
  
  const getTasksForDay = (date: Date) => {
    return tasks.filter(task => isSameDay(task.dueDate, date))
  }

  const getDayClasses = (date: Date) => {
    const baseClasses = 'min-h-[100px] p-2 border border-gray-100 cursor-pointer hover:bg-gray-50 transition-colors'
    
    if (!isSameMonth(date, currentDate)) {
      return `${baseClasses} bg-gray-50 text-gray-400`
    }
    
    if (isToday(date)) {
      return `${baseClasses} bg-blue-50 border-blue-200`
    }
    
    return baseClasses
  }

  const weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']

  return (
    <Card className="w-full">
      <CardHeader>
        <div className="flex items-center justify-between">
          <CardTitle className="flex items-center gap-2">
            <CalendarIcon className="h-5 w-5" />
            Calendar View
          </CardTitle>
          <div className="flex items-center gap-2">
            <Button variant="outline" size="sm" onClick={goToPreviousMonth}>
              <ChevronLeft className="h-4 w-4" />
            </Button>
            <div className="font-semibold min-w-[140px] text-center">
              {format(currentDate, 'MMMM yyyy')}
            </div>
            <Button variant="outline" size="sm" onClick={goToNextMonth}>
              <ChevronRight className="h-4 w-4" />
            </Button>
          </div>
        </div>
      </CardHeader>
      
      <CardContent className="p-0">
        <div className="grid grid-cols-7 border-b">
          {weekDays.map(day => (
            <div key={day} className="p-3 text-center font-semibold text-sm bg-gray-50 border-r last:border-r-0">
              {day}
            </div>
          ))}
        </div>
        
        <div className="grid grid-cols-7">
          {days.map(day => {
            const dayTasks = getTasksForDay(day)
            
            return (
              <div key={day.toISOString()} className={getDayClasses(day)}>
                <div className="flex items-center justify-between mb-1">
                  <span className={`text-sm font-medium ${isToday(day) ? 'text-blue-600' : ''}`}>
                    {format(day, 'd')}
                  </span>
                  {dayTasks.length > 0 && (
                    <Badge variant="secondary" className="text-xs">
                      {dayTasks.length}
                    </Badge>
                  )}
                </div>
                
                <div className="space-y-1">
                  {dayTasks.slice(0, 3).map(task => {
                    const categoryInfo = taskCategories.find(cat => cat.value === task.category)
                    const isOverdue = task.dueDate < new Date() && !task.completed
                    
                    return (
                      <div
                        key={task.id}
                        className={`text-xs p-1 rounded cursor-pointer transition-colors ${
                          task.completed 
                            ? 'bg-green-100 text-green-800 line-through' 
                            : isOverdue 
                              ? 'bg-red-100 text-red-800' 
                              : 'bg-blue-100 text-blue-800'
                        } hover:opacity-80`}
                        onClick={() => onTaskClick(task)}
                        title={task.title}
                      >
                        <div className="truncate font-medium">{task.title}</div>
                        <div className="flex items-center justify-between">
                          <Badge className="text-xs bg-slate-100 text-slate-700 border-slate-200">
                            {categoryInfo?.label}
                          </Badge>
                          <span className="text-xs opacity-70">
                            {task.estimatedDuration}m
                          </span>
                        </div>
                      </div>
                    )
                  })}
                  
                  {dayTasks.length > 3 && (
                    <div className="text-xs text-gray-500 text-center py-1">
                      +{dayTasks.length - 3} more
                    </div>
                  )}
                </div>
              </div>
            )
          })}
        </div>
      </CardContent>
    </Card>
  )
}

export function MiniCalendar() {
  const { tasks } = useTask()
  const [currentDate, setCurrentDate] = useState(new Date())
  
  const monthStart = startOfMonth(currentDate)
  const monthEnd = endOfMonth(currentDate)
  const days = eachDayOfInterval({ start: monthStart, end: monthEnd })
  
  const goToPreviousMonth = () => {
    setCurrentDate(new Date(currentDate.getFullYear(), currentDate.getMonth() - 1, 1))
  }
  
  const goToNextMonth = () => {
    setCurrentDate(new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 1))
  }
  
  const getTasksForDay = (date: Date) => {
    return tasks.filter(task => isSameDay(task.dueDate, date))
  }

  const weekDays = ['S', 'M', 'T', 'W', 'T', 'F', 'S']

  return (
    <Card className="w-full">
      <CardHeader className="pb-2">
        <div className="flex items-center justify-between">
          <Button variant="ghost" size="sm" onClick={goToPreviousMonth}>
            <ChevronLeft className="h-4 w-4" />
          </Button>
          <div className="font-semibold text-sm">
            {format(currentDate, 'MMM yyyy')}
          </div>
          <Button variant="ghost" size="sm" onClick={goToNextMonth}>
            <ChevronRight className="h-4 w-4" />
          </Button>
        </div>
      </CardHeader>
      
      <CardContent className="p-2">
        <div className="grid grid-cols-7 gap-1 mb-2">
          {weekDays.map((day, index) => (
            <div key={`${day}-${index}`} className="text-center text-xs font-medium text-gray-500 p-1">
              {day}
            </div>
          ))}
        </div>
        
        <div className="grid grid-cols-7 gap-1">
          {days.map(day => {
            const dayTasks = getTasksForDay(day)
            const hasOverdue = dayTasks.some(task => task.dueDate < new Date() && !task.completed)
            
            return (
              <div
                key={day.toISOString()}
                className={`
                  aspect-square flex items-center justify-center text-xs cursor-pointer rounded transition-colors
                  ${!isSameMonth(day, currentDate) ? 'text-gray-300' : ''}
                  ${isToday(day) ? 'bg-blue-500 text-white' : 'hover:bg-gray-100'}
                  ${hasOverdue ? 'bg-red-100 text-red-800' : ''}
                  ${dayTasks.length > 0 && !hasOverdue ? 'bg-blue-100 text-blue-800' : ''}
                `}
              >
                <div className="flex flex-col items-center">
                  <span>{format(day, 'd')}</span>
                  {dayTasks.length > 0 && (
                    <div className="w-1 h-1 bg-current rounded-full mt-1" />
                  )}
                </div>
              </div>
            )
          })}
        </div>
      </CardContent>
    </Card>
  )
}
