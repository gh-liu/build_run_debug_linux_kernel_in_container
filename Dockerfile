FROM docker.io/library/debian:12.11-slim

# 第一阶段，构建一个需要的OS环境
RUN apt-get update
RUN apt install -y apt-transport-https ca-certificates 
RUN echo 'deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm main contrib non-free non-free-firmware \n\
        deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware \n\
        deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-backports main contrib non-free non-free-firmware \n\
        deb https://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware\n' \
        > /etc/apt/sources.list 
RUN apt-get update 
RUN apt-get install -y vim
# build kernel
RUN apt-get install -y \
        bc \
        flex \
        bison \
        build-essential \
        cpio \
        libelf-dev \
        libncurses-dev \
        libssl-dev
# run kernel
RUN apt-get install -y qemu-kvm
# debug kernel
RUN apt-get install -y gdb

# 第二阶段，构建initramfs，用于引导内核启动
RUN apt-get install -y wget
# RUN apt-get install -y bzip2
WORKDIR /busybox
# downloads busybox-src
RUN wget https://busybox.net/downloads/busybox-1.37.0.tar.bz2
RUN tar -vxjf busybox-1.37.0.tar.bz2
RUN mv busybox-1.37.0 src
# build busybox
WORKDIR /busybox/src
RUN mkdir -p /busybox/obj
RUN make O=/busybox/obj defconfig
# https://github.com/mirror/busybox/blob/371fe9f71d445d18be28c82a2a6d82115c8af19d/Config.in#L373
ADD .busybox_config /busybox/obj/.config
WORKDIR /busybox/obj
RUN make -j$(nproc)
RUN make install
# make initramfs from busybox
WORKDIR /busybox/initramfs 
RUN mkdir -p bin sbin etc proc sys usr/bin usr/sbin
RUN cp -av /busybox/obj/_install/* .
# pack initramfs
WORKDIR /busybox/initramfs 
ADD ./init.sh init
RUN chmod a+x init
RUN find . -print0 | cpio --null -ov --format=newc | gzip -9 > /busybox/initramfs-busybox.cpio.gz

# # 第三阶段，编译Linux内核
# WORKDIR /linux
# ADD ./linux-src src
# WORKDIR /linux/src
# RUN mkdir -p /linux/obj
# RUN make O=/linux/obj defconfig
# # https://www.kernelconfig.io/config_debug_info?q=&kernelversion=6.12.31&arch=x86
# # TODO 修改部分配置 # Compile-time checks and compiler options
# ADD .config /linux/obj/.config
# WORKDIR /linux/obj
# RUN make O=/linux/obj -j$(nproc)

# 编译linux脚本
# -v $(pwd)/linux-src:/linux/src
# -v $(pwd)/linux-obj:/linux/obj
ADD .config /.config
RUN echo "#!/bin/sh \n \
        cd /linux/src \n \
        make O=/linux/obj defconfig \n \
        cp /.config /linux/obj/.config \n \
        make O=/linux/obj -j$(nproc) \n "\
        > /usr/local/bin/build-linux.sh
RUN chmod a+x /usr/local/bin/build-linux.sh


# 启动gdb脚本
RUN echo 'add-auto-load-safe-path /linux/src/scripts/gdb/vmlinux-gdb.py' >/root/.gdbinit
RUN echo '#!/bin/sh \n \
        cd /linux/obj \n \
        gdb vmlinux -ex "target remote :1234" \n '\
        > /usr/local/bin/start-gdb.sh
RUN chmod a+x /usr/local/bin/start-gdb.sh

# 启动qemu 启动
# EXPOSE 1234
RUN echo '#!/bin/sh \n \
        qemu-system-x86_64 -kernel /linux/obj/arch/x86/boot/bzImage -initrd /busybox/initramfs-busybox.cpio.gz -nographic -append "nokaslr console=ttyS0" -s -S'\
        > /usr/local/bin/qemu-gdb.sh
RUN echo '#!/bin/sh \n \
        qemu-system-x86_64 -kernel /linux/obj/arch/x86/boot/bzImage -initrd /busybox/initramfs-busybox.cpio.gz -nographic -append "console=ttyS0"'\
        > /usr/local/bin/qemu-run.sh
RUN chmod a+x /usr/local/bin/qemu-*.sh


# 第四阶段，运行Linux内核
# 1. 使用GDB
# -s shorthand for -gdb tcp::1234
# -S freeze CPU at startup (use ’c’ to start execution)
# ENTRYPOINT ["qemu-system-x86_64","-kernel","/linux/obj/arch/x86/boot/bzImage","-initrd","/busybox/initramfs-busybox.cpio.gz","-nographic","-append","nokaslr","-s","-S"]
# 2. 直接运行 
# ENTRYPOINT ["qemu-system-x86_64","-kernel","/linux/obj/arch/x86/boot/bzImage","-initrd","/busybox/initramfs-busybox.cpio.gz","-nographic","-append","console=ttyS0"]

ENTRYPOINT ["bash"]
CMD ["build-linux.sh"]
# CMD ["qemu-run.sh"]
# CMD ["qemu-gdb.sh"]

