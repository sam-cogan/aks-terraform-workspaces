
resource "azurerm_resource_group" "rg" {
  name     = var.aks_resource_group_name
  location = var.location

  tags = {
    environment = ${terraform.workspace}
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  address_space       = ["10.0.0.0/16"]





  tags = {
    environment = ${terraform.workspace}
  }
}


resource "azurerm_subnet" "aks_subnet" {
  name                 = "testsubnet"
  resource_group_name  = "${azurerm_resource_group.test.name}"
  virtual_network_name = "${azurerm_virtual_network.test.name}"
  address_prefix       = "10.0.1.0/24"



}

resource "azurerm_subnet" "aci_subet" {
    name           = "aci_subnet"
    address_prefix = "10.0.2.0/24"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"


  delegation {
    name = "aciDelegation"
    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}


module "aks" {
  source  = "app.terraform.io/samcogan/aks/samcogan"
    name = var.cluster_name
    environment = ${terraform.workspace}
    location = var.location
    vnet_resource_group = "${data.azurerm_resource_group.rg.name}"
    vnet_name = "${azurerm_virtual_network.vnet.name}"
    vnet_subnet = "${azurerm_virtual_network.aks_subnet.name}"
    aci_subnet_name = "${azurerm_virtual_network.aci_subnet.name}"
    acr_sku = var.acr_sku
    dns_prefix = var.cluster_name
    kubernetes_version = var.kubernetes_version
    count = var.node_count
    vm_size = var.vm_size
    max_pods = var.max_pods
    os_type = "Linux"
    os_disk_size_gb = "50"
    admin_username = "scadmin"
    cert_issuer_email = var.email
    aci_subnet_name = "${azurerm_virtual_network.aci_subnet.name}"
}