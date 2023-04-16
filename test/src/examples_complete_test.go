package test

import (
	"fmt"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	testStructure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"path"
	"regexp"
	"strings"
	"testing"
	"time"
)

const WorkspaceKeyPrefix = "workspace"
const Workspace = "eg-test"

// Test the Terraform module in examples/complete using Terratest.
func TestExamplesComplete(t *testing.T) {
	t.Parallel()
	randID := strings.ToLower(random.UniqueId())
	attributes := []string{randID}

	rootFolder := "../../"
	terraformFolderRelativeToRoot := "examples/complete"
	varFiles := []string{"fixtures.us-east-2.tfvars"}

	tempTestFolder := testStructure.CopyTerraformFolderToTemp(t, rootFolder, terraformFolderRelativeToRoot)

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: tempTestFolder,
		Upgrade:      true,
		// Variables to pass to our Terraform code using -var-file options
		VarFiles: varFiles,
		Vars: map[string]interface{}{
			"attributes": attributes,
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer cleanup(t, terraformOptions, tempTestFolder)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	if _, err := terraform.InitAndApplyE(t, terraformOptions); err != nil {
		require.FailNow(t, "Terraform \"apply\" failed, skipping the rest of the tests")
	}

	t.Log("Waiting 15 seconds for S3 to set up replication")
	time.Sleep(15 * time.Second)

	// Deploy a null resource (an output) in the blue region.
	// Verify that the resource is in the Terraform state in the blue S3 bucket
	// and that the state object is replicated.
	blueBackendMap := terraform.OutputMap(t, terraformOptions, "blue_backend_config")
	blueRegion := blueBackendMap["region"]
	s3BucketNames := terraform.OutputMap(t, terraformOptions, "s3_bucket_ids")
	blueBucket := s3BucketNames[blueRegion]
	require.NotEmpty(t, blueBucket, "Could not find bucket name for blue region")
	greenBackendMap := terraform.OutputMap(t, terraformOptions, "green_backend_config")
	greenRegion := greenBackendMap["region"]

	blueConfig := BackendTestConfig{
		region:        blueBackendMap["region"],
		bucketName:    s3BucketNames[blueRegion],
		backendConfig: mapToConfig(blueBackendMap),
		// For multi-region, the keys are prefixed with what is configured as the bucket name
		tfStateKey: fmt.Sprintf("%s/%s", blueBackendMap["bucket"], blueBackendMap["key"]),
		testData:   fmt.Sprintf("data-for-blue-test-%s", randID),
		testFolder: path.Join(tempTestFolder, "backend-test"),
		workspace:  "",
	}
	blueWorkspaceBackendConfig := mapToConfig(blueBackendMap)
	blueWorkspaceBackendConfig["workspace_key_prefix"] = WorkspaceKeyPrefix

	//blueWorkspaceConfig := BackendTestConfig{
	//	region:        blueConfig.region,
	//	bucketName:    blueConfig.bucketName,
	//	backendConfig: blueWorkspaceBackendConfig,
	//	tfStateKey:    fmt.Sprintf("%s/%s/%s/%s", blueBackendMap["bucket"], WorkspaceKeyPrefix, Workspace, blueBackendMap["key"]),
	//	testData:      fmt.Sprintf("data-for-blue-workspace-test-%s", randID),
	//	testFolder:    path.Join(tempTestFolder, "backend-workspace-test"),
	//	workspace:     Workspace,
	//}

	greenConfig := BackendTestConfig{
		region:        greenBackendMap["region"],
		bucketName:    s3BucketNames[greenRegion],
		backendConfig: mapToConfig(greenBackendMap),
		tfStateKey:    fmt.Sprintf("%s/%s", greenBackendMap["bucket"], greenBackendMap["key"]),
		testData:      blueConfig.testData,
		testFolder:    path.Join(tempTestFolder, "backend-test"),
		workspace:     "",
	}
	greenWorkspaceBackendConfig := mapToConfig(greenBackendMap)
	greenWorkspaceBackendConfig["workspace_key_prefix"] = WorkspaceKeyPrefix

	//greenWorkspaceConfig := BackendTestConfig{
	//	region:        greenConfig.region,
	//	bucketName:    greenConfig.bucketName,
	//	backendConfig: greenWorkspaceBackendConfig,
	//	tfStateKey:    fmt.Sprintf("%s/%s/%s/%s", greenBackendMap["bucket"], WorkspaceKeyPrefix, Workspace, greenBackendMap["key"]),
	//	testData:      blueWorkspaceConfig.testData,
	//	testFolder:    path.Join(tempTestFolder, "backend-workspace-test"),
	//	workspace:     Workspace,
	//}

	if !provisionInBlue(t, blueConfig) {
		assert.FailNow(t, "Blue backend not working as expected")
	}

	// Wait for replication from blue to green
	waitForReplication(t, "blue", blueConfig)

	// Verify that the values are visible in the green region, that
	// setting them to the same value does not change anything,
	// and that they can be changed in the green region (in preparation for
	// testing propagation back to blue).

	greenTestData, greenSuccess := verifyAndChange(t, "green", greenConfig)
	if !greenSuccess {
		assert.FailNow(t, "Green backend not working as expected")
	}

	// wait for replication from green to blue
	waitForReplication(t, "green", greenConfig)

	blueConfig.testData = greenTestData
	verifyAndChange(t, "blue", blueConfig)

}

func TestExamplesCompleteDisabled(t *testing.T) {
	t.Parallel()
	randID := strings.ToLower(random.UniqueId())
	attributes := []string{randID}

	rootFolder := "../../"
	terraformFolderRelativeToRoot := "examples/complete"
	varFiles := []string{"fixtures.us-east-2.tfvars"}

	tempTestFolder := testStructure.CopyTerraformFolderToTemp(t, rootFolder, terraformFolderRelativeToRoot)

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: tempTestFolder,
		Upgrade:      true,
		// Variables to pass to our Terraform code using -var-file options
		VarFiles: varFiles,
		Vars: map[string]interface{}{
			"attributes": attributes,
			"enabled":    "false",
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer cleanup(t, terraformOptions, tempTestFolder)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	results := terraform.InitAndApply(t, terraformOptions)

	// Should complete successfully without creating or changing any resources.
	// Extract the "Resources:" section of the output to make the error message more readable.
	re := regexp.MustCompile(`Resources: [^.]+\.`)
	match := re.FindString(results)
	assert.Equal(t, "Resources: 0 added, 0 changed, 0 destroyed.", match,
		"Applying with `enabled == false` should not create or change any resources")
}

func TestExamplesCompleteDestroyByDisable(t *testing.T) {
	t.Parallel()
	randID := strings.ToLower(random.UniqueId())
	attributes := []string{randID}

	rootFolder := "../../"
	terraformFolderRelativeToRoot := "examples/complete"
	varFiles := []string{"fixtures.us-east-2.tfvars"}

	tempTestFolder := testStructure.CopyTerraformFolderToTemp(t, rootFolder, terraformFolderRelativeToRoot)

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: tempTestFolder,
		Upgrade:      true,
		// Variables to pass to our Terraform code using -var-file options
		VarFiles: varFiles,
		Vars: map[string]interface{}{
			"attributes": attributes,
		},
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer cleanup(t, terraformOptions, tempTestFolder)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	results, err := terraform.InitAndApplyE(t, terraformOptions)
	if err != nil {
		require.FailNow(t, "Unable to create backend for testing")
	}

	terraformOptions.Vars = map[string]interface{}{
		"attributes": attributes,
		"enabled":    "false",
	}

	results, err = terraform.ApplyE(t, terraformOptions)
	if err != nil {
		require.FailNow(t, "Error while trying to destroy the backend by setting `enabled` to `false`")
	}

	results, err = terraform.DestroyE(t, terraformOptions)
	if err != nil {
		require.FailNow(t, "Error while trying to destroy the `enabled == false` backend")
	}

	// Should complete successfully destroying any resources.
	// Extract the "Resources:" section of the output to make the error message more readable.
	re := regexp.MustCompile(`Resources: [^.]+\.`)
	match := re.FindString(results)
	assert.Equal(t, "Resources: 0 destroyed.", match,
		"Destroying after `enabled == false` should not destroy any resources")

	// Terraform has "count" issues with destroying a project already destroyed, so we create it
	// again here so that the cleanup function will not fail.
	terraform.Apply(t, terraformOptions)
}
