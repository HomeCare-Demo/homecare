# HomeCare - Home Maintenance Tracker

## Project Overview

HomeCare is a comprehensive Next.js application designed to help users manage and track their home maintenance tasks. The application provides a beautiful, modern interface for scheduling, tracking, and analyzing home maintenance activities.

## Tech Stack

### Frontend
- **Next.js 15** - React framework with App Router
- **TypeScript** - Type-safe JavaScript
- **Tailwind CSS** - Utility-first CSS framework
- **ShadCN UI** - Component library built on Radix UI
- **Lucide React** - Icon library

### Key Dependencies
- **@radix-ui/react-*** - Unstyled, accessible UI components
- **class-variance-authority** - CSS class variance handling
- **clsx** - Conditional class names
- **tailwind-merge** - Tailwind CSS class merging
- **date-fns** - Date manipulation library

### DevOps & Deployment
- **Docker** - Containerization with multi-stage builds
- **Kubernetes** - Container orchestration
- **Kustomize** - Kubernetes configuration management
- **Docker Compose** - Local development environment

## Architecture

### Component Structure
```
src/
├── app/                    # Next.js App Router
│   ├── globals.css        # Global styles with design system
│   ├── layout.tsx         # Root layout with providers
│   └── page.tsx           # Main application page
├── components/            # React components
│   ├── ui/               # ShadCN UI components
│   ├── Dashboard.tsx     # Main dashboard view
│   ├── TaskCard.tsx      # Individual task display
│   ├── TaskFormDialog.tsx # Task creation/editing
│   ├── TaskFilters.tsx   # Filtering and search
│   ├── TasksView.tsx     # All tasks view
│   ├── CalendarView.tsx  # Calendar components
│   ├── TaskHistory.tsx   # Task completion history
│   ├── AnalyticsView.tsx # Analytics and reporting
│   └── Navigation.tsx    # Sidebar navigation
├── contexts/             # React contexts
│   └── TaskContext.tsx   # Task state management
├── data/                 # Sample data
│   └── sampleTasks.ts    # Mock task data
├── lib/                  # Utility functions
│   └── utils.ts          # Common utilities
└── types/                # TypeScript type definitions
    └── task.ts           # Task-related types
```

### State Management
- **React Context** - Global task state management
- **useState/useEffect** - Local component state
- **Frontend-only** - No backend integration, uses sample data

### Design System
- **CSS Variables** - Consistent theming
- **Gradients** - Beautiful visual elements
- **Smooth Animations** - Enhanced UX
- **Responsive Design** - Desktop-first approach

## Key Features

### Core Functionality
1. **Task Management**
   - Add, edit, delete tasks
   - Mark tasks as complete
   - Task categorization (electrical, plumbing, HVAC, etc.)
   - Frequency scheduling (weekly, monthly, quarterly, etc.)

2. **Views**
   - Dashboard with overview and priorities
   - List view with filtering and sorting
   - Calendar view for visual scheduling
   - Analytics view with performance metrics

3. **Task Properties**
   - Title and description
   - Category and frequency
   - Due dates and priority
   - Estimated duration
   - Completion history with ratings

### User Experience
- **Filtering** - By category, frequency, priority, completion status
- **Search** - Text search across task titles and descriptions
- **Sorting** - Multiple sort options (due date, priority, etc.)
- **History Tracking** - Completion logs with notes and ratings
- **Visual Indicators** - Color-coded priorities and status

## Development Guidelines

### Code Style
- Use TypeScript for all components
- Follow React best practices (hooks, functional components)
- Implement proper error handling
- Use meaningful component and variable names

### Component Patterns
- **Composition over inheritance**
- **Props interfaces** for all components
- **Context for global state**
- **Custom hooks** for reusable logic

### Styling
- Use Tailwind utility classes
- Follow design system variables
- Implement smooth transitions
- Mobile-first responsive design (when needed)

### State Management
- Use TaskContext for global task operations
- Local state for component-specific data
- Proper cleanup in useEffect hooks

## File Conventions

### Naming
- Components: PascalCase (TaskCard.tsx)
- Hooks: camelCase with 'use' prefix (useTask.ts)
- Types: PascalCase (Task, TaskFilter)
- Utilities: camelCase (formatDate, generateId)

### Import Structure
```typescript
// External libraries
import { useState } from 'react'
import { Button } from '@/components/ui/button'

// Internal components
import { TaskCard } from '@/components/TaskCard'

// Types and utilities
import { Task } from '@/types/task'
import { cn } from '@/lib/utils'
```

## Deployment

### Docker
- Multi-stage build for production
- Non-root user for security
- Health checks implemented
- Standalone Next.js output

### Kubernetes
- Kustomize for configuration management
- Separate dev/prod environments
- Horizontal pod autoscaling ready
- Resource limits and requests configured

### Commands
```bash
# Development
npm run dev

# Production build
npm run build

# Docker build
docker build -t homecare-app .

# Kubernetes deploy (dev)
kubectl apply -k k8s/overlays/dev

# Kubernetes deploy (prod)
kubectl apply -k k8s/overlays/prod
```

## Environment Variables
- `NODE_ENV` - Environment (development/production)
- `PORT` - Server port (default: 3000)
- `HOSTNAME` - Server hostname (default: 0.0.0.0)

## Data Structure

### Task Model
```typescript
interface Task {
  id: string
  title: string
  description: string
  category: TaskCategory
  frequency: TaskFrequency
  dueDate: Date
  lastCompleted?: Date
  completed: boolean
  priority: 'high' | 'medium' | 'low'
  estimatedDuration: number
  completionHistory: CompletionRecord[]
}
```

### Sample Data
- 10 realistic home maintenance tasks
- Complete with categories, frequencies, and history
- Covers electrical, plumbing, HVAC, cleaning, seasonal tasks

## Performance Considerations
- Lazy loading for large task lists
- Memoization for expensive calculations
- Optimized re-renders with React.memo
- Efficient filtering and sorting algorithms

## Future Enhancements
- Backend integration with API
- User authentication
- Task templates and recommendations
- Mobile app support
- Notifications and reminders
- Integration with home automation systems
