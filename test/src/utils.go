package test

import (
	"context"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/require"
	"log"
	"os"
	"testing"
)

func cleanup(t *testing.T, terraformOptions *terraform.Options, tempTestFolder string) {
	t.Logf("Cleanup running Terraform destroy in folder %s\n", tempTestFolder)
	// If Destroy fails, it will log the error, so we do not need to log it again,
	// but we want to fail immediately rather than delete the temp folder, so we
	// have a chance to inspect the state, fix what went wrong, and destroy the resources.
	if _, err := terraform.DestroyE(t, terraformOptions); err != nil {
		require.FailNow(t, "Terraform destroy failed.\nNot deleting temp test folder (%s)", tempTestFolder)
	}
	if err := os.RemoveAll(tempTestFolder); err != nil {
		t.Logf("Error deleting temp folder %v: \n %v", tempTestFolder, err)
	}
}

func mapToConfig(m map[string]string) map[string]any {
	c := make(map[string]any)
	for k, v := range m {
		c[k] = v
	}
	return c
}

func AWSConfig(region string) aws.Config {
	// Load the default AWS Configuration
	cfg, err := config.LoadDefaultConfig(context.TODO(), config.WithRegion(region))
	if err != nil {
		log.Fatal(err)
	}

	return cfg
}
