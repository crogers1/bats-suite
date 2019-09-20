#!/usr/bin/env bats

@test "test blktap encryption" {

  # Create our test key
  run dd if=/dev/urandom of=/config/platform-crypto-keys/bats,aes-xts-plain,512.key bs=64 count=1
  [ ${status} -eq 0 ]

  # Create our test vhd
  run vhd-util create -n /storage/bats.vhd -s 10
  [ ${status} -eq 0 ]

  # Set the key to our test vhd
  run vhd-util key -s -n /storage/bats.vhd -k /config/platform-crypto-keys/bats,aes-xts-plain,512.key
  [ ${status} -eq 0 ]

  # Tap the new vhd
  run TAPDISK3_CRYPTO_KEYDIR="/config/platform-crypto-keys" tap-ctl create -a "vhd:/storage/bats.vhd"
  [ ${status} -eq 0 ]
  tapdev=${lines[0]}

  # Write a clear message into the tapdev. tapback should encrypt it for us
  run echo -n "secrettext" | dd of=${tapdev}
  [ ${status} -eq 0 ]

  # Close our tapdevice
  run tap-ctl destroy -d ${tapdev}
  [ ${status} -eq 0 ]

  # Check for message in the clear inside our test vhd
  run strings /storage/bats.vhd | grep "secrettext"
  [ ${status} -neq 0 ]

  # Clean up
  run rm /config/platform-crypto-keys/bats,aes-xts-plain,512.key
  [ ${status} -eq 0 ]

  run rm /storage/bats.vhd
  [ ${status} -eq 0 ]

}
