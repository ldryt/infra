package main

import (
	"context"
	"fmt"
	"os"

	"github.com/hashicorp/terraform-exec/tfexec"
)

var (
	tf *tfexec.Terraform
)

func InitTF() (err error) {
	dirInfo, err := os.Stat(TerraformWorkingDir)
	if err != nil {
		return fmt.Errorf("error checking directory %v: %v", TerraformWorkingDir, err)
	}
	if !dirInfo.IsDir() {
		return fmt.Errorf("%v is not a directory", TerraformWorkingDir)
	}

	tf, err = tfexec.NewTerraform(TerraformWorkingDir, TerraformExecPath)
	if err != nil {
		return fmt.Errorf("error loading terraform: %s", err)
	}

	err = tf.Init(context.Background())
	if err != nil {
		return fmt.Errorf("error running Init: %s", err)
	}

	return nil
}

func ApplyTF(destroy bool) (ip string, err error) {
	err = tf.Apply(context.Background(), tfexec.Var(fmt.Sprintf("%v=%v", "ignore_instance_zarina", destroy)))
	if err != nil {
		return "", fmt.Errorf("error running Apply: %s", err)
	}

	out, err := tf.Output(context.Background())
	if err != nil {
		return "", fmt.Errorf("error running Output: %s", err)
	}

	ip = string(out["zarina_ipv4"].Value)

	return ip, nil
}
