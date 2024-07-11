// https://developer.hashicorp.com/terraform/internals/json-format

package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/exec"
	"time"
)

type TFPlan struct {
	Path          string
	FormatVersion string `json:"format_version"`
	CanApply      bool   `json:"applyable"`
	WillComplete  bool   `json:"complete"`
	IsErrored     bool   `json:"errored"`
}

func InitializeTF() (err error) {
	dirInfo, err := os.Stat(TerraformWorkingDir)
	if err != nil {
		return fmt.Errorf("error checking directory %v: %v", TerraformWorkingDir, err)
	}
	if !dirInfo.IsDir() {
		return fmt.Errorf("%s is not a directory", TerraformWorkingDir)
	}

	log.Println("Checking Terraform configuration...")
	_, err = tfWrap("init")
	if err != nil {
		return fmt.Errorf("couldn't initialize terraform configuration: %v", err)
	}
	_, err = tfWrap("validate")
	if err != nil {
		return fmt.Errorf("couldn't validate terraform configuration: %v", err)
	}
	log.Println("Successfully checked Terraform configuration")

	return nil
}

func ApplyTF() (err error) {
	var plan TFPlan

	err = planTF(plan)
	if err != nil {
		return fmt.Errorf("couldn't plan terraform configuration: %v", err)
	}

	if plan.FormatVersion != "1.2" {
		return fmt.Errorf("terraform plan format version differs. expected %v, got %v", "1.2", plan.FormatVersion)
	}
	if plan.IsErrored {
		return fmt.Errorf("terraform plan has failed, cannot continue")
	}
	if !plan.WillComplete {
		return fmt.Errorf("unexpected terraform plan behaviour, state after apply should match the desired state")
	}
	if !plan.CanApply {
		log.Println("Terraform plan has already been applyed")
		return nil
	}

	log.Println("Applying terraform configuration...")
	_, err = tfWrap("apply", "-plan="+plan.Path, "-auto-approve=true", "-input=false")
	if err != nil {
		return fmt.Errorf("couldn't apply terraform configuration: %v", err)
	}
	log.Println("Applyed terraform configuration.")

	return nil
}

func planTF(plan TFPlan) (err error) {
	t := time.Now()
	plan.Path = fmt.Sprintf("./plan-%v", t.UnixNano())

	log.Println("Planning terraform configuration...")
	_, err = tfWrap("plan", "-out="+plan.Path)
	if err != nil {
		return fmt.Errorf("couldn't plan terraform configuration: %v", err)
	}
	log.Println("Planned terraform configuration.")

	output, err := tfWrap("show", "-json", plan.Path)
	if err != nil {
		return fmt.Errorf("couldn't inspect terraform plan: %v", err)
	}

	err = json.Unmarshal(output, &plan)
	if err != nil {
		return fmt.Errorf("couldn't parse JSON from terraform plan: %v", err)
	}

	return nil
}

func tfWrap(args ...string) (output []byte, err error) {
	allArgs := append([]string{"-chdir=" + TerraformWorkingDir}, args...)

	cmd := exec.Command("terraform", allArgs...)

	output, err = cmd.CombinedOutput()
	if err != nil {
		return nil, fmt.Errorf("terraform command failed:\n%v", string(output))
	}

	return output, nil
}
