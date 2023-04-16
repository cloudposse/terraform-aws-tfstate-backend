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
	"path"
	"regexp"
	"testing"
	"time"
)

// Wait for the tfstateKey object to be replicated
func waitForReplication(t *testing.T, color string, bucketName string, tfstateKey string, region string) {
	var (
		otherColor      string
		pollingDuration time.Duration
		replicaStatus   *s3.HeadObjectOutput
		rsError         error
	)
	if color == "blue" {
		otherColor = "green"
	} else {
		otherColor = "blue"
	}
	retryTime := 10 * time.Second
	replicaStatusRequest := &s3.HeadObjectInput{
		Bucket: aws.String(bucketName),
		Key:    aws.String(tfstateKey),
	}
	s3Client := s3.NewFromConfig(AWSConfig(region))

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
func provisionInBlue(t *testing.T, tempTestFolder string, testData string, backendMap map[string]string, bucketName string, tfstateKey string) bool {
	return t.Run("Provision in blue", func(t *testing.T) {
		region := backendMap["region"]

		terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
			// The path to where our Terraform code is located
			TerraformDir: path.Join(tempTestFolder, "backend-test"),
			NoColor:      true,
			Upgrade:      true,
			Vars: map[string]interface{}{
				"test": testData,
			},
			BackendConfig: mapToConfig(backendMap),
		})

		results := terraform.InitAndApply(t, terraformOptions)

		outputsRegex := regexp.MustCompile(`(?s)\n(Changes to Outputs:\n.+?\n)\n`)
		outputsMatch := outputsRegex.FindString(results)
		assert.NotEmpty(t, outputsMatch, "Apply should change outputs")

		outData := terraform.Output(t, terraformOptions, "test")
		require.Equal(t, testData, outData, "Unable to create resource in blue backend")

		// Check a state file actually got stored in S3 and contains our data in it somewhere
		// (since that data is used in an output of the Terraform code)
		contents := ttaws.GetS3ObjectContents(t, region, bucketName, tfstateKey)
		require.Contains(t, contents, testData)
	})
}

// Verify that the values are visible in a region, that
// setting them to the same value does not change anything,
// and that they can be changed in the region (in preparation for
// testing propagation back to the other region).

func verifyAndChange(t *testing.T, color string, backendMap map[string]string, bucketName string, tfstateKey string, testData string, tempTestFolder string) (string, bool) {
	region := backendMap["region"]
	newTestData := fmt.Sprintf("Test data for %s region %s: (%s)", color, region, random.UniqueId())
	return newTestData, t.Run(fmt.Sprintf("Verify and change in %s", color), func(t *testing.T) {
		s3Client := s3.NewFromConfig(AWSConfig(region))

		// Check a state file actually got stored in S3 and contains our data in it somewhere
		// (since that data is used in an output of the Terraform code)
		contents := ttaws.GetS3ObjectContents(t, backendMap["region"], bucketName, tfstateKey)
		require.Contains(t, contents, testData)

		// Check object's replica status
		replicaStatusRequest := &s3.HeadObjectInput{
			Bucket: aws.String(bucketName),
			Key:    aws.String(tfstateKey),
		}

		replicaStatus, rsError := s3Client.HeadObject(context.TODO(), replicaStatusRequest)
		assert.NoError(t, rsError, fmt.Sprintf("Error getting status of tfstate object in %s bucket", color))
		assert.NotNil(t, replicaStatus, fmt.Sprintf("No status returned from HeadObject for tfstate object in %s bucket", color))

		if replicaStatus != nil {
			assert.Equal(t, types.ReplicationStatusReplica, replicaStatus.ReplicationStatus, "Replicated tfstate not marked as REPLICA")
		}

		terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
			// The path to where our Terraform code is located
			TerraformDir: path.Join(tempTestFolder, "backend-test"),
			NoColor:      true,
			Reconfigure:  true,
			Upgrade:      true,
			Vars: map[string]interface{}{
				"test": testData,
			},
			BackendConfig: mapToConfig(backendMap),
		})

		if _, err := terraform.InitE(t, terraformOptions); err != nil {
			// Error will have already been logged, no need to log it again
			require.FailNow(t, fmt.Sprintf("Terminating test: unable to initialize %s backend", color))
		}

		outData := terraform.Output(t, terraformOptions, "test")
		assert.Equal(t, testData, outData, fmt.Sprintf("Unable to read resource in %s backend", color))

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
