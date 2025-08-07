/*
Copyright 2025.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package controller

import (
	"context"
	"fmt"
	"time"

	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/api/errors"
	"k8s.io/apimachinery/pkg/api/resource"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/util/intstr"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	networkingv1 "k8s.io/api/networking/v1"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/log"
	"sigs.k8s.io/controller-runtime/pkg/controller/controllerutil"

	previewv1 "github.com/homecare-demo/homecare/operator/api/v1"
)

const (
	PreviewEnvironmentFinalizer = "preview.homecareapp.xyz/finalizer"
)

// PreviewEnvironmentReconciler reconciles a PreviewEnvironment object
type PreviewEnvironmentReconciler struct {
	client.Client
	Scheme *runtime.Scheme
}

//+kubebuilder:rbac:groups=preview.homecareapp.xyz,resources=previewenvironments,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=preview.homecareapp.xyz,resources=previewenvironments/status,verbs=get;update;patch
//+kubebuilder:rbac:groups=preview.homecareapp.xyz,resources=previewenvironments/finalizers,verbs=update
//+kubebuilder:rbac:groups="",resources=namespaces,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=apps,resources=deployments,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups="",resources=services,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=networking.k8s.io,resources=ingresses,verbs=get;list;watch;create;update;patch;delete

// Reconcile is part of the main kubernetes reconciliation loop which aims to
// move the current state of the cluster closer to the desired state.
// The PreviewEnvironment controller reconciles preview environment resources by:
// 1. Creating dedicated namespaces
// 2. Deploying the application with proper resource management
// 3. Setting up ingress for external access
// 4. Managing TTL-based cleanup
func (r *PreviewEnvironmentReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	logger := log.FromContext(ctx)

	// Fetch the PreviewEnvironment instance
	previewEnv := &previewv1.PreviewEnvironment{}
	err := r.Get(ctx, req.NamespacedName, previewEnv)
	if err != nil {
		if errors.IsNotFound(err) {
			// Request object not found, could have been deleted after reconcile request.
			return ctrl.Result{}, nil
		}
		logger.Error(err, "Failed to get PreviewEnvironment")
		return ctrl.Result{}, err
	}

	// Check if the resource is being deleted
	if previewEnv.ObjectMeta.DeletionTimestamp.IsZero() {
		// The object is not being deleted, add finalizer if needed
		if !controllerutil.ContainsFinalizer(previewEnv, PreviewEnvironmentFinalizer) {
			controllerutil.AddFinalizer(previewEnv, PreviewEnvironmentFinalizer)
			return ctrl.Result{}, r.Update(ctx, previewEnv)
		}
	} else {
		// The object is being deleted
		if controllerutil.ContainsFinalizer(previewEnv, PreviewEnvironmentFinalizer) {
			// Perform cleanup
			if err := r.cleanupPreviewEnvironment(ctx, previewEnv); err != nil {
				logger.Error(err, "Failed to cleanup preview environment")
				return ctrl.Result{}, err
			}

			// Remove finalizer to allow deletion
			controllerutil.RemoveFinalizer(previewEnv, PreviewEnvironmentFinalizer)
			return ctrl.Result{}, r.Update(ctx, previewEnv)
		}
		return ctrl.Result{}, nil
	}

	// Check if environment has expired
	if previewEnv.IsExpired() {
		logger.Info("Preview environment has expired, marking for deletion", 
			"namespace", previewEnv.GetNamespace())
		
		// Update status to expiring
		previewEnv.Status.Phase = previewv1.PhaseExpiring
		previewEnv.Status.Message = "Environment has expired and is being cleaned up"
		if err := r.Status().Update(ctx, previewEnv); err != nil {
			logger.Error(err, "Failed to update status to expiring")
		}

		// Delete the resource (which will trigger cleanup via finalizer)
		return ctrl.Result{}, r.Delete(ctx, previewEnv)
	}

	// Initialize status if needed
	if previewEnv.Status.Phase == "" {
		previewEnv.Status.Phase = previewv1.PhaseCreating
		previewEnv.Status.Namespace = previewEnv.GenerateNamespace()
		previewEnv.Status.EnvironmentURL = previewEnv.GenerateEnvironmentURL()
		previewEnv.Status.CreatedAt = &metav1.Time{Time: time.Now()}
		previewEnv.SetExpirationTime()
		previewEnv.Status.Message = "Creating preview environment resources"
		
		if err := r.Status().Update(ctx, previewEnv); err != nil {
			logger.Error(err, "Failed to initialize status")
			return ctrl.Result{}, err
		}
	}

	// Reconcile the preview environment resources
	if err := r.reconcilePreviewEnvironment(ctx, previewEnv); err != nil {
		logger.Error(err, "Failed to reconcile preview environment")
		
		// Update status to failed
		previewEnv.Status.Phase = previewv1.PhaseFailed
		previewEnv.Status.Message = fmt.Sprintf("Failed to create resources: %v", err)
		if statusErr := r.Status().Update(ctx, previewEnv); statusErr != nil {
			logger.Error(statusErr, "Failed to update status to failed")
		}
		
		return ctrl.Result{RequeueAfter: time.Minute * 5}, err
	}

	// Update status to ready if all resources are created
	if previewEnv.Status.Phase == previewv1.PhaseCreating {
		previewEnv.Status.Phase = previewv1.PhaseReady
		previewEnv.Status.Message = "Preview environment is ready"
		if err := r.Status().Update(ctx, previewEnv); err != nil {
			logger.Error(err, "Failed to update status to ready")
		}
	}

	// Requeue to check for expiration
	return ctrl.Result{RequeueAfter: time.Hour}, nil
}

// SetupWithManager sets up the controller with the Manager.
func (r *PreviewEnvironmentReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&previewv1.PreviewEnvironment{}).
		Complete(r)
}

// reconcilePreviewEnvironment creates and manages all resources for the preview environment
func (r *PreviewEnvironmentReconciler) reconcilePreviewEnvironment(ctx context.Context, previewEnv *previewv1.PreviewEnvironment) error {
	logger := log.FromContext(ctx)
	
	// Create namespace
	if err := r.reconcileNamespace(ctx, previewEnv); err != nil {
		logger.Error(err, "Failed to reconcile namespace")
		return err
	}

	// Create deployment
	if err := r.reconcileDeployment(ctx, previewEnv); err != nil {
		logger.Error(err, "Failed to reconcile deployment")
		return err
	}

	// Create service
	if err := r.reconcileService(ctx, previewEnv); err != nil {
		logger.Error(err, "Failed to reconcile service")
		return err
	}

	// Create ingress
	if err := r.reconcileIngress(ctx, previewEnv); err != nil {
		logger.Error(err, "Failed to reconcile ingress")
		return err
	}

	return nil
}

// reconcileNamespace creates the dedicated namespace for the preview environment
func (r *PreviewEnvironmentReconciler) reconcileNamespace(ctx context.Context, previewEnv *previewv1.PreviewEnvironment) error {
	namespace := &corev1.Namespace{
		ObjectMeta: metav1.ObjectMeta{
			Name: previewEnv.GetNamespace(),
			Labels: map[string]string{
				"app.kubernetes.io/name":       "homecare-preview",
				"app.kubernetes.io/instance":   fmt.Sprintf("pr-%d", previewEnv.Spec.PRNumber),
				"app.kubernetes.io/managed-by": "preview-operator",
				"preview.homecareapp.xyz/repo": previewEnv.Spec.RepoName,
				"preview.homecareapp.xyz/pr":   fmt.Sprintf("%d", previewEnv.Spec.PRNumber),
				"preview.homecareapp.xyz/user": previewEnv.Spec.GitHubUsername,
			},
		},
	}

	// Set owner reference
	if err := controllerutil.SetControllerReference(previewEnv, namespace, r.Scheme); err != nil {
		return err
	}

	// Create or update namespace
	existingNS := &corev1.Namespace{}
	err := r.Get(ctx, client.ObjectKey{Name: namespace.Name}, existingNS)
	if err != nil {
		if errors.IsNotFound(err) {
			return r.Create(ctx, namespace)
		}
		return err
	}

	// Update existing namespace if needed
	existingNS.Labels = namespace.Labels
	return r.Update(ctx, existingNS)
}

// reconcileDeployment creates the application deployment
func (r *PreviewEnvironmentReconciler) reconcileDeployment(ctx context.Context, previewEnv *previewv1.PreviewEnvironment) error {
	replicas := int32(1)
	
	deployment := &appsv1.Deployment{
		ObjectMeta: metav1.ObjectMeta{
			Name:      "homecare-app",
			Namespace: previewEnv.GetNamespace(),
			Labels: map[string]string{
				"app": "homecare-app",
				"preview.homecareapp.xyz/repo": previewEnv.Spec.RepoName,
				"preview.homecareapp.xyz/pr":   fmt.Sprintf("%d", previewEnv.Spec.PRNumber),
			},
		},
		Spec: appsv1.DeploymentSpec{
			Replicas: &replicas,
			Selector: &metav1.LabelSelector{
				MatchLabels: map[string]string{
					"app": "homecare-app",
				},
			},
			Template: corev1.PodTemplateSpec{
				ObjectMeta: metav1.ObjectMeta{
					Labels: map[string]string{
						"app": "homecare-app",
						"preview.homecareapp.xyz/repo": previewEnv.Spec.RepoName,
						"preview.homecareapp.xyz/pr":   fmt.Sprintf("%d", previewEnv.Spec.PRNumber),
					},
				},
				Spec: corev1.PodSpec{
					Containers: []corev1.Container{
						{
							Name:  "homecare-app",
							Image: previewEnv.Spec.ImageTag,
							Ports: []corev1.ContainerPort{
								{
									ContainerPort: 3000,
									Protocol:      corev1.ProtocolTCP,
								},
							},
							Resources: corev1.ResourceRequirements{
								Requests: corev1.ResourceList{
									corev1.ResourceMemory: resource.MustParse("32Mi"),
									corev1.ResourceCPU:    resource.MustParse("50m"),
								},
								Limits: corev1.ResourceList{
									corev1.ResourceMemory: resource.MustParse("64Mi"),
									corev1.ResourceCPU:    resource.MustParse("100m"),
								},
							},
							LivenessProbe: &corev1.Probe{
								ProbeHandler: corev1.ProbeHandler{
									HTTPGet: &corev1.HTTPGetAction{
										Path: "/",
										Port: intstr.FromInt(3000),
									},
								},
								InitialDelaySeconds: 30,
								PeriodSeconds:       10,
							},
							ReadinessProbe: &corev1.Probe{
								ProbeHandler: corev1.ProbeHandler{
									HTTPGet: &corev1.HTTPGetAction{
										Path: "/",
										Port: intstr.FromInt(3000),
									},
								},
								InitialDelaySeconds: 5,
								PeriodSeconds:       5,
							},
						},
					},
				},
			},
		},
	}

	// Set owner reference
	if err := controllerutil.SetControllerReference(previewEnv, deployment, r.Scheme); err != nil {
		return err
	}

	// Create or update deployment
	existingDeployment := &appsv1.Deployment{}
	err := r.Get(ctx, client.ObjectKey{Name: deployment.Name, Namespace: deployment.Namespace}, existingDeployment)
	if err != nil {
		if errors.IsNotFound(err) {
			return r.Create(ctx, deployment)
		}
		return err
	}

	// Update existing deployment if image has changed
	if existingDeployment.Spec.Template.Spec.Containers[0].Image != previewEnv.Spec.ImageTag {
		existingDeployment.Spec.Template.Spec.Containers[0].Image = previewEnv.Spec.ImageTag
		return r.Update(ctx, existingDeployment)
	}

	return nil
}

// reconcileService creates the service for the application
func (r *PreviewEnvironmentReconciler) reconcileService(ctx context.Context, previewEnv *previewv1.PreviewEnvironment) error {
	service := &corev1.Service{
		ObjectMeta: metav1.ObjectMeta{
			Name:      "homecare-app",
			Namespace: previewEnv.GetNamespace(),
			Labels: map[string]string{
				"app": "homecare-app",
				"preview.homecareapp.xyz/repo": previewEnv.Spec.RepoName,
				"preview.homecareapp.xyz/pr":   fmt.Sprintf("%d", previewEnv.Spec.PRNumber),
			},
		},
		Spec: corev1.ServiceSpec{
			Selector: map[string]string{
				"app": "homecare-app",
			},
			Ports: []corev1.ServicePort{
				{
					Name:       "http",
					Port:       80,
					TargetPort: intstr.FromInt(3000),
					Protocol:   corev1.ProtocolTCP,
				},
			},
			Type: corev1.ServiceTypeClusterIP,
		},
	}

	// Set owner reference
	if err := controllerutil.SetControllerReference(previewEnv, service, r.Scheme); err != nil {
		return err
	}

	// Create or get existing service
	existingService := &corev1.Service{}
	err := r.Get(ctx, client.ObjectKey{Name: service.Name, Namespace: service.Namespace}, existingService)
	if err != nil {
		if errors.IsNotFound(err) {
			return r.Create(ctx, service)
		}
		return err
	}

	return nil
}

// reconcileIngress creates the ingress for external access
func (r *PreviewEnvironmentReconciler) reconcileIngress(ctx context.Context, previewEnv *previewv1.PreviewEnvironment) error {
	pathType := networkingv1.PathTypePrefix
	ingressClassName := "nginx"
	
	// Generate hostname
	shortSha := previewEnv.Spec.CommitSha
	if len(shortSha) > 7 {
		shortSha = shortSha[:7]
	}
	hostname := fmt.Sprintf("%s%d%s.dev.homecareapp.xyz", 
		previewEnv.Spec.GitHubUsername, previewEnv.Spec.PRNumber, shortSha)

	ingress := &networkingv1.Ingress{
		ObjectMeta: metav1.ObjectMeta{
			Name:      "homecare-app",
			Namespace: previewEnv.GetNamespace(),
			Labels: map[string]string{
				"app": "homecare-app",
				"preview.homecareapp.xyz/repo": previewEnv.Spec.RepoName,
				"preview.homecareapp.xyz/pr":   fmt.Sprintf("%d", previewEnv.Spec.PRNumber),
			},
			Annotations: map[string]string{
				"nginx.ingress.kubernetes.io/rewrite-target": "/",
			},
		},
		Spec: networkingv1.IngressSpec{
			IngressClassName: &ingressClassName,
			Rules: []networkingv1.IngressRule{
				{
					Host: hostname,
					IngressRuleValue: networkingv1.IngressRuleValue{
						HTTP: &networkingv1.HTTPIngressRuleValue{
							Paths: []networkingv1.HTTPIngressPath{
								{
									Path:     "/",
									PathType: &pathType,
									Backend: networkingv1.IngressBackend{
										Service: &networkingv1.IngressServiceBackend{
											Name: "homecare-app",
											Port: networkingv1.ServiceBackendPort{
												Number: 80,
											},
										},
									},
								},
							},
						},
					},
				},
			},
		},
	}

	// Set owner reference
	if err := controllerutil.SetControllerReference(previewEnv, ingress, r.Scheme); err != nil {
		return err
	}

	// Create or get existing ingress
	existingIngress := &networkingv1.Ingress{}
	err := r.Get(ctx, client.ObjectKey{Name: ingress.Name, Namespace: ingress.Namespace}, existingIngress)
	if err != nil {
		if errors.IsNotFound(err) {
			return r.Create(ctx, ingress)
		}
		return err
	}

	return nil
}

// cleanupPreviewEnvironment handles cleanup when the PreviewEnvironment is deleted
func (r *PreviewEnvironmentReconciler) cleanupPreviewEnvironment(ctx context.Context, previewEnv *previewv1.PreviewEnvironment) error {
	logger := log.FromContext(ctx)
	
	// Since we use owner references, deleting the namespace will cascade delete all resources
	namespace := &corev1.Namespace{}
	err := r.Get(ctx, client.ObjectKey{Name: previewEnv.GetNamespace()}, namespace)
	if err != nil {
		if errors.IsNotFound(err) {
			// Namespace already deleted
			return nil
		}
		return err
	}

	logger.Info("Deleting preview environment namespace", "namespace", previewEnv.GetNamespace())
	return r.Delete(ctx, namespace)
}
