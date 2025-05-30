# 在容器中构建、运行、调试Linux内核代码

1. `bash ./download-kernel.sh` 下载内核代码
2. `podman build -t linux-builder .` 构建镜像
3. `podman run -it --name linux-runner -v $(pwd)/linux-src:/linux/src -v $(pwd)/linux-obj:/linux/obj --rm linux-builder` 构建Linux
4. `podman run -it --name linux-runner -v $(pwd)/linux-src:/linux/src -v $(pwd)/linux-obj:/linux/obj --rm linux-builder qemu-run.sh` 运行Linux，使用 [printk](https://www.kernel.org/doc/html/latest/core-api/printk-basics.html)进行调试
5. `podman run -it --name linux-runner -v $(pwd)/linux-src:/linux/src -v $(pwd)/linux-obj:/linux/obj --rm linux-builder -p 1234:1234 qemu-gdb.sh` 运行Linux，监听GDB的连接
6. `podman exec -it linux-runner bash start-gdb.sh` 运行GDB，连接qemu

## NOTE:

.config 文件是构建Linux内核代码的配置
> Kernel hacking ---> Compile-time checks and compiler options
> DWARF ..: relay ...
> Provide GDB script

.busybox_config 文件是构建busybox的配置
> Settings ---> Build static binary (no shared libs)

init.sh 用于内核init进程：挂载一些目录，启动一个交互shellk

本地远程调试: `gdb ./linux-obj/vmlinux -ex "target remote :1234" -ex "set substitute-path /linux/src ./linux-src"`
TODO: add-auto-load-safe-path /linux/src/scripts/gdb/vmlinux-gdb.py
echo "add-auto-load-safe-path $(pwd)/linux-src/scripts/gdb/vmlinux-gdb.py" >~/.gdbinit
