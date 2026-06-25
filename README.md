# Azure Python Function + Terraform

This repository contains an Azure Functions Python app and Terraform infrastructure code to deploy it.

## Repository structure

- `Python function/`
  - `function_app.py` - Python Azure Function app with an HTTP-triggered route named `httpbin`.
  - `host.json` - Azure Functions host configuration.
  - `local.settings.json` - Local settings for development.
  - `requirements.txt` - Python dependencies.
- `Terraform/`
  - `main.tf` - Azure resource definitions for the Function App, App Service Plan, Storage Account, Application Insights, API Management, Front Door, Event Hub, and diagnostics.
  - `provider.tf` - Azure provider configuration.
  - `variables.tf` - Input variables required for deployment.
  - `outputs.tf` - Terraform outputs returned after deployment.
  - `backend.sh` - Optional backend helper script.
  - `terraform.tfvars` - Example values for Terraform variables.

## Features

- HTTP-triggered Azure Function with route `httpbin`
- Python Azure Functions runtime
- Terraform-managed Azure infrastructure
- App Service Plan (Linux)
- Storage Account and Application Insights
- API Management gateway
- Azure Front Door routing
- Event Hub namespace, hub, and diagnostic settings

## Python Function

The function is defined in `Python function/function_app.py` and returns a personalized response when a `name` is provided.

Example HTTP request:

```http
GET /api/httpbin?name=Azure
```

Example response:

```text
Hello, Azure. This HTTP triggered function executed successfully.
```

If no `name` parameter is provided, the function returns a default success message.

## Local development

1. Install dependencies:

```bash
cd "Python function"
pip install -r requirements.txt
```

2. Run locally using the Azure Functions Core Tools:

```bash
func start
```

3. Invoke locally:

```bash
curl "http://localhost:7071/api/httpbin?name=Local"
```

## Terraform deployment

1. Change into the Terraform directory:

```bash
cd Terraform
```

2. Initialize Terraform:

```bash
terraform init
```

3. Plan deployment:

```bash
terraform plan -var="location=westus2" \
  -var="rg-name=<resource-group-name>" \
  -var="fn_storage_account_name=<storage-account-name>" \
  -var="fn_app_service_plan_name=<service-plan-name>" \
  -var="function_app_name=<function-app-name>" \
  -var="apim_name=<apim-name>" \
  -var="function_name=httpbin" \
  -var="environment=dev"
```

4. Apply deployment:

```bash
terraform apply -var="location=westus2" \
  -var="rg-name=<resource-group-name>" \
  -var="fn_storage_account_name=<storage-account-name>" \
  -var="fn_app_service_plan_name=<service-plan-name>" \
  -var="function_app_name=<function-app-name>" \
  -var="apim_name=<apim-name>" \
  -var="function_name=httpbin" \
  -var="environment=dev"
```

5. After creation, inspect outputs for the APIM gateway URL and Front Door endpoint.

## Notes

- The function app uses `FUNCTIONS_WORKER_RUNTIME=python`.
- `requirements.txt` includes only the `azure-functions` package. Do not manually include `azure-functions-worker`.
- The HTTP route is defined as `httpbin`, and Azure Functions applies the default `api/` route prefix.

## Useful file locations

- `Python function/function_app.py` - core Python function code
- `Python function/host.json` - function host settings
- `Python function/local.settings.json` - local development settings
- `Terraform/main.tf` - infrastructure definitions
- `Terraform/variables.tf` - deployment variables
- `Terraform/outputs.tf` - deployment outputs

