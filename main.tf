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
          url          = try(webhook.value.url, null)
          method       = try(webhook.value.method, null)
          headers      = try(webhook.value.headers, null)
          body         = try(webhook.value.body, null) == null ? null : jsonencode(webhook.value.body)
          agent        = try(webhook.value.agent, null)
          synchronized = try(webhook.value.synchronized, null)
          on_timeout   = try(webhook.value.on_timeout, null)
          on_failure   = try(webhook.value.on_failure, null)
        }
      }
      dynamic "upsert_entity" {
        for_each = try(node.value.upsert_entity, null) == null ? [] : [node.value.upsert_entity]
        content {
          blueprint_identifier = upsert_entity.value.blueprint_identifier
          on_failure           = try(upsert_entity.value.on_failure, "terminate")
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