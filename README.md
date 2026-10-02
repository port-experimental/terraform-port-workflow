# terraform-port-workflow

Creates one Port workflow with the `port_workflow` resource. It deliberately contains no provider configuration or credentials; callers supply both from their root module.

> [!IMPORTANT]
> **Permissions** The module does not expose `permissions` on the self-service trigger, so a workflow created with it can only be run by Port Admins. Grant wider access in Port, or extend the module, if non-admins need to trigger it.

## Requirements

- Terraform >= 1.1
- `port-labs/port-labs` provider >= 2.25.0
- A root module that configures the Port provider with pipeline environment variables `PORT_CLIENT_ID` and `PORT_CLIENT_SECRET`

## Usage

```hcl
module "workflow" {
  source = "github.com/port-experimental/terraform-port-workflow?ref=1.0.0"

  identifier  = "create_service"
  title       = "Create service"
  description = "Registers a new service in the catalog."
  icon        = "Microservice"
  category    = "Catalog"

  nodes = [
    {
      identifier = "trigger"
      self_serve_trigger = {
        action_card_button_text = "Create"
        user_inputs = {
          user_properties = {
            string_props = {
              name = {
                title    = "Service name"
                required = true
              }
            }
          }
        }
      }
    },
    {
      identifier = "register_service"
      title      = "Register service"
      upsert_entity = {
        blueprint_identifier = "service"
        mapping = {
          identifier = "{{ .outputs.trigger.name }}"
          title      = "{{ .outputs.trigger.name }}"
          properties = {
            owner = "{{ .workflowRun.trigger.by.email }}"
          }
        }
      }
    }
  ]

  connections = [
    {
      source_identifier = "trigger"
      target_identifier = "register_service"
    }
  ]
}
```

### Nodes

Each entry in `nodes` needs an `identifier` and exactly one of the node blocks below. The module wires up only these three node kinds; other Port node types, such as `WEBHOOK`, `CONDITION` or `INPUT`, are not supported yet.

- `self_serve_trigger` — A form users submit on demand. `published` defaults to `true`. `user_inputs.user_properties` takes `string_props`, `number_props`, `boolean_props`, `object_props` and `array_props`, passed straight to the provider.
- `ai` — An AI step. Accepts `provider`, `model`, `system_prompt`, `user_prompt`, `tools` and `output_schema`. Set `output_schema` when a later node needs structured fields from the response.
- `upsert_entity` — Creates or updates an entity on `blueprint_identifier`. `on_failure` defaults to `"terminate"`, which stops the whole run; set `"continue"` to carry on. Pass `mapping.properties` and `mapping.relations` as HCL objects, because the module JSON-encodes them for you.

Every node also accepts optional `title`, `description`, `icon`, `verbose` (default `false`) and `variables`. Leave `title`, `description` and `icon` off trigger nodes, because Port ignores them there. Setting `variables` replaces the node's default output, so re-declare any field a downstream node reads.

Use snake_case node identifiers. A hyphen breaks JQ dot notation such as `{{ .outputs.my-node.field }}`; with hyphens you must use `{{ .outputs["my-node"].field }}` instead.

### Connections

Each entry in `connections` is a directed edge with a required `source_identifier` and `target_identifier`, plus optional `source_outlet_identifier`, `fallback` and `description`. Trigger nodes can only be sources. Each node can have only one outgoing connection, so chain steps in sequence rather than fanning out.

## Inputs

- `identifier` — Unique identifier for the workflow. Required.
- `title` — Display name of the workflow. Optional; defaults to `null`.
- `description` — Description of the workflow. Optional; defaults to `null`.
- `icon` — Port icon identifier. Optional; defaults to `null`.
- `category` — Category that groups the workflow in the UI, up to 40 characters. Optional; defaults to `null`.
- `allow_anyone_to_view_runs` — Whether all users can view workflow runs. Optional; defaults to `true`.
- `nodes` — Workflow node definitions. Required; must contain at least one node.
- `connections` — Directed connections between nodes. Optional; defaults to `[]`.

## Outputs

- `id` — Port's identifier for the workflow resource.
- `identifier` — Configured workflow identifier.
- `title` — Configured workflow title.
