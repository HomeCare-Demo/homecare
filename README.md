# HomeCare - Home Maintenance Tracker

A comprehensive Next.js application designed to help users manage and track their home maintenance tasks with a beautiful, modern interface.

![HomeCare Dashboard](https://via.placeholder.com/800x400/667eea/ffffff?text=HomeCare+Dashboard)

## ✨ Features

- **Task Management**: Add, edit, delete, and complete maintenance tasks
- **Smart Categorization**: Organize tasks by category (electrical, plumbing, HVAC, etc.)
- **Flexible Scheduling**: Set frequency (weekly, monthly, quarterly, yearly)
- **Multiple Views**: Dashboard, list view, calendar view, and analytics
- **Progress Tracking**: Monitor completion history and performance metrics
- **Beautiful UI**: Modern design with gradients, smooth animations, and responsive layout

## 🚀 Quick Start

### Prerequisites

- Node.js 18+ 
- npm or yarn

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd homecare
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Start development server**
   ```bash
   npm run dev
   ```

4. **Open your browser**
   Navigate to [http://localhost:3000](http://localhost:3000)

## 🏗️ Tech Stack

- **Framework**: Next.js 15 with App Router
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **UI Components**: ShadCN UI (Radix UI)
- **Icons**: Lucide React
- **Date Handling**: date-fns

## 📱 Application Views

### Dashboard
- Overview of all tasks with priority highlighting
- Quick stats and recent activity
- Mini calendar with task indicators
- High-priority and overdue task alerts

### Task Management
- Complete task list with filtering and sorting
- Search functionality across titles and descriptions
- Grid and list view modes
- Category-based organization

### Calendar View
- Visual task scheduling in calendar format
- Monthly navigation
- Task density indicators
- Color-coded by status and priority

### Analytics
- Performance metrics and completion rates
- Category-wise analysis
- Priority distribution charts
- Recent completion history

## 🎨 Design System

The application features a cohesive design system with:
- **Color Palette**: Soft blues, warm neutrals, with gradient accents
- **Typography**: Clean, readable fonts with proper hierarchy
- **Animations**: Smooth transitions and micro-interactions
- **Components**: Consistent ShadCN UI components throughout

## 🐳 Docker Support

The application includes multi-platform Docker support for both AMD64 and ARM64 architectures, making it compatible with various deployment environments including ARM-based cloud instances.

### Build and Run with Docker

```bash
# Build the image
docker build -t homecare-app .

# Run the container
docker run -p 3000:3000 homecare-app
```

### Multi-Platform Build

```bash
# Build for multiple platforms (requires Docker Buildx)
docker buildx build --platform linux/amd64,linux/arm64 -t homecare-app .
```

### Docker Compose

```bash
# Production
docker-compose up

# Development
docker-compose --profile dev up
```

## ☸️ Infrastructure & Deployment

The application includes complete Infrastructure as Code (IaC) with Terraform and production-ready Kubernetes configurations for Azure deployment:

### Infrastructure Setup with Terraform
```bash
# Initialize and deploy infrastructure
cd terraform
terraform init
terraform plan
terraform apply
```

### Ingress Controller
- **NGINX Ingress**: Cost-optimized with Basic Load Balancer (~$15-25/month)

### Quick Deployment
```bash
# Install NGINX Ingress Controller
./scripts/install-nginx-ingress.sh

# Deploy to development
kubectl apply -k k8s/overlays/dev

# Deploy to production
kubectl apply -k k8s/overlays/prod
```

### Automated Deployment with GitHub Actions
This project includes a complete CI/CD pipeline using GitHub Actions with OIDC authentication for secure deployments to AKS.

### 🔄 Preview Environments
Automatic preview environments for pull requests with isolated testing and review:

- **Auto-deployment**: Every PR gets its own preview environment
- **Unique URLs**: `https://<username><pr><commit>.dev.homecareapp.xyz`
- **Kubernetes Operator**: Go-based operator for complete lifecycle management
- **Resource Isolation**: Dedicated namespaces with owner-reference cleanup
- **TTL Management**: Automatic expiration and cleanup
- **Cost Optimized**: Minimal resource usage with ARM64 compatibility

**📖 Preview Documentation:**
- [PreviewEnvironment Setup Guide](docs/PREVIEW_ENVIRONMENTS_SETUP.md) - Quick setup instructions
- [Complete PreviewEnvironment Documentation](docs/PREVIEW_ENVIRONMENTS.md) - Detailed feature guide

**📖 Infrastructure Documentation:**
- [Complete AKS Deployment Guide](docs/AKS_DEPLOYMENT.md) - Detailed setup instructions
- [NGINX Ingress Setup](docs/NGINX_INGRESS.md) - Cost-optimized ingress configuration
- [Quick Setup Checklist](docs/QUICK_SETUP.md) - Manual inputs and configuration
- [Terraform Documentation](terraform/README.md) - Infrastructure as Code details

**🚀 Features:**
- Complete Terraform Infrastructure as Code
- OIDC authentication with Azure (no secrets required)
- Multi-platform Docker image builds (AMD64/ARM64) with GitHub Container Registry
- Environment-specific deployments (dev/prod)
- **Preview Environments**: Automatic PR-based preview deployments with Kubernetes operator
- Cost-optimized ARM64-based AKS cluster for Azure free tier
- NGINX Ingress with Basic Load Balancer for cost savings
- Manual and automatic deployment triggers

## 📊 Sample Data

The application comes with 10 realistic home maintenance tasks including:
- Replace Water Filter (Quarterly)
- Check Inverter Battery (Monthly)
- HVAC System Maintenance (Quarterly)
- Clean Dishwasher Filter (Monthly)
- Test Smoke Detectors (Monthly)
- And more...

## 🛠️ Development

### Project Structure

```
src/
├── app/                 # Next.js App Router
├── components/          # React components
│   ├── ui/             # ShadCN UI components
│   └── *.tsx           # Feature components
├── contexts/           # React contexts
├── data/              # Sample data
├── lib/               # Utilities
└── types/             # TypeScript types
```

### Available Scripts

```bash
npm run dev          # Start development server
npm run build        # Build for production
npm run start        # Start production server
npm run lint         # Run ESLint
```

### Adding New Tasks

Tasks are managed through the `TaskContext` and include:
- Title and description
- Category (electrical, plumbing, HVAC, etc.)
- Frequency (weekly, monthly, quarterly, etc.)
- Due dates and priorities
- Estimated duration
- Completion history with ratings

## 🚀 Deployment

### Vercel (Recommended)

1. Connect your repository to Vercel
2. Deploy automatically on push to main

### Self-Hosted

1. Build the application: `npm run build`
2. Start the production server: `npm start`

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Next.js](https://nextjs.org/) for the amazing React framework
- [Tailwind CSS](https://tailwindcss.com/) for utility-first styling
- [Radix UI](https://radix-ui.com/) for accessible components
- [Lucide](https://lucide.dev/) for beautiful icons

---

Built with ❤️ for better home maintenance management
