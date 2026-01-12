# ==================================================================
# Lazy-Loading Wrapper for Heavy Tools
# ==================================================================
# Defers initialization of slow commands until first use
# Significantly improves shell startup time

# ---- Configuration ----
typeset -A LAZY_TOOLS=(
	[conda]="/opt/anaconda3/bin/conda shell.zsh hook"
	[mise]="$HOME/.local/bin/mise activate zsh"
	[thefuck]="thefuck --alias"
	[tv]="tv init zsh"
)

# ---- Implementation ----
# Creates stub functions that initialize on first call

_lazy_load_tool() {
	local tool="$1"
	local init_cmd="${LAZY_TOOLS[$tool]}"

	# Remove the stub function
	unfunction "$tool" 2>/dev/null

	# Initialize the real tool
	eval "$(eval "$init_cmd")" 2>/dev/null || {
		echo "Warning: Failed to initialize $tool" >&2
		return 1
	}

	# Run the original command
	"$tool" "$@"
}

# ---- Create Lazy-Loading Stubs ----

# Conda - Python environment manager
if [[ -x "/opt/anaconda3/bin/conda" ]]; then
	conda() {
		_lazy_load_tool conda "$@"
	}
fi

# mise - Runtime version manager
if [[ -x "$HOME/.local/bin/mise" ]]; then
	mise() {
		_lazy_load_tool mise "$@"
	}
fi

# thefuck - Command corrector
if command -v thefuck >/dev/null 2>&1; then
	fuck() {
		_lazy_load_tool thefuck "$@"
	}
fi

# tv - Terminal file viewer
if command -v tv >/dev/null 2>&1; then
	tv() {
		_lazy_load_tool tv "$@"
	}
fi

# ---- Note ----
# To disable lazy-loading for a specific tool and load immediately:
# 1. Remove from LAZY_TOOLS array above
# 2. Add traditional init to .zshrc section 8, e.g.:
#    eval "$(/opt/anaconda3/bin/conda shell.zsh hook)" 2>/dev/null || true
