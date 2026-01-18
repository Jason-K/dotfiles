r"""The Fuck rule: swap `/clear` for `\clear`.

This corrects the common slip of typing a leading slash when invoking the
terminal clear command.
"""


def match(command):
    """Return True when the mistyped command is `/clear`."""
    return command.script.strip() == "/clear"


def get_new_command(command):
    r"""Suggest the proper `\clear` invocation."""
    return "\\clear"