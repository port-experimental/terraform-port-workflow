resource "port_workflow" "main" {
  identifier                = var.identifier
  title                     = var.title
  description               = var.description
  icon                      = var.icon
  category                  = var.category
  allow_anyone_to_view_runs = var.allow_anyone_to_view_runs
  dynamic "node" {
    for_each = var.nodes
    content {
      identifier  = node.value.identifier
      title       = try(node.value.title, null)
      description = try(node.value.description, null)
      icon        = try(node.value.icon, null)
      verbose     = try(node.value.verbose, false)
      variables   = try(node.value.variables, null)
      dynamic "self_serve_trigger" {
        for_each = try(node.value.self_serve_trigger, null) == null ? [] : [node.value.self_serve_trigger]
        content {
          published                  = try(self_serve_trigger.value.published, true)
          action_card_button_text    = try(self_serve_trigger.value.action_card_button_text, null)
          execute_action_button_text = try(self_serve_trigger.value.execute_action_button_text, null)
          variant                    = try(self_serve_trigger.value.variant, null)
          dynamic "user_inputs" {
            for_each = try(self_serve_trigger.value.user_inputs, null) == null ? [] : [self_serve_trigger.value.user_inputs]
            content {
              user_properties = {
                string_props  = try(user_inputs.value.user_properties.string_props, null)
                number_props  = try(user_inputs.value.user_properties.number_props, null)
                boolean_props = try(user_inputs.value.user_properties.boolean_props, null)
                object_props  = try(user_inputs.value.user_properties.object_props, null)
                array_props   = try(user_inputs.value.user_properties.array_props, null)
              }
              order_properties = try(user_inputs.value.order_properties, null)
            }
          }
          dynamic "permissions" {
            for_each = try(self_serve_trigger.value.permissions, null) == null ? [] : [self_serve_trigger.value.permissions]
            content {
              roles  = try(permissions.value.roles, null)
              teams  = try(permissions.value.teams, null)
              users  = try(permissions.value.users, null)
              policy = try(permissions.value.policy, null) == null ? null : jsonencode(permissions.value.policy)
            }
          }
        }
      }
      dynamic "event_trigger" {
        for_each = try(node.value.event_trigger, null) == null ? [] : [node.value.event_trigger]
        content {
          type                 = event_trigger.value.type
          blueprint_identifier = try(event_trigger.value.blueprint_identifier, null)
          property_identifier  = try(event_trigger.value.property_identifier, null)
          published            = try(event_trigger.value.published, true)
          dynamic "condition" {
            for_each = try(event_trigger.value.condition, null) == null ? [] : [event_trigger.value.condition]
            content {
              expressions = condition.value.expressions
              combinator  = try(condition.value.combinator, "and")
            }
          }
        }
      }
      dynamic "ai" {
        for_each = try(node.value.ai, null) == null ? [] : [node.value.ai]
        content {
          provider      = try(ai.value.provider, null)
          model         = try(ai.value.model, null)
          system_prompt = try(ai.value.system_prompt, null)
          user_prompt   = try(ai.value.user_prompt, null)
          tools         = try(ai.value.tools, null)
          output_schema = try(ai.value.output_schema, null)
          mcp_servers   = try(ai.value.mcp_servers, null)
        }
      }
      dynamic "webhook" {
        for_each = try(node.value.webhook, null) == null ? [] : [node.value.webhook]
        content {
          url             = try(webhook.value.url, null)
          method          = try(webhook.value.method, null)
          headers         = try(webhook.value.headers, null)
          body            = try(webhook.value.body, null) == null ? null : jsonencode(webhook.value.body)
          agent           = try(webhook.value.agent, null)
          synchronized    = try(webhook.value.synchronized, null)
          on_timeout      = try(webhook.value.on_timeout, null)
          on_failure      = try(webhook.value.on_failure, null)
          timeout_minutes = try(webhook.value.timeout_minutes, null)
        }
      }
      dynamic "integration_action" {
        for_each = try(node.value.integration_action, null) == null ? [] : [node.value.integration_action]
        content {
          installation_id             = integration_action.value.installation_id
          integration_provider        = integration_action.value.integration_provider
          integration_invocation_type = integration_action.value.integration_invocation_type
          execution_properties        = try(integration_action.value.execution_properties, null) == null ? null : jsonencode(integration_action.value.execution_properties)
          on_failure                  = try(integration_action.value.on_failure, null)
          timeout_minutes             = try(integration_action.value.timeout_minutes, null)
        }
      }
      dynamic "condition" {
        for_each = try(node.value.condition, null) == null ? [] : [node.value.condition]
        content {
          timeout_minutes = try(condition.value.timeout_minutes, null)
          dynamic "outlets" {
            for_each = condition.value.outlets
            content {
              identifier = outlets.value.identifier
              title      = try(outlets.value.title, null)
              expression = outlets.value.expression
              dynamic "status_label" {
                for_each = try(outlets.value.status_label, null) == null ? [] : [outlets.value.status_label]
                content {
                  text    = try(status_label.value.text, null)
                  variant = try(status_label.value.variant, null)
                }
              }
              dynamic "workflow_status_label" {
                for_each = try(outlets.value.workflow_status_label, null) == null ? [] : [outlets.value.workflow_status_label]
                content {
                  text    = try(workflow_status_label.value.text, null)
                  variant = try(workflow_status_label.value.variant, null)
                }
              }
            }
          }
        }
      }
      dynamic "schedule_trigger" {
        for_each = try(node.value.schedule_trigger, null) == null ? [] : [node.value.schedule_trigger]
        content {
          cron      = schedule_trigger.value.cron
          published = try(schedule_trigger.value.published, true)
        }
      }
      dynamic "workflow_trigger" {
        for_each = try(node.value.workflow_trigger, null) == null ? [] : [node.value.workflow_trigger]
        content {
          published = try(workflow_trigger.value.published, true)
        }
      }
      dynamic "execute_workflow" {
        for_each = try(node.value.execute_workflow, null) == null ? [] : [node.value.execute_workflow]
        content {
          workflow_identifier = execute_workflow.value.workflow_identifier
          trigger_identifier  = execute_workflow.value.trigger_identifier
          input               = try(execute_workflow.value.input, null) == null ? null : jsonencode(execute_workflow.value.input)
          wait                = try(execute_workflow.value.wait, null)
          on_failure          = try(execute_workflow.value.on_failure, null)
          timeout_minutes     = try(execute_workflow.value.timeout_minutes, null)
        }
      }
      dynamic "input" {
        for_each = try(node.value.input, null) == null ? [] : [node.value.input]
        content {
          description     = try(input.value.description, null)
          timeout_minutes = try(input.value.timeout_minutes, null)
          dynamic "responders" {
            for_each = try(input.value.responders, null) == null ? [] : [input.value.responders]
            content {
              roles       = try(responders.value.roles, null)
              teams       = try(responders.value.teams, null)
              users       = try(responders.value.users, null)
              users_query = try(responders.value.users_query, null) == null ? null : jsonencode(responders.value.users_query)
            }
          }
          dynamic "notifications" {
            for_each = try(input.value.notifications, [])
            content {
              target  = notifications.value.target
              url     = try(notifications.value.url, null)
              method  = try(notifications.value.method, null)
              agent   = try(notifications.value.agent, null)
              headers = try(notifications.value.headers, null)
              body    = try(notifications.value.body, null) == null ? null : jsonencode(notifications.value.body)
              dynamic "fields" {
                for_each = try(notifications.value.fields, [])
                content {
                  label = fields.value.label
                  value = fields.value.value
                }
              }
            }
          }
          dynamic "user_inputs" {
            for_each = try(input.value.user_inputs, null) == null ? [] : [input.value.user_inputs]
            content {
              buttons          = try(user_inputs.value.buttons, null)
              order_properties = try(user_inputs.value.order_properties, null)
              user_properties = try(user_inputs.value.user_properties, null) == null ? null : {
                string_props  = try(user_inputs.value.user_properties.string_props, null)
                number_props  = try(user_inputs.value.user_properties.number_props, null)
                boolean_props = try(user_inputs.value.user_properties.boolean_props, null)
                object_props  = try(user_inputs.value.user_properties.object_props, null)
                array_props   = try(user_inputs.value.user_properties.array_props, null)
              }
            }
          }
          dynamic "outlets" {
            for_each = input.value.outlets
            content {
              identifier        = outlets.value.identifier
              title             = try(outlets.value.title, null)
              num_of_responders = outlets.value.num_of_responders
              dynamic "status_label" {
                for_each = try(outlets.value.status_label, null) == null ? [] : [outlets.value.status_label]
                content {
                  text    = try(status_label.value.text, null)
                  variant = try(status_label.value.variant, null)
                }
              }
              dynamic "workflow_status_label" {
                for_each = try(outlets.value.workflow_status_label, null) == null ? [] : [outlets.value.workflow_status_label]
                content {
                  text    = try(workflow_status_label.value.text, null)
                  variant = try(workflow_status_label.value.variant, null)
                }
              }
            }
          }
        }
      }
      dynamic "upsert_entity" {
        for_each = try(node.value.upsert_entity, null) == null ? [] : [node.value.upsert_entity]
        content {
          blueprint_identifier = upsert_entity.value.blueprint_identifier
          on_failure           = try(upsert_entity.value.on_failure, "terminate")
          timeout_minutes      = try(upsert_entity.value.timeout_minutes, null)
          dynamic "mapping" {
            for_each = try(upsert_entity.value.mapping, null) == null ? [] : [upsert_entity.value.mapping]
            content {
              identifier = try(mapping.value.identifier, null)
              title      = try(mapping.value.title, null)
              icon       = try(mapping.value.icon, null)
              properties = try(mapping.value.properties, null) == null ? null : jsonencode(mapping.value.properties)
              relations  = try(mapping.value.relations, null) == null ? null : jsonencode(mapping.value.relations)
              teams      = try(mapping.value.teams, null)
            }
          }
        }
      }
    }
  }
  dynamic "connections" {
    for_each = var.connections
    content {
      source_identifier        = connections.value.source_identifier
      target_identifier        = connections.value.target_identifier
      source_outlet_identifier = try(connections.value.source_outlet_identifier, null)
      fallback                 = try(connections.value.fallback, null)
      description              = try(connections.value.description, null)
    }
  }
}