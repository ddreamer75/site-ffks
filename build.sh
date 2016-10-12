#!/bin/bash
# Build the gluon release specified by the tag name in site.mk
# and the checked out branch in this repo.
#
# First argument is taken to generate a sopel bot log.

#
# VARIABLES
#

cur_dir=$(dirname $(readlink -f "${0}"))
release=$(make -f "${cur_dir}/site.mk" print_default_release)
branch=$(git rev-parse --abbrev-ref HEAD)
gluon_broken="BROKEN=1"
job_count=$(nproc)
let "job_count++"

bot_log="${1}"

# TODO Get this information from the make files
declare -a gluon_targets=(\
    ar71xx-generic  \
    ar71xx-nand     \
    mpc85xx-generic \
    x86-generic     \
    x86-kvm_guest   \
    x86-64          \
    x86-xen_domu    \
    )

declare -a gluon_targets_broken=(\
    ramips-rt305x    \ # BROKEN: No AP+IBSS support
    brcm2708-bcm2708 \ # BROKEN: Needs more testing
    brcm2708-bcm2709 \ # BROKEN: Needs more testing
    sunxi            \ # BROKEN: Untested, no sysupgrade support
)


#
# FUNCTIONS
#

# Builds images for all targets
#
#   ${1} branch
#   ${2} version
build_images() {
    cd "${cur_dir}/.." || die "Could not change directory to ${cur_dir}/.."
    [[ "${2}" ]] && gluon_release="GLUON_RELEASE=${2}" || die "No GLUON_RELEASE given"
    make update || die "Could not update repository"

    bot_log "Starting build for branch '${1}' version '${2}'..."

    # Clean repo for all builds
    # TODO This seems to be deprecated?!
    #for target in {"${gluon_targets[@]}","${gluon_targets_broken[@]}"}; do
    #    make clean GLUON_TARGET=${target} || die "Error while cleaning target ${target}"
    #done

    # Build for non-broken targets
    for target in "${gluon_targets[@]}"; do
        bot_log "Building target ${target}..."
        make clean GLUON_TARGET=${target} && make ${gluon_release} GLUON_TARGET=${target} -j${job_count} || die "Error while building target ${target}"
    done

    # Build for broken targets
    if [[ "${1}" != "stable" ]]; then
        echo "Building additional targets with ${gluon_broken}, because not on stable branch."
        for target in "${gluon_targets_broken[@]}"; do
            make clean GLUON_TARGET=${target} && make ${gluon_release} ${gluon_broken} GLUON_TARGET=${target} -j${job_count} || die "Error while building target ${target}"
        done
    fi
}

bot_log() {
    [[ -z "${bot_log}" ]] || echo "${@}" >> "${bot_log}"
}

die() {
    bot_log "${@}"
    echo "${@}" >&2
    exit 1
}

# Gets the current version ID
# ${release}-${build_id}-${branch}
# e.g. v2016.1.5-4-beta
get_version() {
    cd "${cur_dir}/.." || die "Could not change directory to ${cur_dir}/.."
    tag_date=$(git show -s --format=%ci "${release}")
    cd "${OLDPWD}"
    # Commit count in this branch since the date of the commit's tag in the gluon repo
    commit_count=$(git rev-list --count --since "${tag_date}" @)
    echo "${release}-${commit_count}-${branch}"
}


#
# EXECUTION
#

build_images "${branch}" "$(get_version)" || die "Building images failed"
echo "Warning: Images not yet signed/published" >&2
bot_log "Finished building all targets"
bot_log "Warning: Images not yet signed/published"
