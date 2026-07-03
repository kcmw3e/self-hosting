#!/usr/bin/env -S just --justfile

# Make the default recipe just list possible recipes. Taken from the
# `just` documentation:
#     https://github.com/casey/just?tab=readme-ov-file#listing-available-recipes
# 
default:
    @just --list --unsorted --justfile {{justfile()}}

set dotenv-load := true

alias i := install

podman := require('podman')

# The directory where quadlet definitions are stored, and which can be
# installed.
quadlets-dir := env('SELFHOST_QUADLETS_DIRECTORY', 'quadlets')

env-files-dir := env('SELFHOST_ENV_FILES_DIRECTORY', 'env')
template-files-dir := env('SELFHOST_ENV_FILES_DIRECTORY', 'templates')

# Directory to where configurations for self-hosted services and related things
# are written. Configurations written here are not necessarily dictated by a
# container or service, but rather belong to this project and how it's set up.
# For example, this is where files referenced by Quadlet `.container` files are
# stored, such as `.env` files, and that could serve multiple different
# containers if needed.
config-install-dir := env(
    'SELFHOST_CONFIG_INSTALL_DIRECTORY',
    config_dir()/'self-hosted',
)

# Directory where `.env` files are stored for this project. Unless specifically
# set to something else, this will be the same as `install-config-dir`. Note
# that, if this is changed, some containers which reference files in this
# directory will need to be edited to reference to this directory.
env-install-dir := env('SELFHOST_ENV_INSTALL_DIR', config-install-dir)
env-generated-install-dir := env-install-dir/'generated'


install: install-containers install-config


install-containers pattern='': make-install-env-dir install-config
    #!/usr/bin/env fish

    set quadlets (
        find '{{quadlets-dir}}' -type f -name '*{{pattern}}*.container'
    )

    printf 'Installing quadlets:\n'
    for file in $quadlets
        printf '  %s\n' $file
        '{{podman}}' quadlet install $file -r &| string replace -r '^' '    '
    end


install-config: make-install-config-dir install-env install-env-generated


install-env pattern='': make-install-env-dir
    #!/usr/bin/env fish

    set files (
        find '{{env-files-dir}}' -type f -name '*{{pattern}}*.env'
    )

    printf 'Installing env files:\n'
    for file in $files
        printf '  %s\n' $file
        cp -t '{{env-install-dir}}' $file
    end


install-env-generated pattern='': make-install-env-generated-dir
    #!/usr/bin/env fish

    set files (
        find '{{template-files-dir}}' -type f -name '*{{pattern}}*.env.template'
    )

    printf 'Generating base env files for containers.\n'
    for template in $files
        set filename (path basename -E $template)
        set file (
            string join / '{{env-generated-install-dir}}' $filename
        )
        printf '  %s -> %s\n' $template $file
        cat $template | envsubst > $file
    end


[private]
@make-install-config-dir:
    mkdir -p '{{config-install-dir}}'


[private]
@make-install-env-dir:
    mkdir -p '{{env-install-dir}}'


[private]
@make-install-env-generated-dir:
    mkdir -p '{{env-generated-install-dir}}'
