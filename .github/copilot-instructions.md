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
- **Kubernetes** - Container orchestration on Azure AKS
- **Kustomize** - Kubernetes configuration management with overlays
- **Azure Application Gateway** - Ingress controller (AGIC)
- **GitHub Actions** - CI/CD with OIDC authentication
- **Docker Compose** - Local development environment

## Architecture

### Project Structure
```
/
├── .github/                   # GitHub workflows and settings
│   └── workflows/
│       └── deploy.yml        # Automated deployment to AKS
├── docs/                     # Documentation
│   ├── AKS_DEPLOYMENT.md    # Azure AKS deployment guide
│   ├── NGINX_INGRESS.md     # Alternative ingress configuration
│   └── QUICK_SETUP.md       # Quick setup checklist
├── k8s/                      # Kubernetes configurations
│   ├── base/                # Base Kubernetes manifests
│   │   ├── deployment.yaml  # Application deployment
│   │   ├── service.yaml     # ClusterIP service
│   │   ├── ingress.yaml     # AGIC ingress configuration
│   │   └── kustomization.yaml
│   └── overlays/            # Environment-specific overlays
│       ├── dev/             # Development environment
│       │   ├── ingress-patch.yaml    # dev.homecareapp.xyz
│       │   ├── resources-patch.yaml  # Minimal resources
│       │   └── kustomization.yaml
│       └── prod/            # Production environment
│           ├── ingress-patch.yaml    # homecareapp.xyz
│           ├── resources-patch.yaml  # Production resources
│           └── kustomization.yaml
├── scripts/                  # Automation scripts
│   ├── setup-aks.sh        # Complete Azure/AKS setup
│   └── cleanup-aks.sh      # Resource cleanup
├── src/                     # Application source code
│   ├── app/                 # Next.js App Router
│   │   ├── globals.css     # Global styles with design system
│   │   ├── layout.tsx      # Root layout with providers
│   │   └── page.tsx        # Main application page
│   ├── components/          # React components
│   │   ├── ui/             # ShadCN UI components
│   │   ├── Dashboard.tsx   # Main dashboard view
│   │   ├── TaskCard.tsx    # Individual task display
│   │   ├── TaskFormDialog.tsx # Task creation/editing
│   │   ├── TaskFilters.tsx # Filtering and search
│   │   ├── TasksView.tsx   # All tasks view
│   │   ├── CalendarView.tsx # Calendar components
│   │   ├── TaskHistory.tsx # Task completion history
│   │   ├── AnalyticsView.tsx # Analytics and reporting
│   │   └── Navigation.tsx  # Sidebar navigation
│   ├── contexts/           # React contexts
│   │   └── TaskContext.tsx # Task state management
│   ├── data/               # Sample data
│   │   └── sampleTasks.ts  # Mock task data
│   ├── lib/                # Utility functions
│   │   └── utils.ts        # Common utilities
│   └── types/              # TypeScript type definitions
│       └── task.ts         # Task-related types
├── public/                  # Static assets
├── docker-compose.yml       # Local development setup
├── Dockerfile              # Production container build
├── Dockerfile.dev          # Development container build
└── package.json            # Dependencies and scripts
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

### Infrastructure & Deployment
- **Azure AKS** - Managed Kubernetes cluster (free tier compatible)
- **Application Gateway** - Azure native ingress with AGIC
- **Single Node Setup** - Cost-optimized for development/small workloads
- **Resource Optimization** - Minimal CPU/memory requests for efficiency
- **Domain Configuration** - Pre-configured for homecareapp.xyz

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

### Automated Setup
- **Setup Script**: `scripts/setup-aks.sh` - Complete Azure infrastructure setup
- **Cleanup Script**: `scripts/cleanup-aks.sh` - Safe resource removal
- **Idempotent Operations**: Scripts can be run multiple times safely

### Docker
- Multi-stage build for production
- Non-root user for security
- Health checks implemented
- Standalone Next.js output

### Kubernetes
- Kustomize for configuration management
- Separate dev/prod environments
- Resource limits optimized for single node
- AGIC ingress with homecareapp.xyz domain

### GitHub Actions CI/CD
- OIDC authentication with Azure (no secrets)
- Automated Docker image building and pushing
- Environment-specific deployments
- Manual and release-triggered workflows

### Commands
```bash
# Automated setup (recommended)
chmod +x scripts/setup-aks.sh
./scripts/setup-aks.sh

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

# Cleanup resources
chmod +x scripts/cleanup-aks.sh
./scripts/cleanup-aks.sh
```

## Environment Variables

### Application
- `NODE_ENV` - Environment (development/production)
- `PORT` - Server port (default: 3000)
- `HOSTNAME` - Server hostname (default: 0.0.0.0)

### GitHub Actions Secrets
- `AZURE_CLIENT_ID` - Azure AD app registration ID
- `AZURE_TENANT_ID` - Azure tenant ID
- `AZURE_SUBSCRIPTION_ID` - Azure subscription ID
- `AZURE_RESOURCE_GROUP` - Azure resource group name
- `AZURE_CLUSTER_NAME` - AKS cluster name

### Kubernetes Resource Configurations
- **Base Environment**: 1 replica, 64Mi memory request, 128Mi limit
- **Dev Environment**: 1 replica, 32Mi memory request, 64Mi limit
- **Prod Environment**: 1 replica, 64Mi memory request, 128Mi limit

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

## Infrastructure Details

### Azure AKS Configuration
- **VM Size**: Standard_D2plds_v5 (ARM-based, cost-optimized)
- **Network**: Azure CNI Overlay mode
- **Free Tier**: Compatible with Azure free tier
- **Single Node**: 1 node pool for cost optimization
- **AGIC**: Application Gateway Ingress Controller for native Azure integration

### DNS and Ingress
- **Production Domain**: homecareapp.xyz
- **Development Domain**: dev.homecareapp.xyz
- **Wildcard DNS**: *.homecareapp.xyz → Application Gateway IP
- **SSL**: Handled by Application Gateway
- **Ingress Class**: azure/application-gateway

### Cost Optimization
- Single replica deployments for all environments
- Minimal resource requests and limits
- ARM-based VM for better price/performance
- Free tier AKS control plane
- Estimated monthly cost: ~$85-120

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
