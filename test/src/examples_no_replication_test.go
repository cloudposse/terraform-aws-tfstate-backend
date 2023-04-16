package test

import (
	"fmt"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	testStructure "github.com/gruntwork-io/terratest/modules/test-structure"
	"path"

	"github.com/stretchr/testify/assert"
	"strings"
	"testing"
)

// Test the Terraform module in examples/complete using Terratest.
func TestExamplesNoReplication(t *testing.T) {
	t.Parallel()
	randID := strings.ToLower(random.UniqueId())
	attributes := []string{randID}

	rootFolder := "../../"
	terraformFolderRelativeToRoot := "examples/no-replication"
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
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the value of an output variable
	s3BucketId := terraform.Output(t, terraformOptions, "s3_bucket_id")
	expectedS3BucketId := "eg-use2-test-terraform-tfstate-backend-" + randID
	// Verify we're getting back the outputs we expect
	assert.Equal(t, expectedS3BucketId, s3BucketId)

	// Run `terraform output` to get the value of an output variable
	dynamodbTableName := terraform.Output(t, terraformOptions, "dynamodb_table_name")
	expectedDynamodbTableName := "eg-use2-test-terraform-tfstate-backend-" + randID + "-lock"
	// Verify we're getting back the outputs we expect
	assert.Equal(t, expectedDynamodbTableName, dynamodbTableName)

	backendMap := terraform.OutputMap(t, terraformOptions, "backend_config")

	backendTestConfig := BackendTestConfig{
		region:        backendMap["region"],
		bucketName:    s3BucketId,
		backendConfig: mapToConfig(backendMap),
		tfStateKey:    backendMap["key"],
		testData:      fmt.Sprintf("data-for-no-replication-test-%s", randID),
		testFolder:    path.Join(path.Dir(tempTestFolder), "complete", "backend-test"),
		workspace:     "",
	}

	if !provisionInBlue(t, backendTestConfig) {
		assert.FailNow(t, "No-replication backend not working as expected")
	}

	verifyAndChange(t, "only", backendTestConfig)
}
