require("full-border"):setup()
require("recycle-bin"):setup()

Status:children_add(function(self)
    local h = self._current.hovered
    if h and h.link_to then
        return " -> " .. tostring(h.link_to)
    else
        return ""
    end
end, 3300, Status.LEFT)

require("copy-file-contents"):setup({
    append_char = "\n",
    notification = true,
})
