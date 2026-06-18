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

home := env('HOME')


# The directory where quadlet definitions are stored, and which can be
# installed.
quadlets-dir := env("SELFHOST_QUADLETS_DIRECTORY", 'quadlets')



install: install-containers


install-containers pattern="": make-install-env-dir install-config
    #!/usr/bin/env fish

    set quadlets (
        find '{{quadlets-dir}}' -type f -name '*{{pattern}}*.container'
    )

    printf 'Installing quadlets:\n'
    for file in $quadlets
        printf '  %s\n' $file
        "{{podman}}" quadlet install $file -r &| string replace -r '^' '    '
    end
