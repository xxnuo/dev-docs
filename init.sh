#!/bin/bash
# Debian 12 bookworm 虚拟机配置
su -
sudo usermod -aG sudo xxnuo

sudo sed -i 's/deb.debian.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list
echo """
export HTTP_PROXY=http://192.168.1.200:7890
export HTTPS_PROXY=http://192.168.1.200:7890
export ALL_PROXY=http://192.168.1.200:7890
export NO_PROXY=localhost,127.0.0.1,192.168.1.200
export LANG=zh_CN.UTF-8
export LANGUAGE=zh_CN:en_US
""" >>~/.bashrc
source ~/.bashrc
sudo apt update
sudo apt install apt-transport-https ca-certificates curl btop wget vim git build-essential cmake

# sshd
sudo apt install openssh-server
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
sudo sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sudo systemctl restart sshd
sudo systemctl status sshd
sudo systemctl enable sshd

# openvmtools
sudo apt install open-vm-tools
sudo systemctl start vmtoolsd
sudo systemctl status vmtoolsd
sudo systemctl enable vmtoolsd
sudo systemctl start vmware-vmblock-fuse
sudo systemctl status vmware-vmblock-fuse
sudo systemctl enable vmware-vmblock-fuse
sudo mkdir /mnt/hgfs
sudo echo ".host:/ /mnt/hgfs fuse.vmhgfs-fuse defaults,allow_other 0 0" >>/etc/fstab
sudo mount -a

# Github Desktop
wget -qO - https://mirror.mwt.me/shiftkey-desktop/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/mwt-desktop.gpg >/dev/null
sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/mwt-desktop.gpg] https://mirror.mwt.me/shiftkey-desktop/deb/ any main" > /etc/apt/sources.list.d/mwt-desktop.list'
sudo apt-get update
sudo apt-get install github-desktop

# 懒猫微服
/bin/bash -c "$(curl -fsSL https://dl.lazycat.cloud/client/desktop/linux-install)"

# hportal-client
wget https://gitee.com/lazycatcloud/hclient-cli/releases/download/latest/hclient-cli-linux-amd64
chmod +x hclient-cli-linux-amd64
sudo mv hclient-cli-linux-amd64 /home/xxnuo/.local/bin/hportal-client
echo """
[Unit]
Description=hportal-client
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
ExecStart=/home/xxnuo/.local/bin/hportal-client -cfg /home/xxnuo/.config/hportal-client -tun -disable-api
Restart=on-failure
RestartSec=5s
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
""" | sudo tee /etc/systemd/system/hportal-client.service >/dev/null

/home/xxnuo/.local/bin/hportal-client -cfg /home/xxnuo/.config/hportal-client
curl -X POST 'http://127.0.0.1:7777/add_box?bname=wl1&uid=taurus&password=taurus'
curl -X POST 'http://127.0.0.1:7777/add_tfa?bname=wl1&tfa=174711'
sudo systemctl daemon-reload
sudo systemctl start hportal-client
sudo systemctl status hportal-client
sudo systemctl enable hportal-client

# Add Docker's official GPG key:
sudo apt-get update
sudo apt install -y uidmap dbus-user-session fuse-overlayfs slirp4netns
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian bookworm stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
sudo apt-get update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
USER=xxnuo
if ! grep -q "^$USER:" /etc/subuid; then sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 $USER; fi
grep "$USER" /etc/subuid
grep "$USER" /etc/subgid
dockerd-rootless-setuptool.sh install
echo "export DOCKER_HOST='unix:///run/user/$(id -u)/docker.sock'" >>~/.bashrc
source ~/.bashrc

# 开发 SDK
curl -fsSL https://fnm.vercel.app/install | bash
fnm install 24
npm config set registry https://registry.npmmirror.com
source ~/.bashrc

curl -fsSL https://get.pnpm.io/install.sh | sh -
source ~/.bashrc
pnpm config set registry https://registry.npmmirror.com

curl -LsSf https://astral.sh/uv/install.sh | sh
mkdir -p ~/.config/uv
echo """
[[tool.uv.index]]
url = "https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple"
default = true
""" >> ~/.config/uv/config.toml

wget https://go.dev/dl/go1.24.4.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.24.4.linux-amd64.tar.gz
echo "export PATH=\$PATH:/usr/local/go/bin:\$HOME/go/bin" >> ~/.bashrc
source ~/.bashrc
go env -w GO111MODULE=on
go env -w  GOPROXY=https://goproxy.cn,direct
go env | grep GOPROXY
