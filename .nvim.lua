local config = vim.g.termdebug_config or {}
config["command"] = {
	"gdb",
	"./linux-obj/vmlinux",
	"-ex",
	"target remote :1234",
	"-ex",
	"set substitute-path /linux/src ./linux-src",
}
vim.g.termdebug_config = config
vim.cmd[[packadd termdebug]]
