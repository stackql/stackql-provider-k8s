# StackQL Provider Template

This repository serves as a template for developing StackQL providers. It provides a structured workflow and tools to generate, test, and document StackQL providers for various cloud services and APIs.

## What is StackQL?

[StackQL](https://github.com/stackql/stackql) is an open-source SQL interface for cloud APIs that allows you to query and manipulate cloud resources using SQL-like syntax. With StackQL, you can:

- Query cloud resources across multiple providers using familiar SQL syntax
- Join data from different services and providers
- Execute CRUDL operations (`SELECT`, `INSERT`, `UPDATE`, `REPLACE`, `DELETE`) on cloud resources
- Execute lifecycle operations (like starting or stopping vms) using `EXEC`
- Build custom dashboards and reports
- Automate infrastructure operations using [`stackql-deploy`](https://stackql-deploy.io/)

## What are StackQL Providers?

StackQL providers are extensions that connect StackQL to specific cloud services or APIs. Each provider:

1. Defines a schema that maps API endpoints to SQL-like resources and methods
2. Implements authentication mechanisms for the target API
3. Translates SQL operations into API calls
4. Transforms API responses into tabular data that can be queried with SQL

This template repository helps you build StackQL providers by converting OpenAPI specifications into StackQL-compatible provider schemas using the `@stackql/provider-utils` package.

## How StackQL Providers Work

StackQL providers bridge the gap between SQL queries and REST APIs:

1. **Resource Mapping**: API endpoints are mapped to SQL-like tables and views
2. **Method Mapping**: API operations are mapped to SQL verbs (`SELECT`, `INSERT`, `UPDATE`, `REPLACE`, `DELETE` and `EXEC`)
3. **Parameter Mapping**: SQL query conditions are translated to API parameters
4. **Response Transformation**: API responses are converted to tabular results

## Prerequisites

To use this template for developing a StackQL provider, you'll need:

1. An OpenAPI specification for the target API
2. Node.js and `npm` installed on your system
3. StackQL CLI installed (see [StackQL Installation](https://stackql.io/docs/installing-stackql))
4. API credentials for testing your provider

## Development Workflow

### 1. Clone this Template

Start by cloning this template repository and installing dependencies:

```bash
git clone https://github.com/stackql/stackql-provider-template.git stackql-provider-myprovider
cd stackql-provider-myprovider
npm install
```

### 2. Download the OpenAPI Specification

Obtain the OpenAPI specification for your target API. You can typically find this in the API documentation or developer portal.

```bash
mkdir -p provider-dev/downloaded
curl -L https://api-url.example.com/openapi.yaml -o provider-dev/downloaded/provider-name.yaml
```

> recommended to automate this by creating a script in the `provider-dev/scripts` folder

### 3. Split the OpenAPI Spec into Service Specs

Break down the OpenAPI specification into smaller, service-specific files:

```bash
npm run split -- \
  --provider-name your-provider-name \
  --api-doc provider-dev/downloaded/provider-name.yaml \
  --svc-discriminator tag \
  --output-dir provider-dev/source \
  --overwrite \
  --svc-name-overrides "$(cat <<EOF
{
  "service_tag_1": "service_name_1",
  "service_tag_2": "service_name_2"
  # Add more mappings as needed
}
EOF
)"
```

This step organizes the API endpoints into logical services based on OpenAPI tags. You can customize the service names using the `--svc-name-overrides` parameter.  

`svc-discriminator` can be based upon `tags` in each operation or based upon the path for each operation.

### 4. Generate Mappings

Generate the mapping configuration that connects OpenAPI operations to StackQL resources:

```bash
npm run generate-mappings -- \
  --provider-name your-provider-name \
  --input-dir provider-dev/source \
  --output-dir provider-dev/config
```

This creates a CSV mapping file that you'll need to edit to define how OpenAPI operations translate to StackQL resources, methods, and SQL verbs.

### 5. Edit the Mapping File

Edit the generated `provider-dev/config/all_services.csv` file to add:
- `stackql_resource_name`: The name of the StackQL resource (table/view)
- `stackql_method_name`: The name of the StackQL method
- `stackql_verb`: The SQL verb (`SELECT`, `INSERT`, `UPDATE`, `REPLACE`, `DELETE`, `EXEC`)

For example:
```csv
service,operationId,summary,stackql_resource_name,stackql_method_name,stackql_verb
compute,listDroplets,List all Droplets,droplets,list,SELECT
compute,createDroplet,Create a new Droplet,droplets,insert,INSERT
compute,getDroplet,Retrieve an existing Droplet,droplets,get,SELECT
compute,deleteDroplet,Delete a Droplet,droplets,delete,DELETE
```

### 6. Generate the Provider

Transform the OpenAPI service specs into a StackQL provider:

```bash
npm run generate-provider -- \
  --provider-name your-provider-name \
  --input-dir provider-dev/source \
  --output-dir provider-dev/openapi/src/your-provider-name \
  --config-path provider-dev/config/all_services.csv \
  --servers '[{"url": "https://api.example.com/v1"}]' \
  --provider-config '{"auth": {"credentialsenvvar": "PROVIDER_API_KEY","type": "header", "headerName": "Authorization"}}' \
  --overwrite
```

Make any necessary post-processing updates to the generated files, for example:

```bash
node provider-dev/scripts/flatten_allOf.cjs
sh provider-dev/scripts/fix_broken_links.sh
```

> this will vary by provider and may not be necessary in many cases

### 7. Test the Provider

#### Start the StackQL Server

```bash
PROVIDER_REGISTRY_ROOT_DIR="$(pwd)/provider-dev/openapi"
npm run start-server -- --provider your-provider-name --registry $PROVIDER_REGISTRY_ROOT_DIR
```

#### Test Metadata Routes

```bash
npm run test-meta-routes -- your-provider-name --verbose
```

#### Run Test Queries

```bash
PROVIDER_REGISTRY_ROOT_DIR="$(pwd)/provider-dev/openapi"
REG_STR='{"url": "file://'${PROVIDER_REGISTRY_ROOT_DIR}'", "localDocRoot": "'${PROVIDER_REGISTRY_ROOT_DIR}'", "verifyConfig": {"nopVerify": true}}'
./stackql shell --registry="${REG_STR}"
```

Example test query:
```sql
SELECT * FROM your-provider-name.service_name.resource_name LIMIT 10;
```

When you're done testing, stop the StackQL server:
```bash
npm run stop-server
```

### 8. Publish the Provider

To publish your provider:

1. Fork the [stackql-provider-registry](https://github.com/stackql/stackql-provider-registry) repository
2. Copy your provider directory to `providers/src` in a feature branch
3. Follow the [registry release flow](https://github.com/stackql/stackql-provider-registry/blob/dev/docs/build-and-deployment.md)

Test your published provider in the `dev` registry:
```bash
export DEV_REG="{ \"url\": \"https://registry-dev.stackql.app/providers\" }"
./stackql --registry="${DEV_REG}" shell
```

Pull and verify your provider:
```sql
registry pull your-provider-name;
-- Run test queries
```

### 9. Generate Documentation

Provider doc microsites are built using Docusaurus and published using GitHub Pages.  To genarate and publish comprehensive user docs for your provider, do the following:  

a. Upodate `headerContent1.txt` and `headerContent2.txt` accordingly in `provider-dev/docgen/provider-data/`  

b. Update the following in `website/docusaurus.config.js`:  

```js
// Provider configuration - change these for different providers
const providerName = "yourprovidername";
const providerTitle = "Your Provider Title";
```

c. Then generate docs using...

```bash
npm run generate-docs -- \
  --provider-name your-provider-name \
  --provider-dir ./provider-dev/openapi/src/your-provider-name/v00.00.00000 \
  --output-dir ./website \
  --provider-data-dir ./provider-dev/docgen/provider-data
```  

d. Test the documentation locally:
```bash
cd website
yarn build
yarn start
```

### 10. Publish Documentation

Remove the `.disabled` extension from `.github/workflows/test-web-deploy.yml.disabled` and `.github/workflows/prod-web-deploy.yml.disabled`  

Set up GitHub Pages in your repository settings, and configure DNS if needed:

| Source Domain | Record Type | Target |
|---------------|-------------|--------|
| your-provider-name-provider.stackql.io | CNAME | stackql.github.io. |

## Authentication Configuration

Different APIs require different authentication methods. Here are common authentication configurations:

### API Key in Header
```json
{
  "auth": {
    "credentialsenvvar": "PROVIDER_API_KEY",
    "type": "header",
    "headerName": "X-API-Key"
  }
}
```

### Bearer Token
```json
{
  "auth": {
    "credentialsenvvar": "PROVIDER_TOKEN",
    "type": "bearer"
  }
}
```

### Basic Authentication
```json
{
  "auth": {
    "credentialsenvvar": "PROVIDER_BASIC_AUTH",
    "type": "basic"
  }
}
```

### OAuth (Client Credentials Flow)
```json
{
  "auth": {
    "credentialsenvvar": "PROVIDER_OAUTH_CONFIG",
    "type": "oauth-client-credentials",
    "tokenUrl": "https://auth.example.com/token"
  }
}
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT