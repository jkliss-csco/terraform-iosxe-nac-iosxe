locals {
  static_routes = flatten([
    for device in local.devices : [
      for static_route in try(local.device_config[device.name].routing.static_routes, []) : {
        key         = format("%s/%s", device.name, static_route.name)
        device_name = device.name
        entries = [for e in try(static_route.entries, []) : {
          prefix      = try(e.prefix, local.defaults.iosxe.configuration.static_routes.standard.entries.prefix, null)
          mask        = try(e.mask, local.defaults.iosxe.configuration.static_routes.standard.entries.mask, null)
          next_hops   = try(e.next_hops, local.defaults.iosxe.configuration.static_routes.standard.entries.next_hops, null)
        }
        ]
      }
    ]
  ])
}

# Resource definition for configuring static routes on devices
resource "iosxe_static_route" "static_routes" {
  # Loop through each static route in the flattened list
  for_each = {
    for route in local.static_routes : route.key => route
  }

  device    = each.value.device_name
  prefix    = each.value.prefix
  mask      = each.value.mask
  next_hops = try(each.value.next_hops, null)
}
