#!/bin/bash
#################################################################################################################
# sap_s4_hana_ha.sh
# The script will setup cloud infrastructure,S/4 HANA software and configure HANA system replication, high availability
# Author: Alibaba Cloud, SAP Product & Solution Team
#################################################################################################################
#================================================================================================================
# Environments
QUICKSTART_SAP_MOUDLE='sap-s4-hana-ha'
QUICKSTART_SAP_MOUDLE_VERSION='1.0'
QUICKSTART_ROOT_DIR=$(cd $(dirname "$0" ) && pwd )
QUICKSTART_SAP_SCRIPT_DIR="${QUICKSTART_ROOT_DIR}"
QUICKSTART_FUNCTIONS_SCRIPT_PATH="${QUICKSTART_SAP_SCRIPT_DIR}/functions.sh"
QUICKSTART_LATEST_STEP=16

INFO=`cat <<EOF
    Please input Step number
    Index | Action                  | Description
    -----------------------------------------------
    1     | auto install            | Automatic setup cloud infrastructure, S/4 HANA software and configure HANA system replication, high availability
    2     | manual install          | Setup cloud infrastructure, S/4 HANA software and configure HANA system replication, high availability step by step
    3     | Exit                    |
EOF
`
STEP_INFO=`cat <<EOF
    Please input Step number
    Index | Action                  | Description
    -----------------------------------------------
    1     | add host                | Add hostname into hosts file
    2     | mkdisk                  | Create swap,physical volumes,volume group,logical volumes,file systems
    3     | download media          | Download SAP S/4 HANA software
    4     | extraction media        | Extraction SAP S/4 HANA software
    5     | install packages        | Install additional packages and metrics collector
    6     | config SSH              | Configure SSH
    7     | config ENI              | Configure elastic network card(ENI)
    8     | install ASCS            | Install ASCS software
    9     | install ERS             | Install ERS software
    10    | sync slave node         | Sync ASCS and ERS to slave node
    11    | install DB              | Install DB
    12    | config SBD/corosync     | Install and configure cluster SBD/corosync
    13    | config resource         | Configure cluster(resource)
    14    | validation              | Validation
    15    | install PAS             | Install PAS software
    16    | install AAS             | Install AAS software
    17    | Exit                    |
EOF
`

PARAMS=(
    MasterPass
    HANASID
    HANAInstanceNumber
    HANAMasterServerHostname
    HANASlaveServerHostname
    HANAMasterServerBusinessIpAddress
    HANASlaveServerBusinessIpAddress
    HANAMasterServerHeartbeatIpAddress
    HANASlaveServerHeartbeatIpAddress
    HANAHAVIPIpAddress
    ASCSHAVIPIpAddress
    ERSHAVIPIpAddress
    S4MasterServerHostname
    S4SlaveServerHostname
    S4MasterServerBusinessIpAddress
    S4SlaveServerBusinessIpAddress
    S4MasterServerHeartbeatIpAddress
    S4SlaveServerHeartbeatIpAddress
    SAPSID
    ASCSInstanceNumber
    ERSInstanceNumber
    PASInstanceNumber
    AASInstanceNumber
    MediaPath
    UsrsapSize
    S4SwapDiskSize
    DiskIdSwap
    DiskIdUsrSap
    SapmntNASDomain
    TransNASDomain
    HeartNetworkCard
    NodeType
    S4QuorumDisk
    S4SapSysGid
    S4SapSidAdmUid
    S4SapAdmUid
    FQDN
    ConditionInstallPASAAS
    AutomationBucketName
    ApplicationVersion
)


#==================================================================
#==================================================================
# Functions
#Define check_params function
#check_params
function check_params(){
    check_para MasterPass ${RE_PASSWORD}

    check_para HANASID ${RE_SID}
    check_para HANAInstanceNumber ${RE_INSTANCE_NUMBER}
    check_para HANAMasterServerHostname ${RE_HOSTNAME}
    check_para HANASlaveServerHostname ${RE_HOSTNAME}
    check_para HANAMasterServerBusinessIpAddress ${RE_IP}
    check_para HANASlaveServerBusinessIpAddress ${RE_IP}
    check_para HANAMasterServerHeartbeatIpAddress ${RE_IP}
    check_para HANASlaveServerHeartbeatIpAddress ${RE_IP}

    check_para HANAHAVIPIpAddress ${RE_IP}
    check_para ASCSHAVIPIpAddress ${RE_IP}
    check_para ERSHAVIPIpAddress ${RE_IP}

    check_para S4MasterServerBusinessIpAddress ${RE_IP}
    check_para S4SlaveServerBusinessIpAddress ${RE_IP}
    check_para S4MasterServerHeartbeatIpAddress ${RE_IP}
    check_para S4SlaveServerHeartbeatIpAddress ${RE_IP}
    check_para S4MasterServerHostname ${RE_HOSTNAME}
    check_para S4SlaveServerHostname ${RE_HOSTNAME}

    check_para SAPSID ${RE_SID}
    check_para ASCSInstanceNumber ${RE_INSTANCE_NUMBER}
    check_para ERSInstanceNumber ${RE_INSTANCE_NUMBER}
    check_para PASInstanceNumber ${RE_INSTANCE_NUMBER}
    check_para AASInstanceNumber ${RE_INSTANCE_NUMBER}
    check_para UsrsapSize ${RE_DISK}
    [[ -n "${S4SwapDiskSize}" ]] && check_para S4SwapDiskSize ${RE_DISK}

    check_para SapmntNASDomain ".*nas\.aliyuncs\.com$"
    check_para TransNASDomain ".*nas\.aliyuncs\.com$"
    check_para HeartNetworkCard "^\S{1,}$"
    check_para NodeType "^(Master|Slave)$"
    check_para S4QuorumDisk "^vd[b-z]$"

    check_para FQDN '(?!-)[a-zA-Z0-9-.]*(?<!-)'
    check_para MediaPath "^(oss|http|https)://[\\S\\w]+([\\S\\w])+$"
    check_para S4SapSidAdmUid "(^\\d+$)"
    check_para S4SapAdmUid "(^\\d+$)"
    check_para S4SapSysGid '^(?!1001$)\d+$'
    check_para ConditionInstallPASAAS "^(True|False)$"
    check_para ApplicationVersion '^S/4 HANA (1909|1809)$'
}

#Define init_variable function
#init_variable 
function init_variable(){
    case "$ApplicationVersion" in
    "S/4 HANA 1909")
        ASCS_PRODUCT_ID="NW_ABAP_ASCS:S4HANA1909.CORE.HDB.ABAPHA"
        ERS_PRODUCT_ID="NW_ERS:S4HANA1909.CORE.HDB.ABAPHA"
        DB_PRODUCT_ID="NW_ABAP_DB:S4HANA1909.CORE.HDB.ABAPHA"
        PAS_PRODUCT_ID="NW_ABAP_CI:S4HANA1909.CORE.HDB.ABAPHA"
        AAS_PRODUCT_ID="NW_DI:S4HANA1909.CORE.HDB.PD"
        ;;
    "S/4 HANA 1809")
        ASCS_PRODUCT_ID="NW_ABAP_ASCS:S4HANA1809.CORE.HDB.ABAPHA"
        ERS_PRODUCT_ID="NW_ERS:S4HANA1809.CORE.HDB.ABAPHA"
        DB_PRODUCT_ID="NW_ABAP_DB:S4HANA1809.CORE.HDB.ABAPHA"
        PAS_PRODUCT_ID="NW_ABAP_CI:S4HANA1809.CORE.HDB.ABAPHA"
        AAS_PRODUCT_ID="NW_DI:S4HANA1809.CORE.HDB.PD"
        ;;
    esac
    MediaPath_SWPM="http://sap-automation-${QUICKSTART_SAP_REGION}.oss-${QUICKSTART_SAP_REGION}.aliyuncs.com/alibabacloud-quickstart/packages/SWPM2.0sp05.zip"
    SAPSIDAdm=$(echo "$SAPSID" |tr '[:upper:]' '[:lower:]')"adm"
    HANASIDAdm=$(echo "$HANASID" |tr '[:upper:]' '[:lower:]')"adm"
    ASCSHostname="VASCS${SAPSID}"
    ERSHostname="VERS${SAPSID}"
    DBHostname="VDB${HANASID}"
    PASHostname="${S4MasterServerHostname}"
    AASHostname="${S4SlaveServerHostname}"
    MediaPath_SWPM="http://sap-automation-${QUICKSTART_SAP_REGION}.oss-${QUICKSTART_SAP_REGION}.aliyuncs.com/alibabacloud-quickstart/packages/SWPM2.0sp05.zip"
    ResourceAgentsUrl="http://sap-automation-${QUICKSTART_SAP_REGION}.oss-${QUICKSTART_SAP_REGION}.aliyuncs.com/alibabacloud-quickstart/packages/resource-agents-4.1.9%2Bgit24.9b664917-1.3.x86_64.rpm"
    ClusterConnectorUrl="http://sap-automation-${QUICKSTART_SAP_REGION}.oss-${QUICKSTART_SAP_REGION}.aliyuncs.com/alibabacloud-quickstart/packages/sap-suse-cluster-connector-3.1.0-8.1.noarch.rpm"
    CorosyncConfigurationTemplateURL="http://${AutomationBucketName}.oss-$QUICKSTART_SAP_REGION.aliyuncs.com/alibabacloud-quickstart/v1/sap-s4-hana/sap-s4-hana-ha/scripts/corosync_configuration_template.cfg"
    CorosyncConfigurationTemplatePath="${QUICKSTART_SAP_SCRIPT_DIR}/template_corosync_configuration.cfg"
    ResourcesConfigurationTemplateURL="http://${AutomationBucketName}.oss-${QUICKSTART_SAP_REGION}.aliyuncs.com/alibabacloud-quickstart/v1/sap-s4-hana/sap-s4-hana-ha/scripts/sap_s4_hana_ha_configuration_template.cfg"
    ResourcesConfigurationTemplatePath="${QUICKSTART_SAP_SCRIPT_DIR}/template_SAP_S4_HANA_HA_configuration.cfg"
    ResourcesConfigurationFilePath="${QUICKSTART_SAP_SCRIPT_DIR}/SAP_S4_HANA_HA_configuration_file.cfg"

    TAR_NAME_SW=$(expr "${MediaPath_SWPM}" : '.*/\(.*\(zip\|tar\.gz\|tgz\|tar\.bz2\|tar\)\).*')
}

#Define add_host function
#add_host 
function add_host() {
    info_log "Now adding host file"
    config_host "${HANAMasterServerBusinessIpAddress} ${HANAMasterServerHostname}"
    config_host "${HANAMasterServerHeartbeatIpAddress} ${HANAMasterServerHostname}-ha"
    config_host "${HANASlaveServerBusinessIpAddress} ${HANASlaveServerHostname}"
    config_host "${HANASlaveServerHeartbeatIpAddress} ${HANASlaveServerHostname}-ha"

    config_host "${S4MasterServerBusinessIpAddress} ${S4MasterServerHostname} ${S4MasterServerHostname}.${FQDN}"
    config_host "${S4MasterServerHeartbeatIpAddress} ${S4MasterServerHostname}-ha"
    config_host "${S4SlaveServerBusinessIpAddress} ${S4SlaveServerHostname} ${S4SlaveServerHostname}.${FQDN}"
    config_host "${S4SlaveServerHeartbeatIpAddress} ${S4SlaveServerHostname}-ha"

    config_host "${HANAHAVIPIpAddress} ${DBHostname} ${DBHostname}.${FQDN}"
    config_host "${ASCSHAVIPIpAddress} ${ASCSHostname} ${ASCSHostname}.${FQDN}"
    config_host "${ERSHAVIPIpAddress} ${ERSHostname} ${ERSHostname}.${FQDN}"
    info_log "Added host file successfule"
}

#Define check_filesystem function
function check_filesystem() {
    info_log "Start to check SAP file systems"
    df -h | grep -q "/usr/sap" || { error_log "/usr/sap not mounted"; return 1; }
    info_log "Both SAP relevant file systems have been mounted successful"
}

#Define mkdisk function
#mkdisk
function mkdisk() {
    info_log "Start to create swap,physical volumes,volume group,logical volumes,file systems " 
    check_disks $DiskIdUsrSap $DiskIdSwap || return 1

    disk_id_usr_sap="/dev/${DiskIdUsrSap}"
    disk_size_usr_sap="${UsrsapSize}"
    disk_id_swap="/dev/${DiskIdSwap}"

    mk_swap ${disk_id_swap} || return 1

    pvcreate ${disk_id_usr_sap} || return 1 
    vgcreate sapvg ${disk_id_usr_sap} || return 1
    create_lv ${disk_size_usr_sap} usrsaplv sapvg "free"

    mkfs.xfs -f /dev/sapvg/usrsaplv || return 1 
    mkdir -p /usr/sap || return 1
    $(grep -q /dev/sapvg/usrsaplv ${ETC_FSTAB_PATH}) || echo "/dev/sapvg/usrsaplv        /usr/sap  xfs defaults       0 0" >> ${ETC_FSTAB_PATH}

    mount -a
    check_filesystem || return 1
    info_log "Swap,physical volumes,volume group,logical volumes,file systems have been created successful"
}

#Define check_extraction function
#extraction
function check_extraction {
    info_log "Start to check extraction"
    Kernel_Path=${QUICKSTART_SAP_DOWNLOAD_DIR}"/"
    Hanaclient_Path=`find $QUICKSTART_SAP_EXTRACTION_DIR -regex .*DATA_UNITS/HDB_CLIENT_LINUX_X86_64 | tail -1`"/"
    Export_Path=`find $QUICKSTART_SAP_EXTRACTION_DIR -regex .*DATA_UNITS/EXPORT_11`
    Export_Path="${Export_Path%EXPORT_11}"

    if [[ ! $(cat ${Export_Path}LABELIDX.ASC | wc -l) -eq 11 ]];then 
        error_log "invalid file(${TAR_NAME_EX})"
        return 1 ;
    fi
    info_log "Start to check HANA_Client decompressed files."
    if [[ ! $(cat ${Hanaclient_Path}LABEL.ASC | grep "HDB_CLIENT" |wc -l ) -eq 1 ]];then 
        error_log "invalid file(${TAR_NAME_CL})"
        return 1;
    fi
    info_log "Start to check SAP_S4_HANA_Kernel decompressed files."
    if [[ ! $(ls ${Kernel_Path} | grep -E "(igsexe[0-9_-]+.sar)|(igshelper[0-9_-]+.sar)|(SAPEXE[0-9_-]+.SAR)|(SAPEXEDB[0-9_-]+.SAR)|(SAPHOSTAGENT[0-9_-]+.SAR)$" |wc -l) -eq 5 ]];then 
        error_log "invalid file(${TAR_NAME_KN})"
        return 1 ;
    fi
    info_log "SAP S/4 HANA software have been extracted successful,ready to install"
}

#Define config_havip function
#config_havip index ip_address label
function config_havip() {
    info_log "Start to config havip(${3})"
    local cidr=`curl http://100.100.100.200/latest/meta-data/vswitch-cidr-block 2>/dev/null` 
    cidr="${cidr##*/}"
    cat << EOF >> "${CONFIG_ETH0_PATH}"
IPADDR_${1}='${2}/${cidr}'
LABEL_${1}='${3}'
EOF
    service network restart
}

#Define detach_havip function
#detach_havip
function detach_havip() {
    info_log "Start to  detach HaVip"
    local cidr=`curl http://100.100.100.200/latest/meta-data/vswitch-cidr-block 2>/dev/null` 
    cidr="${cidr##*/}"
    sed -i "/IPADDR_[01]=.*/d" "${CONFIG_ETH0_PATH}"
    sed -i "/LABEL_[01]=.*/d" "${CONFIG_ETH0_PATH}"
    service network restart
}

#Define install_ASCS function
#install_ASCS
function install_ASCS() {
    info_log "Start to install S/4 ASCS"
    sapinst_path=${QUICKSTART_SAP_EXTRACTION_DIR}"/${TAR_NAME_SW%.*}/"
    media_path=${QUICKSTART_SAP_DOWNLOAD_DIR}"/"
    local sap_ASCS_install_template_path="${QUICKSTART_SAP_SCRIPT_DIR}/SAP_S4_HANA_HA_install_ASCS_template.params"
    cat << EOF > ${sap_ASCS_install_template_path}
NW_Delete_Sapinst_Users.removeUsers = true
NW_GetMasterPassword.masterPwd = ${MasterPass}
NW_GetSidNoProfiles.sid = ${SAPSID}
NW_SCS_Instance.instanceNumber = ${ASCSInstanceNumber}
NW_SCS_Instance.scsVirtualHostname = ${ASCSHostname}
NW_getFQDN.FQDN = ${FQDN}
archives.downloadBasket = ${media_path}
hostAgent.sapAdmPassword = ${MasterPass}
nwUsers.sapsysGID = ${S4SapSysGid}
nwUsers.sidAdmUID = ${S4SapSidAdmUid}
nwUsers.sidadmPassword = ${MasterPass}
EOF
    cd "${sapinst_path}" && ./sapinst SAPINST_USE_HOSTNAME=${ASCSHostname} SAPINST_INPUT_PARAMETERS_URL="${sap_ASCS_install_template_path}" SAPINST_EXECUTE_PRODUCT_ID=${ASCS_PRODUCT_ID} SAPINST_SKIP_DIALOGS=true SAPINST_START_GUISERVER=false  >/dev/null || return 1
    info_log "Finished S/4 ASCS installation" 
}

#Define install_ERS function
#install_ERS
function install_ERS() {
    info_log "Start to install S/4 ERS"
    sapinst_path=${QUICKSTART_SAP_EXTRACTION_DIR}"/${TAR_NAME_SW%.*}/"
    media_path=${QUICKSTART_SAP_DOWNLOAD_DIR}"/"
    local sap_ERS_install_template_path="${QUICKSTART_SAP_SCRIPT_DIR}/SAP_S4_HANA_HA_install_ERS_template.params"

    cat << EOF > ${sap_ERS_install_template_path}
NW_Delete_Sapinst_Users.removeUsers = true
archives.downloadBasket = ${media_path}
nwUsers.sapsysGID = ${S4SapSysGid}
nwUsers.sidAdmUID = ${S4SapSidAdmUid}
nw_instance_ers.ersInstanceNumber = ${ERSInstanceNumber}
nw_instance_ers.ersVirtualHostname = ${ERSHostname}
NW_readProfileDir.profileDir = /sapmnt/${SAPSID}/profile
EOF
    cd "${sapinst_path}" && ./sapinst SAPINST_USE_HOSTNAME=${ERSHostname} SAPINST_INPUT_PARAMETERS_URL="${sap_ERS_install_template_path}" SAPINST_EXECUTE_PRODUCT_ID=${ERS_PRODUCT_ID} SAPINST_SKIP_DIALOGS=true SAPINST_START_GUISERVER=false  >/dev/null || return 1
    info_log "Finished S/4 ERS installation" 
}

#Define install_DB function
#install_DB
function install_DB() {
    info_log "Start to install S/4 DB"
    sapinst_path=${QUICKSTART_SAP_EXTRACTION_DIR}"/${TAR_NAME_SW%.*}/"
    media_path=${QUICKSTART_SAP_DOWNLOAD_DIR}"/"
    local sap_DB_install_template_path="${QUICKSTART_SAP_SCRIPT_DIR}/SAP_S4_HANA_HA_install_DB_template.params"
    cat << EOF > ${sap_DB_install_template_path}
HDB_Schema_Check_Dialogs.schemaPassword = ${MasterPass}
HDB_Schema_Check_Dialogs.validateSchemaName = false
NW_Delete_Sapinst_Users.removeUsers = true
NW_GetMasterPassword.masterPwd = ${MasterPass}
HDB_Userstore.doNotResolveHostnames = ${DBHostname}
NW_HDB_DB.abapSchemaPassword = ${MasterPass}
NW_HDB_getDBInfo.dbhost = ${DBHostname}
NW_HDB_getDBInfo.dbsid = ${HANASID}
NW_HDB_getDBInfo.instanceNumber = ${HANAInstanceNumber}
NW_HDB_getDBInfo.systemDbPassword = ${MasterPass}
NW_HDB_getDBInfo.systemPassword = ${MasterPass}
NW_Recovery_Install_HDB.extractLocation = 
NW_Recovery_Install_HDB.extractParallelJobs = 19
NW_Recovery_Install_HDB.sidAdmName = ${HANASIDAdm}
NW_Recovery_Install_HDB.sidAdmPassword = ${MasterPass}
NW_System.installSAPHostAgent = false
NW_getLoadType.loadType = SAP
NW_readProfileDir.profileDir = /sapmnt/${SAPSID}/profile
archives.downloadBasket = ${media_path}
nwUsers.sapsysGID = ${S4SapSysGid}
nwUsers.sidAdmUID = ${S4SapSidAdmUid}
storageBasedCopy.hdb.instanceNumber = ${HANAInstanceNumber}
storageBasedCopy.hdb.systemPassword = ${MasterPass}
EOF
    cd "${sapinst_path}" && ./sapinst SAPINST_USE_HOSTNAME=${DBHostname} SAPINST_INPUT_PARAMETERS_URL="${sap_DB_install_template_path}" SAPINST_EXECUTE_PRODUCT_ID=${DB_PRODUCT_ID} SAPINST_SKIP_DIALOGS=true SAPINST_START_GUISERVER=false  >/dev/null || return 1
    info_log "Finished S/4 DB installation" 
}

#Define install_PAS function
#install_PAS
function install_PAS() {
    info_log "Start to install S/4 PAS"
    sapinst_path=${QUICKSTART_SAP_EXTRACTION_DIR}"/${TAR_NAME_SW%.*}/"
    media_path=${QUICKSTART_SAP_DOWNLOAD_DIR}"/"
    local sap_PAS_install_template_path="${QUICKSTART_SAP_SCRIPT_DIR}/SAP_S4_HANA_HA_install_PAS_template.params"
    cat << EOF > ${sap_PAS_install_template_path}
NW_Delete_Sapinst_Users.removeUsers = true
NW_GetSidNoProfiles.sid = ${SAPSID}
hostAgent.sapAdmPassword = ${MasterPass}
NW_GetMasterPassword.masterPwd = ${MasterPass}
NW_getLoadType.loadType = SAP
NW_readProfileDir.profileDir = /sapmnt/${SAPSID}/profile
archives.downloadBasket = ${media_path}
nwUsers.sapsysGID = ${S4SapSysGid}
nwUsers.sidAdmUID = ${S4SapSidAdmUid}
nwUsers.sidadmPassword = ${MasterPass}
NW_HDB_getDBInfo.systemDbPassword = ${MasterPass}
storageBasedCopy.hdb.instanceNumber = ${HANAInstanceNumber}
storageBasedCopy.hdb.systemPassword = ${MasterPass}
NW_CI_Instance.ciInstanceNumber = ${PASInstanceNumber}
NW_CI_Instance.ciVirtualHostname = ${PASHostname}
EOF
    cd "${sapinst_path}" && ./sapinst SAPINST_INPUT_PARAMETERS_URL="${sap_PAS_install_template_path}" SAPINST_EXECUTE_PRODUCT_ID=${PAS_PRODUCT_ID} SAPINST_SKIP_DIALOGS=true SAPINST_START_GUISERVER=false  >/dev/null || return 1
    info_log "Finished S/4 PAS installation" 
}

#Define install_AAS function
#install_AAS
function install_AAS() {
    info_log "Start to install S/4 AAS"
    sapinst_path=${QUICKSTART_SAP_EXTRACTION_DIR}"/${TAR_NAME_SW%.*}/"
    media_path=${QUICKSTART_SAP_DOWNLOAD_DIR}"/"
    local sap_AAS_install_template_path="${QUICKSTART_SAP_SCRIPT_DIR}/SAP_S4_HANA_HA_install_AAS_template.params"
    cat << EOF > ${sap_AAS_install_template_path}
NW_Delete_Sapinst_Users.removeUsers = true
NW_GetSidNoProfiles.sid = ${SAPSID}
hostAgent.sapAdmPassword = ${MasterPass}
NW_GetMasterPassword.masterPwd = ${MasterPass}
NW_getLoadType.loadType = SAP
NW_readProfileDir.profileDir = /sapmnt/${SAPSID}/profile
archives.downloadBasket = ${media_path}
nwUsers.sapsysGID = ${S4SapSysGid}
nwUsers.sidAdmUID = ${S4SapSidAdmUid}
nwUsers.sidadmPassword = ${MasterPass}
NW_HDB_getDBInfo.systemDbPassword = ${MasterPass}
storageBasedCopy.hdb.instanceNumber = ${HANAInstanceNumber}
storageBasedCopy.hdb.systemPassword = ${MasterPass}
NW_AS.instanceNumber = ${AASInstanceNumber}
NW_DI_Instance.virtualHostname = ${AASHostname}
NW_getFQDN.FQDN = ${FQDN}
NW_HDB_getDBInfo.instanceNumber = ${HANAInstanceNumber}
HDB_Schema_Check_Dialogs.schemaPassword = ${MasterPass}
EOF
    scp -pr "${sap_AAS_install_template_path}" root@${S4SlaveServerHostname}:${sap_AAS_install_template_path} >/dev/null
    run_cmd_remote "${S4SlaveServerHostname}" "cd ${sapinst_path} && ./sapinst SAPINST_INPUT_PARAMETERS_URL=${sap_AAS_install_template_path} SAPINST_EXECUTE_PRODUCT_ID=${AAS_PRODUCT_ID} SAPINST_SKIP_DIALOGS=true SAPINST_START_GUISERVER=false  >/dev/null" || return 1
    info_log "Finished S/4 AAS installation" 
}

#Define sync_slave function
#sync_slave file_path
function sync_slave() {
    info_log "Start to sync ASCS and ERS"
    ssh root@"${S4SlaveServerHostname}" "groupadd -g ${S4SapSysGid} sapsys"
    ssh root@"${S4SlaveServerHostname}" "useradd -g sapsys -u ${S4SapSidAdmUid} ${SAPSIDAdm}"
    ssh root@"${S4SlaveServerHostname}" "useradd -g sapsys -u ${S4SapAdmUid} sapadm"
    ssh root@"${S4SlaveServerHostname}" "echo ${MasterPass} | sudo passwd sapadm --stdin  &>/dev/null"
    ssh root@"${S4SlaveServerHostname}" "echo ${MasterPass} | sudo passwd ${SAPSIDAdm} --stdin  &>/dev/null"
    cd /home && tar -cf ${QUICKSTART_SAP_SCRIPT_DIR}/Home.tar * 
    scp -pr ${QUICKSTART_SAP_SCRIPT_DIR}/Home.tar root@${S4SlaveServerHostname}:/home/ >/dev/null
    ssh root@${S4SlaveServerHostname} "cd /home; tar -xf Home.tar" 
    ssh root@"${S4SlaveServerHostname}" "cd /home/${SAPSIDAdm}; for file in \$(ls .*${S4MasterServerHostname}.*); do mv \$file \${file//${S4MasterServerHostname}/${S4SlaveServerHostname}}; done"
    scp -pr /etc/services root@${S4SlaveServerHostname}:/etc/ >/dev/null
    scp -pr /usr/sap/sapservices root@${S4SlaveServerHostname}:/usr/sap/ >/dev/null
    cd /usr/sap/${SAPSID} && tar -cf ${QUICKSTART_SAP_SCRIPT_DIR}/ASCSERSSYS.tar * 
    ssh root@${S4SlaveServerHostname} "mkdir -p /usr/sap/${SAPSID}"
    ssh root@${S4SlaveServerHostname} "chmod 755 /usr/sap/${SAPSID}"
    scp -pr ${QUICKSTART_SAP_SCRIPT_DIR}/ASCSERSSYS.tar root@${S4SlaveServerHostname}:/usr/sap/${SAPSID}/ >/dev/null
    ssh root@${S4SlaveServerHostname} "cd /usr/sap/${SAPSID}; tar -xf ASCSERSSYS.tar"
    ssh root@${S4SlaveServerHostname} "usermod -a -G haclient ${SAPSIDAdm}"
}

#Define config_cluster_connector function
#config_cluster_connector file_path
function config_cluster_connector() {
    local file_path="${1}"
    sed -i '$aservice/halib = $(DIR_CT_RUN)/saphascriptco.so' ${file_path}
    sed -i '$aservice/halib_cluster_connector = /usr/bin/sap_suse_cluster_connector' ${file_path}
}

#Define config_ASCS function
#config_ASCS
function config_ASCS() {
    info_log "Start to config ASCS"
    usermod -a -G haclient "${SAPSIDAdm}"
    config_cluster_connector "/sapmnt/${SAPSID}/profile/${SAPSID}_ASCS${ASCSInstanceNumber}_${ASCSHostname}"
    su - "${SAPSIDAdm}" -c "sapcontrol -nr ${ASCSInstanceNumber} -function StartService ${SAPSID}"
    su - "${SAPSIDAdm}" -c "sapcontrol -nr ${ASCSInstanceNumber} -function Start"
}

#Define config_ERS function
#config_ERS
function config_ERS() {
    info_log "Start to config ERS"
    usermod -a -G haclient "${SAPSIDAdm}"
    config_cluster_connector "/sapmnt/${SAPSID}/profile/${SAPSID}_ERS${ERSInstanceNumber}_${ERSHostname}"
    su - "${SAPSIDAdm}" -c "sapcontrol -nr ${ERSInstanceNumber} -function StartService ${SAPSID}"
    su - "${SAPSIDAdm}" -c "sapcontrol -nr ${ERSInstanceNumber} -function Start"
}

#Define validation function
#validation
function _package_install() {
    info_log "Start to check version of resource-agents and sap_suse_cluster_connector"
    res_version="$(rpm -qa resource-agents)"
    
    if `version_lt ${res_version} "resource-agents-4.0.2    "`; then
        info_log "resource-agents version: ${res_version}, update resource-agents"
        download "${ResourceAgentsUrl}" "resource_agent.rpm" || return 1
        rpm -Uvh ${QUICKSTART_SAP_DOWNLOAD_DIR}/resource_agent.rpm
    fi
    con_version="$(rpm -qa sap-suse-cluster-connector)"
    
    if `version_lt "${con_version}" "sap-suse-cluster-connector-3.1.0"`; then
        info_log "sap-suse-cluster-connector version: ${con_version}, update sap-suse-cluster-connector"
        download "${ClusterConnectorUrl}" "connector.rpm" || return 1
        rpm -e sap_suse_cluster_connector 2>/dev/null
        rpm -Uvh ${QUICKSTART_SAP_DOWNLOAD_DIR}/connector.rpm
    fi
}

#Define corosync configuration function
#corosync_config
function corosync_config(){
    info_log "Start to configure corosync"
    wget -nv "${CorosyncConfigurationTemplateURL}" -O "${CorosyncConfigurationTemplatePath}"
    if [ $? -ne 0 ];then
        error_log "Download corosync configuration template failed url:${corosync_url}"
        return 1
    fi
    content=$(cat ${CorosyncConfigurationTemplatePath})
    eval "cat <<EOF
    $content
EOF"  > /etc/corosync/corosync.conf 
    scp /etc/corosync/corosync.conf "${S4SlaveServerHostname}":/etc/corosync/corosync.conf || { error_log "Sync corosync.conf file failed"; return 1; }
    info_log "Corosync configuration has been finished sucessful"
}

#Define Resource configuration function
#resource_config
function resource_config(){
    info_log "Start to configure HA resource agent"
    wget -nv "${ResourcesConfigurationTemplateURL}" -O "${ResourcesConfigurationTemplatePath}"
    if [ $? -ne 0 ];then
        error_log "Download HANA HA configuration template failed url:${ha_config_url}"
        return 1
    fi
    id='$id'
    content=$(cat ${ResourcesConfigurationTemplatePath})
    eval "cat <<EOF
    ${content//\\/\\\\}
EOF"  > "${ResourcesConfigurationFilePath}"
    systemctl start pacemaker || { error_log "Start pacemaker failed"; return 1; }
    ssh ${S4SlaveServerHostname} "systemctl start pacemaker" 
    crm configure load update "${ResourcesConfigurationFilePath}"
    if [ $? -ne 0 ];then
        error_log "crm load template failed"
        return 1
    fi
    info_log "HA resource agent configuration have been finished sucessful"
}

# Define setup_nas function
# setup_nas 
function setup_nas(){
    info_log "Start to config NAS"
    mkdir -p /sapmnt
    mkdir -p /usr/sap/trans
    config_nas "${SapmntNASDomain}" "/sapmnt"
    config_nas "${TransNASDomain}" "/usr/sap/trans"
    systemctl start autofs || return 1
    systemctl enable autofs || return 1
}

#Define validation_instance function
#validation_instance sidadm instance_number hostname
function validation_instance() {
    sid_adm="$1"
    instance_number="$2"
    hostname_="$3"
    info_log "Now checking instance(${instance_number}) running status"
    if [[ -n "${hostname_}" ]]; then
        command="sapcontrol -nr ${instance_number} -function GetProcessList"
        ssh root@${hostname_} "su - ${sid_adm} -c \"${command}\""
    else
        su - "${sid_adm}" -c "sapcontrol -nr ${instance_number} -function GetProcessList" > /dev/null 2>&1
    fi
    
    indexserver=$?
    if [ "$indexserver" == '3' ];
    then
        info_log "Instance(${instance_number}) is running"
    else
        error_log "Instance(${instance_number}) status is unknown"; return 1
    fi
}

#Define res_validation function
# res_validation res re_str
function res_validation(){
    res=$1
    re_str=$2
    for num in $(seq 1 20)
    do 
        crm_mon -1 | grep -P "${re_str}" >/dev/null 2>&1 && return 0
        sleep 1m
    done
    warning_log "Resource ${res} validate failed"
    return 1
}

#Define HA_validation function
function HA_validation(){
    info_log "Start to validate SAP S/4 HANA HA"
    res_validation "stonith-sbd" "stonith-sbd.*Started" || return 1
    res_validation "ASCS HaVip" "rsc_ip_${SAPSID}_ASCS${ASCSInstanceNumber}.*Started" || return 1
    res_validation "rsc_sap_${SAPSID}_ASCS${ASCSInstanceNumber}" "rsc_sap_${SAPSID}_ASCS${ASCSInstanceNumber}.*Started" || return 1
    res_validation "ERS HaVip" "rsc_ip_${SAPSID}_ERS${ERSInstanceNumber}.*Started" || return 1
    res_validation "rsc_sap_${SAPSID}_ERS${ERSInstanceNumber}" "rsc_sap_${SAPSID}_ERS${ERSInstanceNumber}.*Started" || return 1
    res_validation "{S4MasterServerHostname} or ${S4SlaveServerHostname}" "Online: \[ ${S4MasterServerHostname} ${S4SlaveServerHostname} \]" || return 1
    return 0
}

# Define setup function
# run step
function run(){
    case "$1" in
        1)
            add_host
            ;;
        2)
            mkdisk || return 1
            setup_nas  || return 1
            check_filesystem || return 1
            ;;
        3)
            mkdir -p "${QUICKSTART_SAP_DOWNLOAD_DIR}"
            download_medias "${MediaPath}" || return 1
            download "${MediaPath_SWPM}" "${TAR_NAME_SW}" || return 1
            ;;
        4)
            auto_extraction "${QUICKSTART_SAP_DOWNLOAD_DIR}/${TAR_NAME_SW}" || return 1
            chmod -R 777 "${QUICKSTART_SAP_DOWNLOAD_DIR}"/*
            ;;
        5)
            HA_packages || return 1
            _package_install || return 1
            APP_post
            ;;
        6)
            if [[ "${NodeType}" == "Master" ]];then
                cluster_member_hostname="${S4SlaveServerHostname}"
            else 
                cluster_member_hostname="${S4MasterServerHostname}"
            fi
            ssh_setup "${cluster_member_hostname}" "root" "${LoginPassword}" || return 1
            info_log "Configure SSH trust successful"
            ;;
        7)  
            if [[ "${NodeType}" == "Master" ]];then
                ip_address="${S4MasterServerHeartbeatIpAddress}"
                config_havip "0" "${ASCSHAVIPIpAddress}" "TempASCS" || return 1
                config_havip "1" "${ERSHAVIPIpAddress}" "TempERS" || return 1
            else
                ip_address="${S4SlaveServerHeartbeatIpAddress}"
            fi
            config_eni "${ip_address}" "${HeartNetworkCard}" || return 1
            info_log "Bind elastic network card successful"
            ;;
        8)
            if [[ "${NodeType}" == "Master" ]];then
                install_ASCS || return 1
                validation_instance "${SAPSIDAdm}" "${ASCSInstanceNumber}" || return 1
                config_ASCS
            fi
            ;;
        9)
            if [[ "${NodeType}" == "Master" ]];then
                install_ERS || return 1
                validation_instance "${SAPSIDAdm}" "${ERSInstanceNumber}" || return 1
                config_ERS
            fi
            ;;
        10)
            if [[ "${NodeType}" == "Master" ]];then
                sync_slave || return 1
            fi
            ;;
        11)
            if [[ "${NodeType}" == "Master" ]];then
                wait_HANA_ECS "${HANAHAVIPIpAddress}" "${HANAInstanceNumber}" || return 1
                install_DB || return 1
            fi
            ;;
        12)
            if [[ "${NodeType}" == "Master" ]];then
                corosync_config || return 1
            fi
            sbd_config "${S4QuorumDisk}" || return 1
            ;;
        13)
            if [[ "${NodeType}" == "Master" ]];then
                resource_config || return 1
                detach_havip 
            fi
            ;;
        14)
            start_hawk "${MasterPass}"
            if [[ "${NodeType}" == "Master" ]];then
                HA_validation || return 1
            fi
            ;;
        15)
            if [[ "${NodeType}" == "Master" && "${ConditionInstallPASAAS}" == "True" ]];then
                install_PAS
                validation_instance "${SAPSIDAdm}" "${PASInstanceNumber}" || warning_log "Install PAS failed"
            fi
            ;;
        16)
            if [[ "${NodeType}" == "Master" && "${ConditionInstallPASAAS}" == "True" ]];then
                install_AAS
                validation_instance "${SAPSIDAdm}" "${AASInstanceNumber}" "${S4SlaveServerHostname}"
                if [[ $? -eq 0 ]]
                then
                    ssh ${S4SlaveServerHostname} "rm -rf ${QUICKSTART_SAP_DOWNLOAD_DIR}"
                else
                    warning_log "Install AAS failed"
                fi
            elif [[ "${NodeType}" == "Slave" && "${ConditionInstallPASAAS}" == "True" ]];then
                SAP_CLEAN_LEVEL="1"
            fi
            ;;
        *)
            error_log "Can't match Mark value,please check whether modify the Mark file"
            exit 1
            ;;
    esac
}


#==================================================================
#==================================================================
#Implementation
if [[ -s "${QUICKSTART_FUNCTIONS_SCRIPT_PATH}" ]]
then
    source "${QUICKSTART_FUNCTIONS_SCRIPT_PATH}"
    if [[ $? -ne 0 ]]
    then
        echo "Import file(${QUICKSTART_FUNCTIONS_SCRIPT_PATH}) error!"
    fi
else
    echo "Missing required file ${QUICKSTART_FUNCTIONS_SCRIPT_PATH}!"
    exit 1
fi

install $@ || EXIT