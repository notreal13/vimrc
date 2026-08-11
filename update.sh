#!/usr/bin/env bash

set -euo pipefail

repository_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source_vimrc="${HOME}/.vimrc"
repository_vimrc="${repository_dir}/.vimrc"
commit_message="Update Vim configuration"

if (( $# > 0 )); then
    commit_message="$*"
fi

if [[ ! -f "${source_vimrc}" ]]; then
    echo "vimrc not found: ${source_vimrc}" >&2
    exit 1
fi

if ! git -C "${repository_dir}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "not a Git repository: ${repository_dir}" >&2
    exit 1
fi

if ! git -C "${repository_dir}" remote get-url origin >/dev/null 2>&1; then
    echo "Git remote 'origin' is not configured" >&2
    exit 1
fi

if ! cmp -s "${source_vimrc}" "${repository_vimrc}"; then
    cp "${source_vimrc}" "${repository_vimrc}"
    echo "Copied ${source_vimrc} -> ${repository_vimrc}"
else
    echo "Working vimrc already matches the repository copy"
fi

if [[ -n "$(git -C "${repository_dir}" status --porcelain -- .vimrc)" ]]; then
    git -C "${repository_dir}" add -- .vimrc
    git -C "${repository_dir}" diff --cached --check -- .vimrc

    if ! git -C "${repository_dir}" diff --cached --quiet -- .vimrc; then
        git -C "${repository_dir}" commit -m "${commit_message}" -- .vimrc
    fi
else
    echo "No vimrc changes to commit"
fi

current_branch="$(git -C "${repository_dir}" branch --show-current)"
if [[ -z "${current_branch}" ]]; then
    echo "cannot push from a detached HEAD" >&2
    exit 1
fi

if git -C "${repository_dir}" rev-parse --abbrev-ref '@{upstream}' >/dev/null 2>&1; then
    git -C "${repository_dir}" push
else
    git -C "${repository_dir}" push --set-upstream origin "${current_branch}"
fi
