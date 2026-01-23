# ==================================================================
# Shell Functions — Organized by purpose
# ==================================================================

# ---- Yazi smart-cd wrapper ----
# Usage: y [directory]
# Changes to the directory you exit yazi in
y() {
	local tmp cwd
	tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	yazi "$@" --cwd-file="$tmp"
	if IFS= read -r -d '' cwd < "$tmp"; then
		[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# ---- Ripgrep-all file finder with preview ----
# Usage: ff <search-term>
# Searches all file types (PDFs, docs, etc.) and opens result
ff() {
	[[ "$#" -gt 0 ]] || { echo "Usage: ff <search-term>"; return 1; }

	if ! command -v rga >/dev/null 2>&1; then
		echo "Error: ripgrep-all (rga) not found. Install with: brew install ripgrep-all" >&2
		return 1
	fi

	local file
	file="$(rga --max-count=1 --ignore-case --files-with-matches --no-messages "$*" \
		| fzf-tmux +m --preview="rga --ignore-case --pretty --context 10 '$*' {}")"

	if [[ -n "$file" ]]; then
		echo "Opening: $file"
		open "$file"
	else
		return 1
	fi
}

# ---- Fuzzy directory navigation with locate ----
# Usage: cf <search-pattern>
# Quickly cd to any directory on system using locate database
cf() {
	if ! command -v locate >/dev/null 2>&1; then
		echo "Error: locate not found" >&2
		return 1
	fi

	local file
	file="$(locate -i "$@" | grep -v '~$' | fzf -0 -1)"

	[[ -n "$file" ]] || return

	if [[ -d "$file" ]]; then
		cd -- "$file"
	else
		cd -- "${file:h}"
	fi
}

# ---- Interactive process killer ----
# Usage: fkill [signal]
# Select processes interactively and kill them (default: SIGKILL/-9)
fkill() {
	local pid signal="${1:-9}"

	if [[ "$UID" != "0" ]]; then
		pid=$(ps -f -u "$UID" | sed 1d | fzf -m | awk '{print $2}')
	else
		pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
	fi

	if [[ -n "$pid" ]]; then
		echo "$pid" | xargs kill -"${signal}"
		echo "Sent signal ${signal} to process(es): $pid"
	fi
}

# ---- Cling window manager helper ----
# Usage: cling <file-or-folder> ...
# Opens parent directories in Cling app for side-by-side viewing
cling() {
	local folders=()

	for arg in "$@"; do
		if [[ -d "$arg" ]]; then
			folders+=("$arg")
		elif [[ -f "$arg" ]]; then
			folders+=("$(dirname "$arg")")
		fi
	done

	if [[ ${#folders[@]} -gt 0 ]]; then
		open -a Cling "${folders[@]}"
	else
		echo "Usage: cling <file-or-folder> ..." >&2
		return 1
	fi
}

# ---- Safe Homebrew Uninstall ----
# Usage: unbrew <package>
# Uninstalls package and removes it from the DOTFILES Brewfile to prevent reinstallation
unbrew() {
    local package="$1"
    local brewfile="$HOME/dotfiles/brew/Brewfile"

    if [[ -z "$package" ]]; then
        echo "Usage: unbrew <package>"
        return 1
    fi

    echo "📦 Uninstalling $package..."
    brew uninstall "$package" || return 1

    if [[ -f "$brewfile" ]]; then
        if grep -q "$package" "$brewfile"; then
            echo "📝 Removing $package from Brewfile..."
            # Delete lines containing the package name matched roughly to avoid partial matches on similar names if possible
            # We match the package name surrounded by quotes or spaces
            sed -i '' "/['\"]$package['\"]/d" "$brewfile"
            # Fallback for unquoted if needed, but let's stick to quotes first as Brewfile usually uses them
            # If the user uses unquoted args (rare in generated files), we can handle that later.
            echo "✅ Removed from $brewfile"
        else
            echo "ℹ️  $package not found in $brewfile"
        fi
    fi
}

# ---- System update function (requires 1Password) ----
# Usage: update [--dry-run] [topgrade options]
# Runs topgrade with GitHub token from 1Password
update() {
	if ! command -v op >/dev/null 2>&1; then
		echo "Error: 1Password CLI (op) not found" >&2
		return 1
	fi

	if ! op whoami &>/dev/null; then
		echo "⚠️  Please authenticate with 1Password first"
		eval "$(op signin)" || return 1
	fi

	local gh_token
	gh_token=$(op read "op://Secrets/GitHub Personal Access Token/token" 2>/dev/null) || {
		echo "Error: Failed to read GitHub token from 1Password" >&2
		return 1
	}

	local sudo_pass
	sudo_pass=$(op read "op://Private/Mac/password" 2>/dev/null) || {
		echo "Error: Failed to read Mac password from 1Password" >&2
		return 1
	}

	# Run reconciliation to check for uninstalled apps
	if [[ -x "$HOME/dotfiles/scripts/brew-reconcile.sh" ]]; then
		"$HOME/dotfiles/scripts/brew-reconcile.sh"
	fi

	# Pre-authenticate sudo
	echo "$sudo_pass" | sudo -S -v 2>/dev/null || {
		echo "Error: Sudo authentication failed" >&2
		return 1
	}

	if ! command -v topgrade >/dev/null 2>&1; then
		echo "Error: topgrade not found. Install with: brew install topgrade" >&2
		return 1
	fi

	topgrade --env GITHUB_TOKEN="${gh_token}" "$@"
}
