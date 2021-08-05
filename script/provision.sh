#! /bin/bash
set -ex

dpkg -i /mnt/root/linux*.deb

echo 'ubuntu-focal' > /etc/hostname
passwd -d root
mkdir /etc/systemd/system/serial-getty@ttyS0.service.d/
cat <<EOF > /etc/systemd/system/serial-getty@ttyS0.service.d/autologin.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root -o '-p -- \\u' --keep-baud 115200,38400,9600 %I $TERM
EOF

cat <<EOF > /etc/netplan/99_config.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: true
EOF
netplan generate

apt-get update && apt install -y curl acl

user="runner" && echo "Creating $user user" && \
  adduser --disabled-password --gecos "" runner && \
  echo "Giving $user user access to the '/home', '/usr/share', and '/opt' directories." && \
  chmod -R 777 /home && \
  echo "Step 1" && \
  setfacl -Rdm "u:$user:rwX" /home && \
  echo "Step 2" && \
  setfacl -Rb /home/runner && \
  echo "Step 3" && \
  echo "Skipping chmod -R 777 /usr/share" && \
  echo "Step 4" && \
  setfacl -Rdm "u:$user:rwX" /usr/share && \
  echo "Step 5" && \
  chmod -R 777 /opt && \
  echo "Step 6" && \
  setfacl -Rdm "u:$user:rwX" /opt && \
  echo "Step 7" && \
  mkdir -p /etc/sudoers.d && \
  echo "Step 8" && \
  echo "$user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/"$user" && \
  echo "Done with config"

sudo -u runner mkdir /home/runner/.ssh
sudo -u runner echo "<some public key>" > /home/runner/.ssh/authorized_keys

mkdir /store
pushd /store
curl -O -L https://github.com/actions/runner/releases/download/v2.279.0/actions-runner-linux-x64-2.279.0.tar.gz
tar xzf ./actions-runner-linux-x64-2.279.0.tar.gz
chmod 777 -R .
