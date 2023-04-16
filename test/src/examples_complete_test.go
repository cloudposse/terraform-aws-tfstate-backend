package test

import (
	"fmt"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	testStructure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"regexp"
	"strings"
	"testing"
)

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

	// Deploy a null resource (an output) in the blue region.
	// Verify that the resource is in the Terraform state in the blue S3 bucket
	// and that the state object is replicated.
	blueBackendMap := terraform.OutputMap(t, terraformOptions, "blue_backend_config")
	blueRegion := blueBackendMap["region"]
	s3BucketNames := terraform.OutputMap(t, terraformOptions, "s3_bucket_ids")
	blueBucket := s3BucketNames[blueRegion]
	// For multi-region, the keys are prefixed with what is configured as the bucket name
	tfstateKey := fmt.Sprintf("%s/%s", blueBackendMap["bucket"], blueBackendMap["key"])
	require.NotEmpty(t, blueBucket, "Could not find bucket name for blue region")

	testData := fmt.Sprintf("data-for-blue-test-%s", randID)

	if !provisionInBlue(t, tempTestFolder, testData, blueBackendMap, blueBucket, tfstateKey) {
		assert.FailNow(t, "Blue backend not working as expected")
	}

	// Wait for replication from blue to green
	waitForReplication(t, "blue", blueBucket, tfstateKey, blueRegion)

	// Verify that the values are visible in the green region, that
	// setting them to the same value does not change anything,
	// and that they can be changed in the green region (in preparation for
	// testing propagation back to blue).

	greenBackendMap := terraform.OutputMap(t, terraformOptions, "green_backend_config")
	greenRegion := greenBackendMap["region"]
	greenBucket := s3BucketNames[greenRegion]

	greenTestData, greenSuccess := verifyAndChange(t, "green", greenBackendMap, greenBucket, tfstateKey, testData, tempTestFolder)
	if !greenSuccess {
		assert.FailNow(t, "Green backend not working as expected")
	}

	// wait for replication from green to blue
	waitForReplication(t, "green", greenBucket, tfstateKey, greenRegion)

	verifyAndChange(t, "blue", blueBackendMap, blueBucket, tfstateKey, greenTestData, tempTestFolder)

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
