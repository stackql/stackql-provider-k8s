# `k8s` provider for [`stackql`](https://github.com/stackql/stackql)

This repository is used to generate and document the `k8s` provider for StackQL, allowing you to query and manipulate Kubernetes resources using SQL-like syntax. The provider is built using the `@stackql/provider-utils` package, which provides tools for converting OpenAPI specifications into StackQL-compatible provider schemas.

## Prerequisites

To use the Kubernetes provider with StackQL, you'll need:

1. Access to a Kubernetes cluster with appropriate permissions
2. A properly configured `kubectl` with a valid kubeconfig file
3. StackQL CLI installed on your system (see [StackQL](https://github.com/stackql/stackql))

## 1. Download the Open API Specification

First, download the Kubernetes OpenAPI specification from your target cluster:

```bash
mkdir -p provider-dev/downloaded

# Option 1: Download directly from a running cluster
kubectl get --raw /openapi/v2 > provider-dev/downloaded/k8s-openapi.json

# Option 2: Or fetch from a specific Kubernetes version
curl -L https://raw.githubusercontent.com/kubernetes/kubernetes/release-1.28/api/openapi-spec/swagger.json \
  -o provider-dev/downloaded/k8s-openapi.json
```

## 2. Split into Service Specs

Next, split the monolithic OpenAPI specification into service-specific files:

```bash
rm -rf provider-dev/source/*
npm run split -- \
  --provider-name k8s \
  --api-doc provider-dev/downloaded/k8s-openapi.json \
  --svc-discriminator group \
  --output-dir provider-dev/source \
  --overwrite \
  --svc-name-overrides "$(cat <<EOF
{
  "apps": "apps",
  "core": "core",
  "networking.k8s.io": "networking",
  "batch": "batch",
  "storage.k8s.io": "storage",
  "rbac.authorization.k8s.io": "rbac",
  "apiextensions.k8s.io": "apiextensions",
  "policy": "policy",
  "autoscaling": "autoscaling",
  "admissionregistration.k8s.io": "admissionregistration",
  "certificates.k8s.io": "certificates"
}
EOF
)"
```

## 3. Generate Mappings

Generate the mapping configuration that connects OpenAPI operations to StackQL resources:

```bash
npm run generate-mappings -- \
  --provider-name k8s \
  --input-dir provider-dev/source \
  --output-dir provider-dev/config
```

Update the resultant `provider-dev/config/all_services.csv` to add the `stackql_resource_name`, `stackql_method_name`, `stackql_verb` values for each operation.

## 4. Generate Provider

This step transforms the split OpenAPI service specs into a fully-functional StackQL provider by applying the resource and method mappings defined in your CSV file.

```bash
rm -rf provider-dev/openapi/*
npm run generate-provider -- \
  --provider-name k8s \
  --input-dir provider-dev/source \
  --output-dir provider-dev/openapi/src/k8s \
  --config-path provider-dev/config/all_services.csv \
  --servers '[{"url": "https://kubernetes.default.svc"}]' \
  --provider-config '{"auth": {"type": "k8s", "credentialsenvvar": "KUBECONFIG"}}' \
  --overwrite
```

## 5. Test Provider

### Starting the StackQL Server

Before running tests, start a StackQL server with your provider:

```bash
PROVIDER_REGISTRY_ROOT_DIR="$(pwd)/provider-dev/openapi"
npm run start-server -- --provider k8s --registry $PROVIDER_REGISTRY_ROOT_DIR
```

### Test Meta Routes

Test all metadata routes (services, resources, methods) in the provider:

```bash
npm run test-meta-routes -- k8s --verbose
```

When you're done testing, stop the StackQL server:

```bash
npm run stop-server
```

Use this command to view the server status:

```bash
npm run server-status
```

### Run test queries

Run some test queries against the provider using the `stackql shell`:

```bash
PROVIDER_REGISTRY_ROOT_DIR="$(pwd)/provider-dev/openapi"
REG_STR='{"url": "file://'${PROVIDER_REGISTRY_ROOT_DIR}'", "localDocRoot": "'${PROVIDER_REGISTRY_ROOT_DIR}'", "verifyConfig": {"nopVerify": true}}'
./stackql shell --registry="${REG_STR}"
```

Example queries to try:

```sql
-- List all namespaces
SELECT 
metadata.name,
metadata.creation_timestamp,
status.phase
FROM k8s.core.namespaces;

-- List all pods in all namespaces
SELECT 
metadata.name,
metadata.namespace,
status.phase,
status.pod_ip,
status.host_ip,
spec.node_name
FROM k8s.core.pods_all_namespaces;

-- List all deployments
SELECT 
metadata.name,
metadata.namespace,
spec.replicas,
status.ready_replicas,
status.available_replicas,
status.unavailable_replicas
FROM k8s.apps.deployments_all_namespaces;

-- List all nodes and their conditions
SELECT 
n.metadata.name,
n.status.capacity,
n.status.allocatable,
c.type,
c.status,
c.last_transition_time
FROM k8s.core.nodes n,
UNNEST(n.status.conditions) AS c;

-- Get information about persistent volumes
SELECT 
metadata.name,
spec.capacity,
spec.access_modes,
spec.persistent_volume_reclaim_policy,
spec.storage_class_name,
status.phase
FROM k8s.core.persistent_volumes;

-- Check RBAC roles and bindings
SELECT 
metadata.name,
metadata.namespace,
rules
FROM k8s.rbac.roles_all_namespaces;
```

## 6. Publish the provider

To publish the provider push the `k8s` dir to `providers/src` in a feature branch of the [`stackql-provider-registry`](https://github.com/stackql/stackql-provider-registry). Follow the [registry release flow](https://github.com/stackql/stackql-provider-registry/blob/dev/docs/build-and-deployment.md).  

Launch the StackQL shell:

```bash
export DEV_REG="{ \"url\": \"https://registry-dev.stackql.app/providers\" }"
./stackql --registry="${DEV_REG}" shell
```

Pull the latest dev `k8s` provider:

```sql
registry pull k8s;
```

Run some test queries to verify the provider works as expected.

## 7. Generate web docs

Provider doc microsites are built using Docusaurus and published using GitHub Pages.  

a. Update `headerContent1.txt` and `headerContent2.txt` accordingly in `provider-dev/docgen/provider-data/`  

b. Update the following in `website/docusaurus.config.js`:  

```js
// Provider configuration - change these for different providers
const providerName = "k8s";
const providerTitle = "Kubernetes Provider";
```

c. Then generate docs using...

```bash
npm run generate-docs -- \
  --provider-name k8s \
  --provider-dir ./provider-dev/openapi/src/k8s/v00.00.00000 \
  --output-dir ./website \
  --provider-data-dir ./provider-dev/docgen/provider-data
```  

## 8. Test web docs locally

```bash
cd website
# test build
yarn build

# run local dev server
yarn start
```

## 9. Publish web docs to GitHub Pages

Under __Pages__ in the repository, in the __Build and deployment__ section select __GitHub Actions__ as the __Source__. In Netlify DNS create the following records:

| Source Domain | Record Type  | Target |
|---------------|--------------|--------|
| k8s-provider.stackql.io | CNAME | stackql.github.io. |

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.