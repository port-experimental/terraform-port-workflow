# terraform-port-workflow

Creates one Port workflow with the `port_workflow` resource. It deliberately contains no provider configuration or credentials; callers supply both from their root module.

> [!IMPORTANT]
> **Permissions** A self-service trigger without `permissions` can only be run by Port Admins. Set `permissions` on the trigger if non-admins need to run the workflow.

## Requirements

- Terraform >= 1.1
- `port-labs/port-labs` provider >= 2.34.4 (first release with node `timeout_minutes`)
- A root module that configures the Port provider with pipeline environment variables `PORT_CLIENT_ID` and `PORT_CLIENT_SECRET`

## Usage

```hcl
module "workflow" {
  source = "github.com/port-experimental/terraform-port-workflow?ref=1.0.3"

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

Each entry in `nodes` needs an `identifier` and exactly one of the node blocks below. Other Port node types, such as `INPUT`, `AI_AGENT`, `KAFKA` and `SCHEDULE_TRIGGER`, are not supported yet.

Triggers:

- `self_serve_trigger` — A form users submit on demand. `published` defaults to `true`. `user_inputs.user_properties` takes `string_props`, `number_props`, `boolean_props`, `object_props` and `array_props`, passed straight to the provider. `permissions` takes `roles`, `teams`, `users` and a `policy` object, which the module JSON-encodes.
- `event_trigger` — Runs when an entity changes. `type` is required: `ENTITY_CREATED`, `ENTITY_UPDATED`, `ENTITY_DELETED`, `ANY_ENTITY_CHANGE` or `TIMER_EXPIRED`. Set `blueprint_identifier` to the blueprint to watch, and `property_identifier` to the timer property for `TIMER_EXPIRED`. `published` defaults to `true`. The optional `condition` filters events with JQ `expressions`, evaluated against the event itself (`.diff.after...`, not `.outputs.trigger...`); `combinator` defaults to `"and"`.

Actions:

- `ai` — An AI step. Accepts `provider`, `model`, `system_prompt`, `user_prompt`, `tools`, `output_schema` and `mcp_servers`. Set `output_schema` when a later node needs structured fields from the response.
- `webhook` — Calls a URL. Accepts `url`, `method`, `headers`, `body`, `agent`, `synchronized`, `on_timeout`, `on_failure` and `timeout_minutes`. Pass `body` as an HCL object, because the module JSON-encodes it.
- `integration_action` — Runs an action through an installed Port integration, such as a GitHub workflow dispatch. `installation_id`, `integration_provider` and `integration_invocation_type` are required. Pass `execution_properties` as an HCL object, because the module JSON-encodes it; its fields depend on the provider (for `github-ocean`: `org`, `repo`, `workflow`, `workflowInputs` and `reportWorkflowStatus`). Set `on_failure = "continue"` so a failed dispatch doesn't stop the run. Set `timeout_minutes` for long-running actions such as Cursor agents; Port's default applies when it is omitted.
- `upsert_entity` — Creates or updates an entity on `blueprint_identifier`. `on_failure` defaults to `"terminate"`, which stops the whole run; set `"continue"` to carry on. Pass `mapping.properties` and `mapping.relations` as HCL objects, because the module JSON-encodes them for you.

Flow control:

- `condition` — Branches on JQ expressions. `outlets` is a list; each outlet needs an `identifier` and an `expression`, and can set a `title`. Outlets are checked in order and the first match wins. Each outlet can also set `status_label` and `workflow_status_label` (`text`, and a `variant` of `"success"` or `"alert"`) to label the node or the run when that branch is taken.

```hcl
nodes = [
  {
    identifier = "trigger"
    event_trigger = {
      type                 = "ENTITY_UPDATED"
      blueprint_identifier = "service"
      condition = {
        expressions = [".diff.after.properties.criticality != .diff.before.properties.criticality"]
      }
    }
  },
  {
    identifier = "check_criticality"
    title      = "Is it critical?"
    condition = {
      outlets = [
        {
          identifier = "critical"
          expression = ".outputs.trigger.diff.after.properties.criticality == \"critical\""
        }
      ]
    }
  },
  {
    identifier = "dispatch"
    title      = "Dispatch GitHub workflow"
    integration_action = {
      installation_id             = "github-ocean"
      integration_provider        = "github-ocean"
      integration_invocation_type = "dispatch_workflow"
      execution_properties = {
        org                  = "my-org"
        repo                 = "my-repo"
        workflow             = "notify.yml"
        workflowInputs       = { service = "{{ .outputs.trigger.diff.after.identifier }}" }
        reportWorkflowStatus = true
      }
    }
  },
  # ...a "record" node for the non-critical branch
]

connections = [
  { source_identifier = "trigger", target_identifier = "check_criticality" },
  { source_identifier = "check_criticality", target_identifier = "dispatch", source_outlet_identifier = "critical" },
  { source_identifier = "check_criticality", target_identifier = "record", fallback = true },
]
```

Every node also accepts optional `title`, `description`, `icon`, `verbose` (default `false`) and `variables`. Leave `title`, `description` and `icon` off trigger nodes, because Port ignores them there. Setting `variables` replaces the node's default output, so re-declare any field a downstream node reads.

Use snake_case node identifiers. A hyphen breaks JQ dot notation such as `{{ .outputs.my-node.field }}`; with hyphens you must use `{{ .outputs["my-node"].field }}` instead.

### Connections

Each entry in `connections` is a directed edge with a required `source_identifier` and `target_identifier`, plus optional `source_outlet_identifier`, `fallback` and `description`. Trigger nodes can only be sources. Each node can have only one outgoing connection, so chain steps in sequence rather than fanning out. The exception is a `condition` node: give it one connection per outlet, each with `source_outlet_identifier` set to the outlet's `identifier`, plus optionally one with `fallback = true` for when no outlet matches.

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
