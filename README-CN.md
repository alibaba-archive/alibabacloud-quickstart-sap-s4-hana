[English](README.md) | 简体中文

<h1 align="center">alibabacloud-quickstart-sap-s4-hana</h1>

## 用途

SAP自动化部署工具sap-s4-hana，在同一可用区内创建和配置基础云资源、S/4 HANA应用以及HANA数据库软件、HANA系统复制（HANA System Replication）、高可用集群以及可选的RDP系统和操作审计服务。


sap-s4-hana支持如下部署模板：

+ SAP S/4 HANA单节点模板（新建VPC、已有VPC）
+ SAP S/4 HANA双节点高可用集群模板（新建VPC、已有VPC）

sap-s4-hana支持如下S/4 HANA版本：
+ S/4 HANA 1709
+ S/4 HANA 1809
+ S/4 HANA 1909

详细的自动化部署最佳实践请参考阿里云官网[《SAP 自动化安装部署最佳实践》](https://www.aliyun.com/acts/best-practice/preview?id=1934811)

## 文件目录

```yaml
├──  sap-s4-hana-single-node # S/4 HANA单节点
    ├── scripts # 脚本目录
    │   ├── sap_s4_hana_single_node.sh # S/4 HANA单节点安装脚本
    │   ├── sap_s4_hana_single_node_input_parameter.cfg # S/4 HANA单节点安装脚本参数文件
    ├── templates # 资源编排(ROS)模板目录
    │   ├── S4_HANA_Single_Node.json  # S/4 HANA单节点基础模板：ECS、安全组、访问控制角色等云资源
    │   ├── New_VPC_S4_HANA_Single_Node.json # S/4 HANA单节点新建VPC模板
    │   ├── New_VPC_S4_HANA_Single_Node_In.json # S/4 HANA单节点新建VPC模板（国际站）
    │   ├── Existing_VPC_S4_HANA_Single_Node.json # S/4 HANA单节点已有VPC模板
    │   ├── Existing_VPC_S4_HANA_Single_Node_In.json # S/4 HANA单节点已有VPC模板（国际站）

├──  sap-s4-hana-ha  # S/4 HANA双节点高可用集群
    ├── scripts # 脚本目录
    │   ├── sap_s4_hana_ha_node.sh # S/4 HANA 双节点高可用安装脚本
    │   ├── corosync_configuration_template.cfg # Corosync配置文件
    │   ├── sap_s4_hana_ha_configuration_template.cfg # 集群resource配置文件
    │   ├── sap_s4_hana_ha_input_parameter.cfg # S/4 HANA双节点高可用安装脚本参数文件
    ├── templates # 资源编排(ROS)模板目录
    │   ├── S4_HANA_HA.json  # S/4 HANA双节点高可用基础模板：ECS、安全组、弹性网卡、访问控制角色等云资源
    │   ├── New_VPC_S4_HANA_HA.json # S/4 HANA双节点高可用新建VPC模板
    │   ├── New_VPC_S4_HANA_HA_In.json # S/4 HANA双节点高可用新建VPC模板（国际站）
    │   ├── Existing_VPC_S4_HANA_HA.json # S/4 HANA双节点高可用已有VPC模板
    │   ├── Existing_VPC_S4_HANA_HA_In.json # S/4 HANA双节点高可用已有VPC模板（国际站）
```

## 部署架构

使用SAP自动化部署工具在同一可用区内实现的S/4 HANA高可用集群架构图：

![sap-s4-hana-ha](https://img.alicdn.com/tfs/TB1E9b0lQ9l0K4jSZFKXXXFjpXa-1643-1826.png)
