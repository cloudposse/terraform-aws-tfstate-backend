package test

import (
	"context"
	"fmt"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/aws-sdk-go-v2/service/s3/types"
	ttaws "github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"regexp"
	"testing"
	"time"
)

type BackendTestConfig struct {
	region        string
	bucketName    string
	backendConfig map[string]any
	tfStateKey    string
	testData      string
	testFolder    string
	workspace     string
}

func testCrossRegionProvisioning(t *testing.T, blueConfig BackendTestConfig, greenConfig BackendTestConfig) {
	name := "Cross Region Without Workspace"
	if len(blueConfig.workspace) > 0 {
		name = "Cross Region With Workspace " + blueConfig.workspace
	}
	t.Run(name, func(t *testing.T) {
		t.Parallel()

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
	})
}

// Wait for the tfstateKey object to be replicated
func waitForReplication(t *testing.T, color string, cfg BackendTestConfig) {
	var (
		otherColor      string
		pollingDuration time.Duration
		replicaStatus   *s3.HeadObjectOutput
		rsError         error
	)
	if color == "green" {
		otherColor = "blue"
	} else {
		otherColor = "green"
	}
	retryTime := 10 * time.Second
	replicaStatusRequest := &s3.HeadObjectInput{
		Bucket: aws.String(cfg.bucketName),
		Key:    aws.String(cfg.tfStateKey),
	}
	s3Client := s3.NewFromConfig(AWSConfig(cfg.region))

	for i := 0; i < 15*6; i++ {
		replicaStatus, rsError = s3Client.HeadObject(context.TODO(), replicaStatusRequest)
		if rsError == nil && replicaStatus.ReplicationStatus != types.ReplicationStatusPending {
			break
		}
		if rsError != nil {
			t.Logf("HeadObject reports error %v", rsError)
			if i > 5 {
				require.FailNow(t, "Terminating test due to repeated HeadObject failures")
			}
		}
		t.Logf("Waiting for Terraform state to replicate from %s to %s... (%v elapsed)", color, otherColor, pollingDuration)
		pollingDuration += retryTime
		time.Sleep(retryTime)
	}
	require.NotNil(t, replicaStatus)
	// types.ReplicationStatusComplete is actually wrong
	// See https://github.com/aws/aws-sdk-go-v2/issues/2101
	require.EqualValues(t, "COMPLETED", replicaStatus.ReplicationStatus)

	t.Logf("Replication from %s to %s completed successfully", color, otherColor)
}

// Provision the resources the first time, using the blue backend
func provisionInBlue(t *testing.T, cfg BackendTestConfig) bool {
	testData := cfg.testData
	return t.Run("Provision in blue", func(t *testing.T) {

		terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
			// The path to where our Terraform code is located
			TerraformDir: cfg.testFolder,
			NoColor:      true,
			Upgrade:      true,
			Vars: map[string]interface{}{
				"test": testData,
			},
			BackendConfig: cfg.backendConfig,
		})

		var results string

		if len(cfg.workspace) == 0 {
			results = terraform.InitAndApply(t, terraformOptions)
		} else {
			if _, err := terraform.InitE(t, terraformOptions); err != nil {
				require.FailNow(t, "Unable to initialize project in directory %s", cfg.testFolder)
			}
			if _, err := terraform.WorkspaceSelectOrNewE(t, terraformOptions, cfg.workspace); err != nil {
				require.FailNow(t, "Unable to create workspace %s", cfg.workspace)
			}
			results = terraform.Apply(t, terraformOptions)
		}

		outputsRegex := regexp.MustCompile(`(?s)\n(Changes to Outputs:\n.+?\n)\n`)
		outputsMatch := outputsRegex.FindString(results)
		assert.NotEmpty(t, outputsMatch, "Apply should change outputs")

		outData := terraform.Output(t, terraformOptions, "test")
		require.Equal(t, testData, outData, "Unable to create resource in blue backend")

		// Check a state file actually got stored in S3 and contains our data in it somewhere
		// (since that data is used in an output of the Terraform code)
		contents := ttaws.GetS3ObjectContents(t, cfg.region, cfg.bucketName, cfg.tfStateKey)
		require.Contains(t, contents, testData)
	})
}

// Verify that the values are visible in a region, that
// setting them to the same value does not change anything,
// and that they can be changed in the region (in preparation for
// testing propagation back to the other region).

func verifyAndChange(t *testing.T, color string, cfg BackendTestConfig) (string, bool) {
	// tempTestFolder string, backendMap map[string]string, bucketName string, tfstateKey string, testData string) (string, bool) {
	region := cfg.region
	newTestData := fmt.Sprintf("Test data for %s region %s: (%s)", color, region, random.UniqueId())
	return newTestData, t.Run(fmt.Sprintf("Verify and change in %s", color), func(t *testing.T) {
		s3Client := s3.NewFromConfig(AWSConfig(region))

		// Check a state file actually got stored in S3 and contains our data in it somewhere
		// (since that data is used in an output of the Terraform code)
		contents := ttaws.GetS3ObjectContents(t, region, cfg.bucketName, cfg.tfStateKey)
		require.Contains(t, contents, cfg.testData)

		if color != "only" {
			// Check object's replica status
			replicaStatusRequest := &s3.HeadObjectInput{
				Bucket: aws.String(cfg.bucketName),
				Key:    aws.String(cfg.tfStateKey),
			}

			replicaStatus, rsError := s3Client.HeadObject(context.TODO(), replicaStatusRequest)
			assert.NoError(t, rsError, fmt.Sprintf("Error getting status of tfstate object in %s bucket", color))
			assert.NotNil(t, replicaStatus, fmt.Sprintf("No status returned from HeadObject for tfstate object in %s bucket", color))

			if replicaStatus != nil {
				assert.Equal(t, types.ReplicationStatusReplica, replicaStatus.ReplicationStatus, "Replicated tfstate not marked as REPLICA")
			}
		}

		terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
			// The path to where our Terraform code is located
			TerraformDir: cfg.testFolder,
			NoColor:      true,
			Reconfigure:  true,
			Upgrade:      true,
			Vars: map[string]interface{}{
				"test": cfg.testData,
			},
			BackendConfig: cfg.backendConfig,
		})

		if _, err := terraform.InitE(t, terraformOptions); err != nil {
			// Error will have already been logged, no need to log it again
			require.FailNow(t, fmt.Sprintf("Terminating test: unable to initialize %s backend", color))
		}

		if len(cfg.workspace) > 0 {
			if _, err := terraform.WorkspaceSelectOrNewE(t, terraformOptions, cfg.workspace); err != nil {
				require.FailNow(t, "Unable to select workspace %s", cfg.workspace)
			}
		}

		outData := terraform.Output(t, terraformOptions, "test")
		assert.Equal(t, cfg.testData, outData, fmt.Sprintf("Unable to read resource in %s backend", color))

		results := terraform.Apply(t, terraformOptions)

		// Should complete successfully without creating or changing any resources.
		// Extract the "Resources:" section of the output to make the error message more readable.
		idempotentMessage := fmt.Sprintf("Re-applying the same configuration in the %s backend should not change any ", color)
		resourcesRegex := regexp.MustCompile(`Resources: [^.]+\.`)
		resourcesMatch := resourcesRegex.FindString(results)
		assert.Equal(t, "Resources: 0 added, 0 changed, 0 destroyed.", resourcesMatch, idempotentMessage+"resources")

		outputsRegex := regexp.MustCompile(`(?s)\n(Changes to Outputs:\n.+?\n)\n`)
		outputsMatchSlice := outputsRegex.FindStringSubmatch(results)

		if len(outputsMatchSlice) > 0 {
			assert.Empty(t, outputsMatchSlice[1], idempotentMessage+"outputs")
		}

		terraformOptions.Vars = map[string]interface{}{
			"test": newTestData,
		}

		results = terraform.Apply(t, terraformOptions)

		outputsMatch := outputsRegex.FindString(results)
		assert.NotEmpty(t, outputsMatch, "Apply should change outputs")

		outData = terraform.Output(t, terraformOptions, "test")
		require.Equal(t, newTestData, outData, "Output not updated")
	})
}
