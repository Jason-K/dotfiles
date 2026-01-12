# ==================================================================
# Kitty Terminal Integration
# ==================================================================
# Only loads when running in Kitty terminal for performance

if [[ "$TERM" == "xterm-kitty" ]]; then
	# ---- Core Kitty Kittens ----

	# SSH with proper terminfo propagation
	alias ssh="kitty +kitten ssh"

	# Image viewing in terminal
	alias icat="kitty +kitten icat"

	# File transfer over SSH
	alias kcp="kitty +kitten transfer"

	# ---- Theme Management (requires allow_remote_control) ----

	kitty-dark() {
		if [[ ! -f ~/.config/kitty/themes/dark.conf ]]; then
			echo "Error: ~/.config/kitty/themes/dark.conf not found" >&2
			return 1
		fi
		kitty @ set-colors --all ~/.config/kitty/themes/dark.conf 2>/dev/null || {
			echo "Error: Enable allow_remote_control in kitty.conf" >&2
			return 1
		}
	}

	kitty-light() {
		if [[ ! -f ~/.config/kitty/themes/light.conf ]]; then
			echo "Error: ~/.config/kitty/themes/light.conf not found" >&2
			return 1
		fi
		kitty @ set-colors --all ~/.config/kitty/themes/light.conf 2>/dev/null || {
			echo "Error: Enable allow_remote_control in kitty.conf" >&2
			return 1
		}
	}

	# ---- Productivity Features ----

	# Broadcast input to all windows (like iTerm2's broadcast)
	kitty-broadcast() { kitty +kitten broadcast; }

	# New window/tab in current directory
	kitty-new() { kitty @ new-window --cwd="$PWD" "$@"; }
	kitty-tab() { kitty @ new-tab --cwd="$PWD" "$@"; }

	# ---- Window Title Hooks ----
	# Show current directory and running command in window title

	autoload -Uz add-zsh-hook

	_kitty_title_precmd() {
		print -Pn "\e]2;%~\a"  # Show directory
	}

	_kitty_title_preexec() {
		# Show directory + command
		print -Pn "\e]2;%~ ❯ ${1%%$'\n'*}\a"
	}

	add-zsh-hook precmd _kitty_title_precmd
	add-zsh-hook preexec _kitty_title_preexec
fi
