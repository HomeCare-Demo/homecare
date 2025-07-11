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
- **Terraform** - Infrastructure as Code for Azure resources
- **Kustomize** - Kubernetes configuration management with overlays
- **NGINX Ingress** - Cost-optimized ingress controller with Basic Load Balancer
- **GitHub Actions** - CI/CD with OIDC authentication
- **Helm** - Package management for Kubernetes applications
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
│   ├── NGINX_INGRESS.md     # NGINX ingress controller setup
│   └── QUICK_SETUP.md       # Quick setup checklist
├── terraform/                # Infrastructure as Code
│   ├── providers.tf         # Terraform provider configurations
│   ├── resource-group.tf    # Azure Resource Group
│   ├── networking.tf        # VNet, subnets, and public IP
│   ├── kubernetes.tf        # AKS cluster configuration
│   ├── azure-ad.tf          # Azure AD app registration
│   ├── role-assignments.tf  # RBAC configurations
│   ├── federated-identity.tf # GitHub OIDC setup
│   ├── variables.tf         # Terraform variables
│   ├── outputs.tf           # Output values
│   └── README.md            # Terraform documentation
├── k8s/                      # Kubernetes configurations
│   ├── base/                # Base Kubernetes manifests
│   │   ├── deployment.yaml  # Application deployment
│   │   ├── service.yaml     # ClusterIP service
│   │   ├── ingress.yaml     # NGINX ingress configuration
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
│   ├── install-nginx-ingress.sh    # NGINX ingress installation
│   └── manage-nginx-ingress.sh     # NGINX management utilities
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
- **Terraform** - Infrastructure as Code for reproducible deployments
- **NGINX Ingress** - Cost-optimized ingress controller with Basic Load Balancer
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

### Infrastructure Setup
- **Terraform** - Complete Infrastructure as Code configuration
  - Azure Resource Group, VNet, AKS cluster
  - Azure AD app registration for GitHub OIDC
  - Federated identity credentials for secure CI/CD
- **Automated Scripts** - NGINX ingress installation and management
- **Idempotent Operations** - Scripts can be run multiple times safely

### Docker
- Multi-stage build for production
- Multi-platform support (linux/amd64, linux/arm64)
- Non-root user for security
- Health checks implemented
- Standalone Next.js output

### Kubernetes
- Kustomize for configuration management
- Separate dev/prod environments
- Resource limits optimized for single node
- NGINX ingress with cost-optimized Basic Load Balancer

### GitHub Actions CI/CD
- OIDC authentication with Azure (no secrets)
- Multi-platform Docker image building (AMD64/ARM64)
- Automated Docker image building and pushing
- Environment-specific deployments
- Manual and release-triggered workflows

### GitHub Actions OIDC Authentication
- **Federated Identity Credentials**: Must use specific subject claims, not wildcards
- **Subject Pattern for Environments**: `repo:owner/repo:environment:env_name` (e.g., `repo:mvkaran/homecare:environment:dev`)
- **Subject Pattern for Branches**: `repo:owner/repo:ref:refs/heads/branch_name`
- **Subject Pattern for Tags**: `repo:owner/repo:ref:refs/tags/tag_name`
- **Best Practice**: Create separate federated identity credentials for each environment (dev, prod) rather than using wildcards
- **Common Issue**: Using `repo:owner/repo:environment:*` wildcard may not work reliably; use specific environment names instead

### Commands
```bash
# Infrastructure setup with Terraform
cd terraform
terraform init
terraform plan
terraform apply

# NGINX Ingress installation
./scripts/install-nginx-ingress.sh

# NGINX Ingress management
./scripts/manage-nginx-ingress.sh

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

# Infrastructure cleanup
terraform destroy
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
- **VM Size**: Standard_D2plds_v5 (ARM64-based, cost-optimized)
- **Architecture**: ARM64 (linux/arm64)
- **Network**: Azure CNI Overlay mode
- **Free Tier**: Compatible with Azure free tier
- **Single Node**: 1 node pool for cost optimization

### DNS and Ingress
- **Production Domain**: homecareapp.xyz
- **Development Domain**: dev.homecareapp.xyz
- **Wildcard DNS**: *.homecareapp.xyz → Load Balancer IP
- **SSL**: Handled by ingress controller
- **Ingress Controller**: NGINX Ingress Controller with Basic Load Balancer

### Cost Optimization
- Single replica deployments for all environments
- Minimal resource requests and limits
- ARM64-based VM for better price/performance
- Free tier AKS control plane
- NGINX Ingress with Basic Load Balancer for cost-effective load balancing
- Multi-platform Docker images optimized for ARM64 and AMD64
- Estimated monthly cost: ~$15-25 for basic workloads

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
