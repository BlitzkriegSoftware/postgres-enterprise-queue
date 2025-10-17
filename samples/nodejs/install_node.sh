#!/usr/bin/env bash
apt update
apt upgrade -y
apt install nodejs -y
apt install npm -y
nov=$(node -v)
npv=$(npm -v)
echo "Node: ${nov}, NPM: ${npv}"
cd /var/lib/postgresql/src