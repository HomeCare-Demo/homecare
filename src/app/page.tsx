'use client';

import { useState } from 'react';
import { Navigation } from '@/components/Navigation';
import { Dashboard } from '@/components/Dashboard';
import { TasksView } from '@/components/TasksView';
import { CalendarViewPage } from '@/components/CalendarViewPage';
import { AnalyticsView } from '@/components/AnalyticsView';
import { TaskFormDialog } from '@/components/TaskFormDialog';
import { Task } from '@/types/task';

export default function Home() {
  const [activeView, setActiveView] = useState('dashboard');
  const [showAddTaskDialog, setShowAddTaskDialog] = useState(false);
  const [editingTask, setEditingTask] = useState<Task | undefined>();

  const handleAddTask = () => {
    setEditingTask(undefined);
    setShowAddTaskDialog(true);
  };

  const handleEditTask = (task: Task) => {
    setEditingTask(task);
    setShowAddTaskDialog(true);
  };

  const handleCloseDialog = () => {
    setShowAddTaskDialog(false);
    setEditingTask(undefined);
  };

  const renderView = () => {
    switch (activeView) {
      case 'dashboard':
        return <Dashboard onEditTask={handleEditTask} />;
      case 'tasks':
        return <TasksView onEditTask={handleEditTask} />;
      case 'calendar':
        return <CalendarViewPage onEditTask={handleEditTask} />;
      case 'analytics':
        return <AnalyticsView />;
      default:
        return <Dashboard onEditTask={handleEditTask} />;
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="flex h-screen">
        {/* Sidebar */}
        <div className="w-64 bg-white shadow-lg">
          <Navigation
            activeView={activeView}
            onViewChange={setActiveView}
            onAddTask={handleAddTask}
          />
        </div>

        {/* Main Content */}
        <div className="flex-1 overflow-auto">
          <main className="p-6">{renderView()}</main>
        </div>
      </div>

      {/* Add/Edit Task Dialog */}
      <TaskFormDialog
        task={editingTask}
        open={showAddTaskDialog}
        onOpenChange={handleCloseDialog}
      />
    </div>
  );
}
