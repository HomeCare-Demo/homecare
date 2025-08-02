package v1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// PreviewEnvironmentSpec defines the desired state of PreviewEnvironment
type PreviewEnvironmentSpec struct {
	// RepoName is the name of the repository
	// +kubebuilder:validation:Required
	// +kubebuilder:validation:Pattern="^[a-zA-Z0-9-_./]+$"
	RepoName string `json:"repoName"`

	// PRNumber is the pull request number
	// +kubebuilder:validation:Required
	// +kubebuilder:validation:Minimum=1
	PRNumber int `json:"prNumber"`

	// Branch is the branch name for the PR
	// +kubebuilder:validation:Required
	// +kubebuilder:validation:Pattern="^[a-zA-Z0-9-_./]+$"
	Branch string `json:"branch"`

	// CommitSha is the commit SHA for the preview
	// +kubebuilder:validation:Required
	// +kubebuilder:validation:Pattern="^[a-f0-9]{7,40}$"
	CommitSha string `json:"commitSha"`

	// GitHubUsername is the username of the PR author
	// +kubebuilder:validation:Required
	// +kubebuilder:validation:Pattern="^[a-zA-Z0-9-]+$"
	GitHubUsername string `json:"githubUsername"`

	// ImageTag is the Docker image tag to deploy
	// +kubebuilder:validation:Required
	ImageTag string `json:"imageTag"`

	// TTL is the time-to-live for the preview environment in hours
	// +kubebuilder:validation:Optional
	// +kubebuilder:validation:Minimum=1
	// +kubebuilder:validation:Maximum=168
	// +kubebuilder:default=24
	TTL int `json:"ttl,omitempty"`
}

// PreviewEnvironmentStatus defines the observed state of PreviewEnvironment
type PreviewEnvironmentStatus struct {
	// Phase indicates the current phase of the PreviewEnvironment
	// +kubebuilder:validation:Enum=Pending;Creating;Ready;Failed;Terminating
	Phase string `json:"phase,omitempty"`

	// EnvironmentUrl is the URL where the preview environment can be accessed
	EnvironmentUrl string `json:"environmentUrl,omitempty"`

	// Namespace is the Kubernetes namespace created for this preview
	Namespace string `json:"namespace,omitempty"`

	// CreatedAt is the timestamp when the preview environment was created
	CreatedAt *metav1.Time `json:"createdAt,omitempty"`

	// ExpiresAt is the timestamp when the preview environment will expire
	ExpiresAt *metav1.Time `json:"expiresAt,omitempty"`

	// Conditions represent the latest available observations of the PreviewEnvironment's current state
	Conditions []metav1.Condition `json:"conditions,omitempty"`

	// Message provides additional information about the current state
	Message string `json:"message,omitempty"`
}

// +kubebuilder:object:root=true
// +kubebuilder:subresource:status
// +kubebuilder:resource:scope=Cluster
// +kubebuilder:printcolumn:name="Phase",type="string",JSONPath=".status.phase"
// +kubebuilder:printcolumn:name="Namespace",type="string",JSONPath=".status.namespace"
// +kubebuilder:printcolumn:name="URL",type="string",JSONPath=".status.environmentUrl"
// +kubebuilder:printcolumn:name="Age",type="date",JSONPath=".metadata.creationTimestamp"
// +kubebuilder:printcolumn:name="Expires",type="date",JSONPath=".status.expiresAt"

// PreviewEnvironment is the Schema for the previewenvironments API
type PreviewEnvironment struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   PreviewEnvironmentSpec   `json:"spec,omitempty"`
	Status PreviewEnvironmentStatus `json:"status,omitempty"`
}

// +kubebuilder:object:root=true

// PreviewEnvironmentList contains a list of PreviewEnvironment
type PreviewEnvironmentList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []PreviewEnvironment `json:"items"`
}

func init() {
	SchemeBuilder.Register(&PreviewEnvironment{}, &PreviewEnvironmentList{})
}