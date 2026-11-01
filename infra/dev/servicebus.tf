# Service Bus namespace: container (address, keys, bill) for queues
resource "azurerm_servicebus_namespace" "sb" {
  name                = "sb-helios-${random_string.sfx.result}"   # globally unique name with our suffix
  location            = azurerm_resource_group.rg.location        # same region as everything else
  resource_group_name = azurerm_resource_group.rg.name            # lives in rg-helios-dev
  sku                 = "Basic"                                   # queues + DLQ, pay per operation (no topics; we use Event Hubs for fan-out)
  tags                = local.tags                                # same tags as the foundation
}

# The command queue: "do this once" jobs, e.g. schedule service
resource "azurerm_servicebus_queue" "service_requests" {
  name                                 = "service-requests"            # queue name senders use
  namespace_id                         = azurerm_servicebus_namespace.sb.id  # put it inside the namespace above
  max_delivery_count                   = 3                             # after 3 failed tries, move the message to the DLQ
  lock_duration                        = "PT10S"                       # worker gets 10 seconds (ISO time) before the message reappears; short for the lab
  dead_lettering_on_message_expiration = true                          # messages that expire unread also go to the DLQ, not silently vanish
}