#!/bin/bash
######################################################################
# sap_s4_hana_single_node.sh
# The script will setup cloud infrastructure and S/4HANA software
# Author: Alibaba Cloud, SAP Product & Solution Team
#####################################################################
#==================================================================
# Environments
QUICKSTART_SAP_MOUDLE='sap-s4-hana-single-node'
QUICKSTART_SAP_MOUDLE_VERSION='1.1.1'
QUICKSTART_ROOT_DIR=$(cd $(dirname "$0" ) && pwd )
QUICKSTART_SAP_SCRIPT_DIR="${QUICKSTART_ROOT_DIR}"
QUICKSTART_FUNCTIONS_SCRIPT_PATH="${QUICKSTART_SAP_SCRIPT_DIR}/functions.sh"
QUICKSTART_LATEST_STEP=6

INFO=`cat <<EOF
    Please input Step number
    Index | Action                  | Description
    -----------------------------------------------
    1     | auto install            | Automatic setup cloud infrastructure and SAP S/4HANA application
    2     | manull install          | Setup cloud infrastructure and install SAP S/4HANA application step by step
    3     | Exit                    |
EOF
`
STEP_INFO=`cat <<EOF
    Please input Step number
    Index | Action             | Description
    -----------------------------------------------
    1     | add host           | Add hostname into hosts file
    2     | mkdisk             | Create swap,physical volumes,volume groups,logical volumes,file systems
    3     | download media     | Download SAP S/4HANA software
    4     | extraction media   | Extraction SAP S/4HANA software
    5     | install S/4HANA   | Install SAP S/4HANA software
    6     | install packages   | Install additional packages and metrics collector
    7     | Exit               |
EOF
`
PARAMS=(
    HANASID
    HANAInstanceNumber
    HANAHostName
    HANAPrivateIpAddress
    SAPSID
    ASCSInstanceNumber
    PASInstanceNumber
    SapmntSize
    UsrsapSize
    S4SwapDiskSize
    DiskIdSapmnt
    DiskIdUsrSap
    DiskIdSwap
    FQDN
    MediaPath
    S4SapSysGid
    S4SapSidAdmUid
    ApplicationVersion
)


#==================================================================
#==================================================================
# Functions
#Define check_params function
#check_params
function check_params(){
    check_para MasterPass '^(?=.*[0-9].*)(?=.*[A-Z].*)(?=.*[a-z].*)[a-zA-Z][0-9a-zA-Z_@#$]{9,13}$'
    check_para HANASID ${RE_SID}
    check_para HANAInstanceNumber ${RE_INSTANCE_NUMBER}
    check_para HANAHostName ${RE_HOSTNAME}
    check_para HANAPrivateIpAddress ${RE_IP}

    check_para SAPSID ${RE_SID}
    check_para ASCSInstanceNumber ${RE_INSTANCE_NUMBER}
    check_para PASInstanceNumber ${RE_INSTANCE_NUMBER}
    check_para UsrsapSize ${RE_DISK}
    check_para SapmntSize ${RE_DISK}
    [[ -n "${S4SwapDiskSize}" ]] && check_para S4SwapDiskSize ${RE_DISK}

    check_para FQDN '(?!-)[a-zA-Z0-9-.]*(?<!-)'
    check_para MediaPath "^(oss|http|https)://[\\S\\w]+([\\S\\w])+$"
    check_para S4SapSidAdmUid "(^\\d+$)"
    check_para S4SapSysGid '^(?!1001$)\d+$'
    check_para ApplicationVersion '^S/4HANA (2020|1909|1809|1709)$'
}

#Define init_variable function
#init_variable 
function init_variable(){
    SAP_INSTALL_TEMPLATE_PATH="${QUICKSTART_SAP_SCRIPT_DIR}/S4_HANA_single_node_install_template.params"
    PASHostname=$(hostname)
    ASCSHostname=$(hostname)

    case "$ApplicationVersion" in
        "S/4HANA 2020")
            SAPINST_EXECUTE_PRODUCT_ID="NW_ABAP_OneHost:S4HANA2020.CORE.HDB.ABAP"
            MediaPath_SWPM="http://sap-automation-${QUICKSTART_SAP_REGION}.oss-${QUICKSTART_SAP_REGION}.aliyuncs.com/alibabacloud-quickstart/packages/SWPM2.0sp07.zip"
            ;;
        "S/4HANA 1909")
            SAPINST_EXECUTE_PRODUCT_ID="NW_ABAP_OneHost:S4HANA1909.CORE.HDB.ABAP"
            MediaPath_SWPM="http://sap-automation-${QUICKSTART_SAP_REGION}.oss-${QUICKSTART_SAP_REGION}.aliyuncs.com/alibabacloud-quickstart/packages/SWPM2.0sp05.zip"
            ;;
        "S/4HANA 1809")
            SAPINST_EXECUTE_PRODUCT_ID="NW_ABAP_OneHost:S4HANA1809.CORE.HDB.ABAP"
            MediaPath_SWPM="http://sap-automation-${QUICKSTART_SAP_REGION}.oss-${QUICKSTART_SAP_REGION}.aliyuncs.com/alibabacloud-quickstart/packages/SWPM2.0sp05.zip"
            ;;
        "S/4HANA 1709")
            SAPINST_EXECUTE_PRODUCT_ID="NW_ABAP_OneHost:S4HANA1709.CORE.HDB.ABAP"
            MediaPath_SWPM="http://sap-automation-${QUICKSTART_SAP_REGION}.oss-${QUICKSTART_SAP_REGION}.aliyuncs.com/alibabacloud-quickstart/packages/SWPM1.0sp23.zip"
            ;;
    esac

    TAR_NAME_SW=$(expr "${MediaPath_SWPM}" : '.*/\(.*\(zip\|ZIP\|tar\.gz\|tgz\|tar\.bz2\|tar\)\).*')
}

#Define add_host function
#add_host
function add_host() {
    info_log "Start to add hosts file"
    config_host "${ECSIpAddress} ${ECSHostname} ${ECSHostname}.${FQDN}"
    config_host "${HANAPrivateIpAddress} ${HANAHostName}"
}

#Define mkdisk function
#mkdisk
function mkdisk() {
    info_log "Start to create swap,physical volumes,volume group,logical volumes,file systems "
    check_disks $DiskIdSapmnt $DiskIdUsrSap $DiskIdSwap || return 1

    disk_id_usr_sap="/dev/${DiskIdUsrSap}"
    disk_size_usr_sap="${UsrsapSize}"
    disk_id_sapmnt="/dev/${DiskIdSapmnt}"
    disk_size_sapmnt="${SapmntSize}"
    disk_id_swap="/dev/${DiskIdSwap}"

    mk_swap ${disk_id_swap}

    pvcreate ${disk_id_usr_sap} ${disk_id_sapmnt} || return 1 
    vgcreate sapvg ${disk_id_usr_sap} ${disk_id_sapmnt} || return 1
    create_lv ${disk_size_sapmnt} sapmntlv sapvg 
    create_lv ${disk_size_usr_sap} usrsaplv sapvg "free"
    mkfs.xfs -f /dev/sapvg/sapmntlv || return 1
    mkfs.xfs -f /dev/sapvg/usrsaplv || return 1 
    mkdir -p /sapmnt /usr/sap
    $(grep -q /dev/sapvg/sapmntlv ${ETC_FSTAB_PATH}) || echo "/dev/sapvg/sapmntlv        /sapmnt  xfs defaults        0 0" >> ${ETC_FSTAB_PATH}
    $(grep -q /dev/sapvg/usrsaplv ${ETC_FSTAB_PATH}) || echo "/dev/sapvg/usrsaplv        /usr/sap  xfs defaults       0 0" >> ${ETC_FSTAB_PATH}

    mount -a
    check_filesystem || return 1
    info_log "Swap,physical volumes,volume group,logical volumes,file systems have been created successful"
}

#Define check_filesystem function
function check_filesystem() {
    info_log "Start to check SAP file systems"
    df -h | grep -q "/usr/sap" || { error_log "/usr/sap mounted failed"; return 1; }
    df -h | grep -q "/sapmnt" || { error_log "/sapmnt mounted failed"; return 1; }
    info_log "Both SAP relevant file systems have been mounted successful"
}

#Define install_S4_1709 function
#install_S4_1709
function install_S4_1709() {
    info_log "Start to install S/4HANA 1709"
    sapinst_path=${QUICKSTART_SAP_EXTRACTION_DIR}"/${TAR_NAME_SW%.*}/"
    Kernel_Path=${QUICKSTART_SAP_DOWNLOAD_DIR}"/"
    Hanaclient_Path=`find $QUICKSTART_SAP_EXTRACTION_DIR -regex .*DATA_UNITS/HDB_CLIENT_LINUX_X86_64 | tail -1`"/"
    Export_Path=`find $QUICKSTART_SAP_EXTRACTION_DIR -regex .*DATA_UNITS/EXPORT_11`
    Export_Path="${Export_Path%EXPORT_11}"
    
    cat << EOF > ${SAP_INSTALL_TEMPLATE_PATH}
    NW_HDB_DB.abapSchemaName = SAPABAP1
    NW_HDB_DB.abapSchemaPassword = ${MasterPass}
    NW_ABAP_Import_Dialog.dbCodepage = 4103
    NW_ABAP_Import_Dialog.migmonJobNum = 40
    NW_ABAP_Import_Dialog.migmonLoadArgs = -c 100000 -rowstorelist /tmp/sapinst_instdir/S4HANA1709/CORE/HDB/INSTALL/STD/ABAP/rowstorelist.txt
    NW_CI_Instance.ascsInstanceNumber = ${ASCSInstanceNumber}
    NW_CI_Instance.ascsVirtualHostname = ${AscsHostName}
    NW_CI_Instance.ciInstanceNumber = ${PASInstanceNumber}
    NW_CI_Instance.ciVirtualHostname = ${PasHostName}
    NW_CI_Instance.scsVirtualHostname = 
    NW_CI_Instance_ABAP_Reports.executeReportsForDepooling = true
    NW_GetMasterPassword.masterPwd = ${MasterPass}
    NW_GetSidNoProfiles.sid = ${SAPSID}
    NW_HDB_DBClient.clientPathStrategy = SAPCPE
    NW_HDB_getDBInfo.dbhost = ${HANAHostName}
    NW_HDB_getDBInfo.dbsid = ${HANASID}
    NW_HDB_getDBInfo.instanceNumber = ${HANAInstanceNumber}
    NW_HDB_getDBInfo.systemDbPassword = ${MasterPass}
    NW_HDB_getDBInfo.systemPassword = ${MasterPass}
    NW_getFQDN.FQDN = ${FQDN}
    NW_getLoadType.loadType = SAP
    NW_liveCache.useLiveCache = false
    archives.downloadBasket = ${Kernel_Path}
    hanadb.landscape.reorg.useParameterFile = DONOTUSEFILE
    hdb.create.dbacockpit.user = true
    nwUsers.sapsysGID = ${S4SapSysGid}
    nwUsers.sidAdmUID = ${S4SapSidAdmUid}
    nwUsers.sidadmPassword = ${MasterPass}
    storageBasedCopy.hdb.instanceNumber = ${HANAInstanceNumber}
    storageBasedCopy.hdb.systemPassword = ${MasterPass}
    SAPINST.CD.PACKAGE.KERNEL = 
    SAPINST.CD.PACKAGE.LOAD = ${Export_Path}
    SAPINST.CD.PACKAGE.RDBMS = ${Hanaclient_Path}
EOF
    cd "${sapinst_path}" && ./sapinst SAPINST_INPUT_PARAMETERS_URL=$"{SAP_INSTALL_TEMPLATE_PATH}" SAPINST_EXECUTE_PRODUCT_ID="${SAPINST_EXECUTE_PRODUCT_ID}" SAPINST_SKIP_DIALOGS=true SAPINST_START_GUISERVER=false  >/dev/null || return 1
    validation || return 1
    info_log "Finished S/4HANA 1709 single node installation" 
}

#Define install_S4_1809 function
#install_S4_1809
function install_S4_1809() {
    check_media_1809 "${QUICKSTART_SAP_DOWNLOAD_DIR}" || return 1
    info_log "Start to install S/4HANA 1809"
    sapinst_path=${QUICKSTART_SAP_EXTRACTION_DIR}"/${TAR_NAME_SW%.*}/"
    MediaPath=${QUICKSTART_SAP_DOWNLOAD_DIR}"/"
    HANA_sid=$(echo "$HANASID" |tr '[:upper:]' '[:lower:]')"adm"

    cat << EOF > ${SAP_INSTALL_TEMPLATE_PATH}
        HDB_Schema_Check_Dialogs.schemaPassword = ${MasterPass}
        HDB_Schema_Check_Dialogs.validateSchemaName = false
        NW_CI_Instance.ascsInstanceNumber = ${ASCSInstanceNumber}
        NW_CI_Instance.ascsVirtualHostname = ${ASCSHostname}
        NW_CI_Instance.ciInstanceNumber = ${PASInstanceNumber}
        NW_CI_Instance.ciVirtualHostname = ${PASHostname}
        NW_CI_Instance.scsVirtualHostname = 
        NW_Delete_Sapinst_Users.removeUsers = true
        NW_GetMasterPassword.masterPwd = ${MasterPass}
        NW_GetSidNoProfiles.sid = ${SAPSID}
        NW_HDB_getDBInfo.dbhost = ${HANAHostName}
        NW_HDB_getDBInfo.dbsid = ${HANASID}
        NW_HDB_getDBInfo.instanceNumber = ${HANAInstanceNumber}
        NW_HDB_getDBInfo.systemDbPassword = ${MasterPass}
        NW_HDB_getDBInfo.systemPassword = ${MasterPass}
        NW_Recovery_Install_HDB.extractLocation = 
        NW_Recovery_Install_HDB.extractParallelJobs = 19
        NW_Recovery_Install_HDB.sidAdmName = ${HANA_sid}
        NW_Recovery_Install_HDB.sidAdmPassword = ${MasterPass}
        NW_getFQDN.FQDN = ${FQDN}
        NW_getLoadType.loadType = SAP
        archives.downloadBasket = ${MediaPath}
        nwUsers.sidadmPassword = ${MasterPass}
        storageBasedCopy.hdb.instanceNumber = ${HANAInstanceNumber}
        storageBasedCopy.hdb.systemPassword = ${MasterPass}
        nwUsers.sapsysGID = ${S4SapSysGid}
        nwUsers.sidAdmUID = ${S4SapSidAdmUid}
EOF
    cd "${sapinst_path}" && ./sapinst SAPINST_INPUT_PARAMETERS_URL=${SAP_INSTALL_TEMPLATE_PATH} SAPINST_EXECUTE_PRODUCT_ID="${SAPINST_EXECUTE_PRODUCT_ID}" SAPINST_SKIP_DIALOGS=true SAPINST_START_GUISERVER=false  >/dev/null || return 1
    validation || return 1
    info_log "Finished S/4HANA 1809 single node installation"
}

#Define install_S4_1909 function
#install_S4_1909
function install_S4_1909() {
    check_export_1909 "${QUICKSTART_SAP_DOWNLOAD_DIR}" || return 1
    info_log "Start to install S/4HANA"
    sapinst_path=${QUICKSTART_SAP_EXTRACTION_DIR}"/${TAR_NAME_SW%.*}/"
    MediaPath=${QUICKSTART_SAP_DOWNLOAD_DIR}"/"
    HANA_sid=$(echo "$HANASID" |tr '[:upper:]' '[:lower:]')"adm"

    cat << EOF > ${SAP_INSTALL_TEMPLATE_PATH}
        HDB_Schema_Check_Dialogs.schemaPassword = ${MasterPass}
        HDB_Schema_Check_Dialogs.validateSchemaName = false
        NW_CI_Instance.ascsInstanceNumber = ${ASCSInstanceNumber}
        NW_CI_Instance.ascsVirtualHostname = ${ASCSHostname}
        NW_CI_Instance.ciInstanceNumber = ${PASInstanceNumber}
        NW_CI_Instance.ciVirtualHostname = ${PASHostname}
        NW_CI_Instance.scsVirtualHostname = 
        NW_Delete_Sapinst_Users.removeUsers = true
        NW_GetMasterPassword.masterPwd = ${MasterPass}
        NW_GetSidNoProfiles.sid = ${SAPSID}
        NW_HDB_getDBInfo.dbhost = ${HANAHostName}
        NW_HDB_getDBInfo.dbsid = ${HANASID}
        NW_HDB_getDBInfo.instanceNumber = ${HANAInstanceNumber}
        NW_HDB_getDBInfo.systemDbPassword = ${MasterPass}
        NW_HDB_getDBInfo.systemPassword = ${MasterPass}
        NW_Recovery_Install_HDB.extractLocation = 
        NW_Recovery_Install_HDB.extractParallelJobs = 19
        NW_Recovery_Install_HDB.sidAdmName = ${HANA_sid}
        NW_Recovery_Install_HDB.sidAdmPassword = ${MasterPass}
        NW_getFQDN.FQDN = ${FQDN}
        NW_getLoadType.loadType = SAP
        archives.downloadBasket = ${MediaPath}
        nwUsers.sidadmPassword = ${MasterPass}
        storageBasedCopy.hdb.instanceNumber = ${HANAInstanceNumber}
        storageBasedCopy.hdb.systemPassword = ${MasterPass}
        nwUsers.sapsysGID = ${S4SapSysGid}
        nwUsers.sidAdmUID = ${S4SapSidAdmUid}
EOF
    cd "${sapinst_path}" && ./sapinst SAPINST_INPUT_PARAMETERS_URL=${SAP_INSTALL_TEMPLATE_PATH} SAPINST_EXECUTE_PRODUCT_ID="${SAPINST_EXECUTE_PRODUCT_ID}" SAPINST_SKIP_DIALOGS=true SAPINST_START_GUISERVER=false  >/dev/null || return 1
    validation || return 1
    info_log "Finished S/4HANA single node installation"
}

#Define install_S4_2020 function
#install_S4_2020
function install_S4_2020() {
    wait_HANA_ECS "${HANAPrivateIpAddress}" "${HANAInstanceNumber}" || return 1
    info_log "Start to install S/4HANA 2020 ABAP"
    sapinst_path=${QUICKSTART_SAP_EXTRACTION_DIR}"/${TAR_NAME_SW%.*}/"
    MediaPath=${QUICKSTART_SAP_DOWNLOAD_DIR}"/"
    HANA_sid=$(echo "$HANASID" |tr '[:upper:]' '[:lower:]')"adm"

    cat << EOF > ${SAP_INSTALL_TEMPLATE_PATH}
        HDB_Schema_Check_Dialogs.schemaPassword = ${MasterPass}
        HDB_Schema_Check_Dialogs.schemaName = SAPHANADB
        HDB_Userstore.doNotResolveHostnames = ${HANAHostName}
        NW_CI_Instance.ascsInstanceNumber = ${ASCSInstanceNumber}
        NW_CI_Instance.ascsVirtualHostname = ${ASCSHostname}
        NW_CI_Instance.ciInstanceNumber = ${PASInstanceNumber}
        NW_CI_Instance.ciVirtualHostname =  ${PASHostname}
        NW_CI_Instance.scsVirtualHostname =
        NW_DDIC_Password.needDDICPasswords = false
        NW_GetMasterPassword.masterPwd = ${MasterPass}
        NW_GetSidNoProfiles.sid = ${SAPSID}
        NW_HDB_DB.abapSchemaName = SAPHANADB
        NW_HDB_DB.abapSchemaPassword = ${MasterPass}
        NW_HDB_getDBInfo.dbhost = ${HANAHostName}
        NW_HDB_getDBInfo.dbsid = ${HANASID}
        NW_HDB_getDBInfo.instanceNumber = ${HANAInstanceNumber}
        NW_HDB_getDBInfo.systemDbPassword = ${MasterPass}
        NW_HDB_getDBInfo.systemPassword = ${MasterPass}
        NW_Recovery_Install_HDB.extractLocation =
        NW_HDB_getDBInfo.systemid = ${HANASID}
        NW_Recovery_Install_HDB.extractParallelJobs = 23
        NW_Recovery_Install_HDB.sidAdmName = ${HANA_sid}
        NW_Recovery_Install_HDB.sidAdmPassword = ${MasterPass}
        NW_getFQDN.FQDN = ${FQDN}
        NW_getLoadType.loadType = SAP
        archives.downloadBasket = ${MediaPath}
        hostAgent.sapAdmPassword = ${MasterPass}
        nwUsers.sidadmPassword = ${MasterPass}
        nwUsers.sapsysGID = ${S4SapSysGid}
        nwUsers.sidAdmUID = ${S4SapSidAdmUid}
EOF
    cd "${sapinst_path}" && ./sapinst SAPINST_INPUT_PARAMETERS_URL="${SAP_INSTALL_TEMPLATE_PATH}" SAPINST_EXECUTE_PRODUCT_ID="${SAPINST_EXECUTE_PRODUCT_ID}" SAPINST_SKIP_DIALOGS=true SAPINST_START_GUISERVER=false  >/dev/null || return 1
    validation || return 1
    info_log "Finished S/4HANA ABAP 2020 single node installation"
}

#Define validation function
#validation
function validation() {
    info_log "Start to check S/4HANA running status"
    SID=$(echo "$SAPSID" |tr '[:upper:]' '[:lower:]')
    SIDADM=$(echo $SID\adm)
    su - ${SIDADM} -c "sapcontrol -nr ${ASCSInstanceNumber} -function GetProcessList" > /dev/null 2>&1
    msgserver=$?
    su - ${SIDADM} -c "sapcontrol -nr ${PASInstanceNumber} -function GetProcessList" > /dev/null 2>&1
    disp=$?
    if [ ${msgserver} == '3' -a ${disp} == '3' ];
    then
        info_log "S/4HANA is running"
        return 0
    else
        error_log "S/4HANA status is unknown"
        return 1
    fi
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
            wait_HANA_ECS "${HANAPrivateIpAddress}" "${HANAInstanceNumber}" || return 1
            case "$ApplicationVersion" in
                "S/4HANA 2020")
                    install_S4_2020 || return 1
                    ;;
                "S/4HANA 1909")
                    install_S4_1909 || return 1
                    ;;
                "S/4HANA 1809")
                    install_S4_1809 || return 1
                    ;;
                "S/4HANA 1709")
                    chmod -R 777 "${QUICKSTART_SAP_EXTRACTION_DIR}"/*
                    install_S4_1709 || return 1
                    ;;
            esac
            ;;
        6)
            single_node_packages
            APP_post
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