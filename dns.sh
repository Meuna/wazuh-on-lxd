#!/bin/bash
resolvectl dns wazuh $(lxc network get wazuh ipv4.address | cut -d'/' -f1)
resolvectl domain wazuh '~wazuh.local'