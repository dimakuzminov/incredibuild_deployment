# this script is based on following article
# http://www.debian.org/doc/manuals/developers-reference/best-pkging-practices.html
#
#! /bin/bash
PROJECT=$(pwd)
DEB_GLOBAL_DIR=${PROJECT}/deb
OS_DISTRIBUTION=$(lsb_release -is)
OS_RELEASE=$(lsb_release -rs)
OS_CODE=$(lsb_release -cs)
OS_VERSION=${OS_DISTRIBUTION}_${OS_RELEASE}_${OS_CODE}
REVISION=$(git rev-parse HEAD)
CURRENT_REV=$(git describe --all --exact-match ${REVISION})
BIN_FILES_DIR=${PROJECT}/OS/${OS_VERSION}/bin
DEB_GLOBAL_DIR=${PROJECT}/deb
    
echo "######   CURRENT REVISION IS [${REVISION}]"
if [[ "$CURRENT_REV" == *tags* ]]
then
    SUFFIX=${CURRENT_REV:5}
    echo "######   CURRENT VERSION IDENTIFIED [${SUFFIX}]"
else
    echo "######   IT IS DIRTY RELEASE, PLEASE CREATE TAG"
    SUFFIX=dirty_${REVISION}
fi

PACKAGE_NAME=incredibuild_linux_$SUFFIX
PKG_BLD_DIR_DEBIAN=0
PKG_BLD_DIR_DOC=1
PKG_BLD_DIR_SBIN=2
PKG_BLD_DIR_MAN=3

pkg_dirs=( ${PROJECT}/${PACKAGE_NAME}/debian/DEBIAN \
            ${PROJECT}/${PACKAGE_NAME}/usr/share/doc/${PACKAGE_NAME} \
            ${PROJECT}/${PACKAGE_NAME}/debian/usr/sbin \
            ${PROJECT}/${PACKAGE_NAME}/debian/usr/share/man/man1 )

files_to_copy=( ${DEB_GLOBAL_DIR}/preinst           \
                ${DEB_GLOBAL_DIR}/control          \
                ${DEB_GLOBAL_DIR}/incredibuild.1.gz    \
                ${DEB_GLOBAL_DIR}/copyright         \
                ${DEB_GLOBAL_DIR}/changelog.Debian  \
                ${BIN_FILES_DIR}/GridCoordinator \
                ${BIN_FILES_DIR}/GridHelper      \
                ${BIN_FILES_DIR}/GridServer      \
                ${BIN_FILES_DIR}/XgConsole       \
                ${BIN_FILES_DIR}/XgRegisterMe    \
                ${BIN_FILES_DIR}/XgSubmit        \
                ${BIN_FILES_DIR}/XgWait )

dest_dirs=( ${pkg_dirs[${PKG_BLD_DIR_DEBIAN}]} \
            ${pkg_dirs[${PKG_BLD_DIR_DEBIAN}]} \
            ${pkg_dirs[${PKG_BLD_DIR_MAN}]} \
            ${pkg_dirs[${PKG_BLD_DIR_DOC}]} \
            ${pkg_dirs[${PKG_BLD_DIR_DOC}]} \
            ${pkg_dirs[${PKG_BLD_DIR_SBIN}]} \
            ${pkg_dirs[${PKG_BLD_DIR_SBIN}]} \
            ${pkg_dirs[${PKG_BLD_DIR_SBIN}]} \
            ${pkg_dirs[${PKG_BLD_DIR_SBIN}]} \
            ${pkg_dirs[${PKG_BLD_DIR_SBIN}]} \
            ${pkg_dirs[${PKG_BLD_DIR_SBIN}]} \
            ${pkg_dirs[${PKG_BLD_DIR_SBIN}]} )

function remove_package() {
    echo  "[$OS_VERSION]: Remove old package..."
    package=$1/$2
    if [ -e ${package} ]
    then 
        echo " Package to remove - ${package}"
        sudo rm -fr ${package}
    fi
}

function create_pkg_dirs() {
    echo  "[$OS_VERSION]: Create the tree structure of files"
    for index in ${!pkg_dirs[*]}
    do
        mkdir -p  ${pkg_dirs[$index]}       
    done
}

function copy_files() {
    echo  "[$OS_VERSION]: Copy the installation files"
    for index in ${!files_to_copy[*]}
    do
        if [ -x ${files_to_copy[${index}]} ]
        then
            strip --remove-section=.comment --remove-section=.note ${files_to_copy[${index}]}
        fi
        cp -v ${files_to_copy[${index}]} ${dest_dirs[${index}]}
    done
}

function set_permissions() {
    sudo chmod -Rv 0755 ${PROJECT}/${PACKAGE_NAME}
    sudo chmod -Rv 0644 ${pkg_dirs[$PKG_BLD_DIR_DOC]}
    sudo chown -v root:root ${pkg_dirs[$PKG_BLD_DIR_DEBIAN]}/preinst
}

function compress_doc_files() {
    sudo gzip -v --best ${pkg_dirs[$PKG_BLD_DIR_DOC]}/changelog.Debian
}

function create_deb_package() {
    pushd ${PROJECT}/${PACKAGE_NAME}
    fakeroot dpkg-deb --build debian
    mv debian.deb ${PACKAGE_NAME}.deb
    popd
}

function create_deb_project_dir_struct() {
    remove_package ${PROJECT} ${PACKAGE_NAME}
    create_pkg_dirs
    copy_files
}

function verify_package() {
    lintian ${PROJECT}/${PACKAGE_NAME}/${PACKAGE_NAME}.deb
    #lintian -iIv --pedantic ${PROJECT}/${PACKAGE_NAME}/${PACKAGE_NAME}.deb
}

create_deb_project_dir_struct
set_permissions
compress_doc_files
create_deb_package
verify_package
