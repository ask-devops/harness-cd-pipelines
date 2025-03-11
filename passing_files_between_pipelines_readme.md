
# Passing Files Between Pipelines in Harness

This guide demonstrates how to pass files between two pipelines in Harness using **Artifacts**.

## 1. Pipeline A (Producer): Generate and Upload the File as an Artifact

In this pipeline, you generate or process the file and upload it as an artifact.

### Example: Pipeline A - Generate and Upload Artifact

```yaml
pipeline:
  name: "Pipeline A - Generate and Upload Artifact"
  identifier: "Pipeline_A"
  projectIdentifier: "Your_Project"
  orgIdentifier: "Your_Org"
  stages:
    - stage:
        name: "Generate Artifact"
        identifier: "Generate_Artifact"
        type: "CI"
        spec:
          execution:
            steps:
              - step:
                  name: "Generate File"
                  identifier: "Generate_File"
                  type: "ShellScript"
                  spec:
                    shell: Sh
                    script: |
                      echo "This is a generated file" > /harness/test_file.txt
              - step:
                  name: "Upload Artifact to Harness"
                  identifier: "Upload_Artifact"
                  type: "StoreArtifact"
                  spec:
                    connectorRef: "your-artifact-repository"
                    artifactPaths:
                      - /harness/test_file.txt
                    artifactName: "test_file"
                    type: "Generic"
```

In **Pipeline A**, the **`Generate File`** step creates the file (`test_file.txt`), and the **`Upload Artifact`** step uploads the file as an artifact.

## 2. Pipeline B (Consumer): Fetch the Artifact and Use the File

In **Pipeline B**, you fetch the artifact uploaded in **Pipeline A** and use the file in subsequent steps.

### Example: Pipeline B - Consume Artifact

```yaml
pipeline:
  name: "Pipeline B - Consume Artifact"
  identifier: "Pipeline_B"
  projectIdentifier: "Your_Project"
  orgIdentifier: "Your_Org"
  stages:
    - stage:
        name: "Fetch and Use Artifact"
        identifier: "Fetch_Artifact"
        type: "Deployment"
        spec:
          execution:
            steps:
              - step:
                  name: "Fetch Artifact"
                  identifier: "Fetch_Artifact_Step"
                  type: "ArtifactSource"
                  spec:
                    connectorRef: "your-artifact-repository"
                    artifactName: "test_file"
                    type: "Generic"
              - step:
                  name: "Use the Artifact"
                  identifier: "Use_Artifact_Step"
                  type: "ShellScript"
                  spec:
                    shell: Sh
                    script: |
                      cat ${artifact.test_file}
                      # Process the file content here
```

In **Pipeline B**, the **`Fetch Artifact`** step fetches the artifact (`test_file`) uploaded by **Pipeline A**, and the **`Use the Artifact`** step processes the file content.

## 3. Triggering Pipeline B from Pipeline A

If you want to automatically trigger **Pipeline B** after **Pipeline A** completes, you can set up a **Trigger** to invoke **Pipeline B** from within **Pipeline A**.

### Example: Trigger Pipeline B from Pipeline A

```yaml
pipeline:
  name: "Pipeline A - Trigger Pipeline B"
  identifier: "Pipeline_A"
  projectIdentifier: "Your_Project"
  orgIdentifier: "Your_Org"
  stages:
    - stage:
        name: "Trigger Pipeline B"
        identifier: "Trigger_Pipeline_B"
        type: "CI"
        spec:
          execution:
            steps:
              - step:
                  name: "Trigger Pipeline B"
                  identifier: "Trigger_Pipeline_B_Step"
                  type: "RunPipeline"
                  spec:
                    pipeline:
                      identifier: "Pipeline_B"
                      projectIdentifier: "Your_Project"
                      orgIdentifier: "Your_Org"
                    variables:
                      ARTIFACT_FROM_PIPELINE_A: "<+pipeline.variables.TEST_FILE>"
```

In this setup, **Pipeline A** triggers **Pipeline B** after completion and passes any variables like file paths.

## Summary

1. **Pipeline A** generates a file and uploads it as an artifact.
2. **Pipeline B** fetches the artifact and processes it.
3. Optionally, **Pipeline A** triggers **Pipeline B** and passes the artifact or file.

This setup allows for easy passing of files between pipelines in Harness.
