'use client'

import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { cn } from '@/lib/utils'
import { 
  Home, 
  Calendar, 
  List, 
  Plus, 
  Settings, 
  Filter,
  BarChart3
} from 'lucide-react'

interface NavigationProps {
  activeView: string
  onViewChange: (view: string) => void
  onAddTask: () => void
}

export function Navigation({ activeView, onViewChange, onAddTask }: NavigationProps) {
  const [collapsed, setCollapsed] = useState(false)

  const navItems = [
    { id: 'dashboard', label: 'Dashboard', icon: Home },
    { id: 'tasks', label: 'All Tasks', icon: List },
    { id: 'calendar', label: 'Calendar', icon: Calendar },
    { id: 'analytics', label: 'Analytics', icon: BarChart3 },
  ]

  return (
    <Card className="h-full">
      <CardContent className="p-4">
        <div className="space-y-6">
          {/* Logo */}
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-slate-100 border border-slate-200">
              <Home className="h-6 w-6 text-slate-700" />
            </div>
            {!collapsed && (
              <div>
                <h2 className="text-xl font-bold text-slate-900">HomeCare</h2>
                <p className="text-xs text-slate-600">Home Maintenance</p>
              </div>
            )}
          </div>

          {/* Add Task Button */}
          <Button 
            onClick={onAddTask}
            className="w-full bg-slate-900 hover:bg-slate-800 text-white"
            size={collapsed ? "icon" : "default"}
          >
            <Plus className="h-4 w-4" />
            {!collapsed && <span className="ml-2">Add Task</span>}
          </Button>

          {/* Navigation Items */}
          <nav className="space-y-2">
            {navItems.map((item) => {
              const Icon = item.icon
              const isActive = activeView === item.id
              
              return (
                <Button
                  key={item.id}
                  variant={isActive ? "secondary" : "ghost"}
                  className={cn(
                    "w-full justify-start transition-all",
                    isActive && "bg-primary/10 text-primary border-primary/20",
                    collapsed && "justify-center"
                  )}
                  onClick={() => onViewChange(item.id)}
                  size={collapsed ? "icon" : "default"}
                >
                  <Icon className="h-4 w-4" />
                  {!collapsed && <span className="ml-2">{item.label}</span>}
                </Button>
              )
            })}
          </nav>

          {/* Collapse Toggle */}
          <div className="pt-4 border-t">
            <Button
              variant="ghost"
              size="sm"
              onClick={() => setCollapsed(!collapsed)}
              className="w-full"
            >
              <Filter className="h-4 w-4" />
              {!collapsed && <span className="ml-2">Collapse</span>}
            </Button>
          </div>
        </div>
      </CardContent>
    </Card>
  )
}

export function Header({ title, description }: { title: string; description?: string }) {
  return (
    <div className="mb-6">
      <h1 className="text-3xl font-bold tracking-tight">{title}</h1>
      {description && (
        <p className="text-muted-foreground mt-2">{description}</p>
      )}
    </div>
  )
}
