package controller

import (
	"context"
	"fmt"
	"strings"
	"time"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	networkingv1 "k8s.io/api/networking/v1"
	"k8s.io/apimachinery/pkg/api/errors"
	"k8s.io/apimachinery/pkg/api/resource"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/types"
	"k8s.io/apimachinery/pkg/util/intstr"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/controller/controllerutil"
	"sigs.k8s.io/controller-runtime/pkg/log"

	previewv1 "github.com/homecare-demo/homecare/operator/api/v1"
)

// PreviewEnvironmentReconciler reconciles a PreviewEnvironment object
type PreviewEnvironmentReconciler struct {
	client.Client
	Scheme *runtime.Scheme
}

// +kubebuilder:rbac:groups=preview.homecareapp.xyz,resources=previewenvironments,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=preview.homecareapp.xyz,resources=previewenvironments/status,verbs=get;update;patch
// +kubebuilder:rbac:groups=preview.homecareapp.xyz,resources=previewenvironments/finalizers,verbs=update
// +kubebuilder:rbac:groups="",resources=namespaces,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups="",resources=services,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=apps,resources=deployments,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=networking.k8s.io,resources=ingresses,verbs=get;list;watch;create;update;patch;delete

func (r *PreviewEnvironmentReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	logger := log.FromContext(ctx)

	// Fetch the PreviewEnvironment instance
	var preview previewv1.PreviewEnvironment
	if err := r.Get(ctx, req.NamespacedName, &preview); err != nil {
		if errors.IsNotFound(err) {
			// Request object not found, could have been deleted after reconcile request.
			logger.Info("PreviewEnvironment resource not found. Ignoring since object must be deleted")
			return ctrl.Result{}, nil
		}
		logger.Error(err, "Failed to get PreviewEnvironment")
		return ctrl.Result{}, err
	}

	// Set finalizer
	finalizerName := "preview.homecareapp.xyz/finalizer"
	if preview.ObjectMeta.DeletionTimestamp.IsZero() {
		if !controllerutil.ContainsFinalizer(&preview, finalizerName) {
			controllerutil.AddFinalizer(&preview, finalizerName)
			return ctrl.Result{}, r.Update(ctx, &preview)
		}
	} else {
		// The object is being deleted
		if controllerutil.ContainsFinalizer(&preview, finalizerName) {
			// Cleanup resources
			if err := r.cleanupResources(ctx, &preview); err != nil {
				logger.Error(err, "Failed to cleanup resources")
				return ctrl.Result{}, err
			}

			// Remove finalizer
			controllerutil.RemoveFinalizer(&preview, finalizerName)
			return ctrl.Result{}, r.Update(ctx, &preview)
		}
		return ctrl.Result{}, nil
	}

	// Generate namespace name
	namespaceName := r.generateNamespaceName(&preview)
	
	// Update status if necessary
	if preview.Status.Namespace == "" {
		preview.Status.Namespace = namespaceName
		preview.Status.Phase = "Creating"
		now := metav1.Now()
		preview.Status.CreatedAt = &now
		
		// Calculate expiration time
		if preview.Spec.TTL == 0 {
			preview.Spec.TTL = 24 // Default 24 hours
		}
		expiresAt := metav1.NewTime(now.Add(time.Duration(preview.Spec.TTL) * time.Hour))
		preview.Status.ExpiresAt = &expiresAt
		
		// Generate environment URL
		preview.Status.EnvironmentUrl = r.generateEnvironmentURL(&preview)
		
		if err := r.Status().Update(ctx, &preview); err != nil {
			logger.Error(err, "Failed to update PreviewEnvironment status")
			return ctrl.Result{}, err
		}
	}

	// Check if environment has expired
	if preview.Status.ExpiresAt != nil && time.Now().After(preview.Status.ExpiresAt.Time) {
		logger.Info("PreviewEnvironment has expired, deleting", "namespace", namespaceName)
		if err := r.Delete(ctx, &preview); err != nil {
			logger.Error(err, "Failed to delete expired PreviewEnvironment")
			return ctrl.Result{}, err
		}
		return ctrl.Result{}, nil
	}

	// Create or update namespace
	if err := r.reconcileNamespace(ctx, &preview, namespaceName); err != nil {
		logger.Error(err, "Failed to reconcile namespace")
		return ctrl.Result{}, err
	}

	// Create or update deployment
	if err := r.reconcileDeployment(ctx, &preview, namespaceName); err != nil {
		logger.Error(err, "Failed to reconcile deployment")
		return ctrl.Result{}, err
	}

	// Create or update service
	if err := r.reconcileService(ctx, &preview, namespaceName); err != nil {
		logger.Error(err, "Failed to reconcile service")
		return ctrl.Result{}, err
	}

	// Create or update ingress
	if err := r.reconcileIngress(ctx, &preview, namespaceName); err != nil {
		logger.Error(err, "Failed to reconcile ingress")
		return ctrl.Result{}, err
	}

	// Update status to Ready
	if preview.Status.Phase != "Ready" {
		preview.Status.Phase = "Ready"
		preview.Status.Message = "Preview environment is ready"
		if err := r.Status().Update(ctx, &preview); err != nil {
			logger.Error(err, "Failed to update PreviewEnvironment status to Ready")
			return ctrl.Result{}, err
		}
	}

	// Schedule next reconcile for TTL check
	return ctrl.Result{RequeueAfter: time.Hour}, nil
}

func (r *PreviewEnvironmentReconciler) generateNamespaceName(preview *previewv1.PreviewEnvironment) string {
	// Generate namespace name: preview<username>-pr<number>
	return fmt.Sprintf("preview%s-pr%d", 
		strings.ToLower(preview.Spec.GitHubUsername), 
		preview.Spec.PRNumber)
}

func (r *PreviewEnvironmentReconciler) generateEnvironmentURL(preview *previewv1.PreviewEnvironment) string {
	// Generate URL: <username><pr><commit>.dev.homecareapp.xyz
	shortCommit := preview.Spec.CommitSha
	if len(shortCommit) > 7 {
		shortCommit = shortCommit[:7]
	}
	return fmt.Sprintf("%s%d%s.dev.homecareapp.xyz", 
		strings.ToLower(preview.Spec.GitHubUsername),
		preview.Spec.PRNumber,
		shortCommit)
}

func (r *PreviewEnvironmentReconciler) reconcileNamespace(ctx context.Context, preview *previewv1.PreviewEnvironment, namespaceName string) error {
	namespace := &corev1.Namespace{
		ObjectMeta: metav1.ObjectMeta{
			Name: namespaceName,
			Labels: map[string]string{
				"app.kubernetes.io/name":       "homecare-preview",
				"app.kubernetes.io/instance":   preview.Name,
				"app.kubernetes.io/version":    "v1",
				"app.kubernetes.io/component":  "preview-environment",
				"app.kubernetes.io/part-of":    "homecare",
				"app.kubernetes.io/managed-by": "homecare-preview-operator",
				"preview.homecareapp.xyz/pr":   fmt.Sprintf("%d", preview.Spec.PRNumber),
				"preview.homecareapp.xyz/user": preview.Spec.GitHubUsername,
			},
		},
	}

	// Set owner reference
	if err := controllerutil.SetControllerReference(preview, namespace, r.Scheme); err != nil {
		return err
	}

	// Create or update namespace
	if err := r.Get(ctx, types.NamespacedName{Name: namespaceName}, &corev1.Namespace{}); err != nil {
		if errors.IsNotFound(err) {
			return r.Create(ctx, namespace)
		}
		return err
	}

	return nil
}

func (r *PreviewEnvironmentReconciler) reconcileDeployment(ctx context.Context, preview *previewv1.PreviewEnvironment, namespaceName string) error {
	labels := map[string]string{
		"app": "homecare-app",
		"preview.homecareapp.xyz/pr":   fmt.Sprintf("%d", preview.Spec.PRNumber),
		"preview.homecareapp.xyz/user": preview.Spec.GitHubUsername,
	}

	replicas := int32(1)
	deployment := &appsv1.Deployment{
		ObjectMeta: metav1.ObjectMeta{
			Name:      "homecare-app",
			Namespace: namespaceName,
			Labels:    labels,
		},
		Spec: appsv1.DeploymentSpec{
			Replicas: &replicas,
			Selector: &metav1.LabelSelector{
				MatchLabels: labels,
			},
			Template: corev1.PodTemplateSpec{
				ObjectMeta: metav1.ObjectMeta{
					Labels: labels,
				},
				Spec: corev1.PodSpec{
					Containers: []corev1.Container{
						{
							Name:  "homecare",
							Image: preview.Spec.ImageTag,
							Ports: []corev1.ContainerPort{
								{
									ContainerPort: 3000,
									Protocol:      corev1.ProtocolTCP,
								},
							},
							Resources: corev1.ResourceRequirements{
								Requests: corev1.ResourceList{
									corev1.ResourceCPU:    resource.MustParse("25m"),
									corev1.ResourceMemory: resource.MustParse("32Mi"),
								},
								Limits: corev1.ResourceList{
									corev1.ResourceCPU:    resource.MustParse("50m"),
									corev1.ResourceMemory: resource.MustParse("64Mi"),
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
	if err := controllerutil.SetControllerReference(preview, deployment, r.Scheme); err != nil {
		return err
	}

	// Create or update deployment
	existingDeployment := &appsv1.Deployment{}
	if err := r.Get(ctx, types.NamespacedName{Name: "homecare-app", Namespace: namespaceName}, existingDeployment); err != nil {
		if errors.IsNotFound(err) {
			return r.Create(ctx, deployment)
		}
		return err
	}

	// Update image if changed
	if existingDeployment.Spec.Template.Spec.Containers[0].Image != preview.Spec.ImageTag {
		existingDeployment.Spec.Template.Spec.Containers[0].Image = preview.Spec.ImageTag
		return r.Update(ctx, existingDeployment)
	}

	return nil
}

func (r *PreviewEnvironmentReconciler) reconcileService(ctx context.Context, preview *previewv1.PreviewEnvironment, namespaceName string) error {
	labels := map[string]string{
		"app": "homecare-app",
		"preview.homecareapp.xyz/pr":   fmt.Sprintf("%d", preview.Spec.PRNumber),
		"preview.homecareapp.xyz/user": preview.Spec.GitHubUsername,
	}

	service := &corev1.Service{
		ObjectMeta: metav1.ObjectMeta{
			Name:      "homecare-app",
			Namespace: namespaceName,
			Labels:    labels,
		},
		Spec: corev1.ServiceSpec{
			Selector: map[string]string{
				"app": "homecare-app",
			},
			Ports: []corev1.ServicePort{
				{
					Port:       80,
					TargetPort: intstr.FromInt(3000),
					Protocol:   corev1.ProtocolTCP,
				},
			},
			Type: corev1.ServiceTypeClusterIP,
		},
	}

	// Set owner reference
	if err := controllerutil.SetControllerReference(preview, service, r.Scheme); err != nil {
		return err
	}

	// Create service if it doesn't exist
	if err := r.Get(ctx, types.NamespacedName{Name: "homecare-app", Namespace: namespaceName}, &corev1.Service{}); err != nil {
		if errors.IsNotFound(err) {
			return r.Create(ctx, service)
		}
		return err
	}

	return nil
}

func (r *PreviewEnvironmentReconciler) reconcileIngress(ctx context.Context, preview *previewv1.PreviewEnvironment, namespaceName string) error {
	labels := map[string]string{
		"app": "homecare-app",
		"preview.homecareapp.xyz/pr":   fmt.Sprintf("%d", preview.Spec.PRNumber),
		"preview.homecareapp.xyz/user": preview.Spec.GitHubUsername,
	}

	pathType := networkingv1.PathTypePrefix
	ingress := &networkingv1.Ingress{
		ObjectMeta: metav1.ObjectMeta{
			Name:      "homecare-app",
			Namespace: namespaceName,
			Labels:    labels,
			Annotations: map[string]string{
				"kubernetes.io/ingress.class":                 "nginx",
				"nginx.ingress.kubernetes.io/rewrite-target":  "/",
				"nginx.ingress.kubernetes.io/ssl-redirect":    "false",
			},
		},
		Spec: networkingv1.IngressSpec{
			Rules: []networkingv1.IngressRule{
				{
					Host: r.generateEnvironmentURL(preview),
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
	if err := controllerutil.SetControllerReference(preview, ingress, r.Scheme); err != nil {
		return err
	}

	// Create ingress if it doesn't exist
	if err := r.Get(ctx, types.NamespacedName{Name: "homecare-app", Namespace: namespaceName}, &networkingv1.Ingress{}); err != nil {
		if errors.IsNotFound(err) {
			return r.Create(ctx, ingress)
		}
		return err
	}

	return nil
}

func (r *PreviewEnvironmentReconciler) cleanupResources(ctx context.Context, preview *previewv1.PreviewEnvironment) error {
	namespaceName := r.generateNamespaceName(preview)

	// Delete namespace (this will cascade delete all resources in the namespace)
	namespace := &corev1.Namespace{}
	if err := r.Get(ctx, types.NamespacedName{Name: namespaceName}, namespace); err != nil {
		if errors.IsNotFound(err) {
			// Already deleted
			return nil
		}
		return err
	}

	return r.Delete(ctx, namespace)
}

// SetupWithManager sets up the controller with the Manager.
func (r *PreviewEnvironmentReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&previewv1.PreviewEnvironment{}).
		Owns(&corev1.Namespace{}).
		Owns(&appsv1.Deployment{}).
		Owns(&corev1.Service{}).
		Owns(&networkingv1.Ingress{}).
		Complete(r)
}