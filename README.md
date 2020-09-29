English | [简体中文](README-CN.md)

<h1 align="center">alibabacloud-quickstart-sap-s4-hana</h1>

## Purpose

SAP automated tool “sap-s4-hana” create and configure basic cloud resources, S/4 HANA applications and HANA database, HSR(HANA System Replication), high-availability cluster,  optional RDP system and audit services in the same availability zone.


sap-s4-hana supports the following templates:

+ SAP S/4 HANA single node template(new VPC, existing VPC)
+ SAP S/4 HANA high availability template(new VPC, existing VPC)

sap-s4-hana supports the following S/4 HANA versions:
+ S/4 HANA 1709
+ S/4 HANA 1809
+ S/4 HANA 1909

View deployment guide please refer to the official website of Alibaba Cloud[《SAP 自动化安装部署最佳实践》](https://www.aliyun.com/acts/best-practice/preview?id=1934811)

## Directory Structure

```yaml
├──  sap-s4-hana-single-node # S/4 HANA single node
    ├── scripts # Scripts directory
    │   ├── sap_s4_hana_single_node.sh # S/4 HANA single node installation
    │   ├── sap_s4_hana_single_node_input_parameter.cfg # S/4 HANA parameter file
    ├── templates # ROS template directory
    │   ├── S4_HANA_Single_Node.json  # S/4 HANA single node basic template:Create ECS,security groups,RAM,etc cloud resources
    │   ├── New_VPC_S4_HANA_Single_Node.json # S/4 HANA single node new VPC template
    │   ├── New_VPC_S4_HANA_Single_Node_In.json # S/4 HANA single node new VPC template(English version)
    │   ├── Existing_VPC_S4_HANA_Single_Node.json # S/4 HANA single node existing VPC template
    │   ├── Existing_VPC_S4_HANA_Single_Node_In.json # S/4 HANA single node existing VPC template(English version)

├──  sap-s4-hana-ha  # S/4 HANA HA cluster
    ├── scripts # Scripts directory
    │   ├── sap_s4_hana_ha_node.sh # S/4 HANA HA installation script
    │   ├── corosync_configuration_template.cfg # Corosync configuration file
    │   ├── sap_s4_hana_ha_configuration_template.cfg # cluster resource configuration file
    │   ├── sap_s4_hana_ha_input_parameter.cfg # S/4 HANA HA installation parameter file
    ├── templates # ROS template directory
    │   ├── S4_HANA_HA.json  # S/4 HANA HA basic template:Create ECS,security groups,ENI,RAM,etc cloud resources
    │   ├── New_VPC_S4_HANA_HA.json # S/4 HANA HA new VPC template
    │   ├── New_VPC_S4_HANA_HA_In.json # S/4 HANA HA new VPC template(English version)
    │   ├── Existing_VPC_S4_HANA_HA.json # S/4 HANA HA existing VPC template
    │   ├── Existing_VPC_S4_HANA_HA_In.json # S/4 HANA HA existing VPC template(English version)
```

## Deployment architecture

Using SAP automated tool can deploy S/4 HANA high-availability cluster as below architecture in the same availability zone:

![sap-s4-hana-ha](https://img.alicdn.com/tfs/TB1E9b0lQ9l0K4jSZFKXXXFjpXa-1643-1826.png)
