#!/bin/bash

feeds_path="./scripts/feeds"

#优先安装 passwall 源
$feeds_path install -a -f -p passwall_packages
$feeds_path install -a -f -p passwall_luci
$feeds_path install -a -f -p openclash
$feeds_path install -a -f -p nikki
$feeds_path install -a -f -p gecoosac
$feeds_path install -a -f -p ddns_go
$feeds_path install -a -f -p socat