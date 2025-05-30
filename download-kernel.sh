#!/bin/bash

wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.12.31.tar.xz
tar -xvJf linux-6.12.31.tar.xz
mv linux-6.12.31 linux-src

mkdir -p linux-obj
