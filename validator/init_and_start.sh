#!/bin/sh

# Adapted from https://github.com/nymtech/nym/blob/develop/docker/validator/init_and_start.sh

PASSPHRASE=passphrase

cd ~

if [ ! -f "/root/.nymd/config/genesis.json" ]; then
  nyxd init genesis --chain-id $CHAIN_ID 2>/dev/null
  # staking/governance token is hardcoded in config, change this
  sed -i "s/\"stake\"/\"u${STAKE_DENOM}\"/" /root/.nyxd/config/genesis.json
  sed -i 's/minimum-gas-prices = "0stake"/minimum-gas-prices = "0.025u'"${DENOM}"'"/' /root/.nyxd/config/app.toml
  sed -i '0,/enable = false/s//enable = true/g' /root/.nyxd/config/app.toml
  sed -i 's/cors_allowed_origins = \[\]/cors_allowed_origins = \["*"\]/' /root/.nyxd/config/config.toml
  sed -i 's/create_empty_blocks = true/create_empty_blocks = false/' /root/.nyxd/config/config.toml
  sed -i 's/laddr = "tcp:\/\/127.0.0.1:26657"/laddr = "tcp:\/\/0.0.0.0:26657"/' /root/.nyxd/config/config.toml

  #    create accounts
  yes "${PASSPHRASE}" | nyxd keys add node_admin 2>&1 >/dev/null | tail -n 1 >/root/.nyxd/mnemonic
  yes "${PASSPHRASE}" | nyxd keys add secondary 2>&1 >/dev/null | tail -n 1 >/root/.nyxd/secondary_mnemonic
  cp /root/.nyxd/mnemonic /genesis_volume/genesis_mnemonic
  cp /root/.nyxd/secondary_mnemonic /genesis_volume/secondary_mnemonic

  #    add genesis accounts with some initial tokens
  GENESIS_ADDRESS=$(yes "${PASSPHRASE}" | nyxd keys show node_admin -a)
  SECONDARY_ADDRESS=$(yes "${PASSPHRASE}" | nyxd keys show secondary -a)
  yes "${PASSPHRASE}" | nyxd genesis add-genesis-account "${GENESIS_ADDRESS}" 1000000000000000u"${DENOM}",1000000000000000u"${STAKE_DENOM}"
  yes "${PASSPHRASE}" | nyxd genesis add-genesis-account "${SECONDARY_ADDRESS}" 1000000000000000u"${DENOM}",1000000000000000u"${STAKE_DENOM}"

  yes "${PASSPHRASE}" | nyxd genesis gentx node_admin 1000000000000u"${STAKE_DENOM}" --chain-id $CHAIN_ID 2>&1 >/dev/null
  nyxd genesis collect-gentxs
  nyxd genesis validate-genesis
  cp /root/.nyxd/config/genesis.json /genesis_volume/genesis.json
else
  echo "Validator already initialized, starting with the existing configuration."
  echo "If you want to re-init the validator, destroy the existing container"
fi
nyxd start
