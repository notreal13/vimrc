#!/usr/bin/env bash

set -euo pipefail

repository_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source_vimrc="${HOME}/.vimrc"
repository_vimrc="${repository_dir}/.vimrc"
default_commit_message="Update Vim configuration"
commit_message=""
commit_message_model="${VIMRC_COMMIT_MODEL:-gpt-5.6-luna}"

if (( $# > 0 )); then
    commit_message="$*"
fi

generate_commit_message() {
    local staged_diff generated_message

    if ! command -v codex >/dev/null 2>&1; then
        echo "Codex CLI not found; using the default commit message" >&2
        printf '%s\n' "${default_commit_message}"
        return
    fi

    staged_diff="$(git -C "${repository_dir}" diff --cached --unified=0 -- .vimrc)"
    echo "Generating commit message with ${commit_message_model}..." >&2

    if ! generated_message="$(
        printf '%s\n' "${staged_diff}" |
            codex exec \
                --ephemeral \
                --ignore-user-config \
                --ignore-rules \
                --sandbox read-only \
                --model "${commit_message_model}" \
                --color never \
                --cd "${repository_dir}" \
                "Write one concise Git commit subject in imperative English for the supplied staged .vimrc diff. Output only the subject: no quotes, Markdown, explanation, or trailing period. Use at most 72 characters. Do not call tools; use only the supplied diff." \
                2>/dev/null
    )"; then
        echo "Commit message generation failed; using the default" >&2
        printf '%s\n' "${default_commit_message}"
        return
    fi

    generated_message="$(
        printf '%s' "${generated_message}" |
            tr '\r\n' ' ' |
            sed -E 's/[[:space:]]+/ /g; s/^[ `"]+//; s/[ `".]+$//' |
            cut -c 1-72
    )"

    if [[ -z "${generated_message}" ]]; then
        echo "Codex returned an empty commit message; using the default" >&2
        printf '%s\n' "${default_commit_message}"
        return
    fi

    printf '%s\n' "${generated_message}"
}

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
        if [[ -z "${commit_message}" ]]; then
            commit_message="$(generate_commit_message)"
        fi
        echo "Commit message: ${commit_message}"
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
