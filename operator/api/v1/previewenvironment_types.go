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

package v1

import (
	"fmt"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"time"
)

// EDIT THIS FILE!  THIS IS SCAFFOLDING FOR YOU TO OWN!
// NOTE: json tags are required.  Any new fields you add must have json tags for the fields to be serialized.

// PreviewEnvironmentSpec defines the desired state of PreviewEnvironment
type PreviewEnvironmentSpec struct {
	// RepoName is the name of the GitHub repository
	// +kubebuilder:validation:Required
	// +kubebuilder:validation:Pattern="^[a-z0-9-]+$"
	RepoName string `json:"repoName"`

	// PRNumber is the pull request number
	// +kubebuilder:validation:Required
	// +kubebuilder:validation:Minimum=1
	PRNumber int `json:"prNumber"`

	// Branch is the source branch name
	// +kubebuilder:validation:Required
	Branch string `json:"branch"`

	// CommitSha is the commit SHA to deploy
	// +kubebuilder:validation:Required
	// +kubebuilder:validation:Pattern="^[a-f0-9]{7,40}$"
	CommitSha string `json:"commitSha"`

	// GitHubUsername is the GitHub username who created the PR
	// +kubebuilder:validation:Required
	// +kubebuilder:validation:Pattern="^[a-z0-9]([a-z0-9-]*[a-z0-9])?$"
	GitHubUsername string `json:"githubUsername"`

	// ImageTag is the Docker image tag to deploy
	// +kubebuilder:validation:Required
	ImageTag string `json:"imageTag"`

	// TTL defines how long the environment should exist (in hours)
	// +kubebuilder:validation:Minimum=1
	// +kubebuilder:validation:Maximum=168
	// +kubebuilder:default=24
	TTL int `json:"ttl,omitempty"`
}

// PreviewEnvironmentPhase represents the current phase of the preview environment
type PreviewEnvironmentPhase string

const (
	// PhaseCreating indicates resources are being created
	PhaseCreating PreviewEnvironmentPhase = "Creating"
	// PhaseReady indicates the environment is ready for use
	PhaseReady PreviewEnvironmentPhase = "Ready"
	// PhaseExpiring indicates the environment is being cleaned up due to TTL
	PhaseExpiring PreviewEnvironmentPhase = "Expiring"
	// PhaseFailed indicates an error occurred
	PhaseFailed PreviewEnvironmentPhase = "Failed"
)

// PreviewEnvironmentStatus defines the observed state of PreviewEnvironment
type PreviewEnvironmentStatus struct {
	// Phase represents the current phase of the preview environment
	// +kubebuilder:validation:Enum=Creating;Ready;Expiring;Failed
	Phase PreviewEnvironmentPhase `json:"phase,omitempty"`

	// EnvironmentURL is the URL where the preview environment can be accessed
	EnvironmentURL string `json:"environmentUrl,omitempty"`

	// Namespace is the Kubernetes namespace containing the preview environment
	Namespace string `json:"namespace,omitempty"`

	// CreatedAt is when the environment was created
	CreatedAt *metav1.Time `json:"createdAt,omitempty"`

	// ExpiresAt is when the environment will be automatically cleaned up
	ExpiresAt *metav1.Time `json:"expiresAt,omitempty"`

	// Message provides additional information about the current status
	Message string `json:"message,omitempty"`

	// Conditions represent the latest available observations of the preview environment
	Conditions []metav1.Condition `json:"conditions,omitempty"`
}

//+kubebuilder:object:root=true
//+kubebuilder:subresource:status
//+kubebuilder:resource:scope=Cluster
//+kubebuilder:printcolumn:name="Phase",type=string,JSONPath=`.status.phase`
//+kubebuilder:printcolumn:name="URL",type=string,JSONPath=`.status.environmentUrl`
//+kubebuilder:printcolumn:name="Namespace",type=string,JSONPath=`.status.namespace`
//+kubebuilder:printcolumn:name="Age",type=date,JSONPath=`.metadata.creationTimestamp`
//+kubebuilder:printcolumn:name="Expires",type=date,JSONPath=`.status.expiresAt`

// PreviewEnvironment is the Schema for the previewenvironments API
type PreviewEnvironment struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   PreviewEnvironmentSpec   `json:"spec,omitempty"`
	Status PreviewEnvironmentStatus `json:"status,omitempty"`
}

//+kubebuilder:object:root=true

// PreviewEnvironmentList contains a list of PreviewEnvironment
type PreviewEnvironmentList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []PreviewEnvironment `json:"items"`
}

func init() {
	SchemeBuilder.Register(&PreviewEnvironment{}, &PreviewEnvironmentList{})
}

// GetNamespace returns the namespace name for this preview environment
func (pe *PreviewEnvironment) GetNamespace() string {
	if pe.Status.Namespace != "" {
		return pe.Status.Namespace
	}
	return pe.GenerateNamespace()
}

// GenerateNamespace generates the namespace name for this preview environment
func (pe *PreviewEnvironment) GenerateNamespace() string {
	return fmt.Sprintf("preview%s-pr%d", pe.Spec.GitHubUsername, pe.Spec.PRNumber)
}

// GenerateEnvironmentURL generates the preview URL for this environment
func (pe *PreviewEnvironment) GenerateEnvironmentURL() string {
	shortSha := pe.Spec.CommitSha
	if len(shortSha) > 7 {
		shortSha = shortSha[:7]
	}
	return fmt.Sprintf("https://%s%d%s.dev.homecareapp.xyz",
		pe.Spec.GitHubUsername, pe.Spec.PRNumber, shortSha)
}

// IsExpired checks if the preview environment has exceeded its TTL
func (pe *PreviewEnvironment) IsExpired() bool {
	if pe.Status.ExpiresAt == nil {
		return false
	}
	return time.Now().After(pe.Status.ExpiresAt.Time)
}

// SetExpirationTime calculates and sets the expiration time based on TTL
func (pe *PreviewEnvironment) SetExpirationTime() {
	ttl := pe.Spec.TTL
	if ttl == 0 {
		ttl = 24 // default 24 hours
	}
	expiresAt := metav1.NewTime(time.Now().Add(time.Duration(ttl) * time.Hour))
	pe.Status.ExpiresAt = &expiresAt
}
