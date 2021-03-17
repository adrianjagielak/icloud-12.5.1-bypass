clear
echo ''
echo ''
echo 'Copyright © Adrian Jagielak (https://github.com/adrianjagielak)'
echo ''
echo ''

# Change the current working directory
cd "`dirname "$0"`"

# Check for Homebrew, install if we don't have it
if test ! $(which brew); then
    echo "Installing homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" > /dev/null 2>&1
    echo ''
fi

# Check for sshpass, install if we don't have it
if test ! $(which sshpass); then
    echo "Installing sshpass..."
    brew install esolitos/ipa/sshpass > /dev/null 2>&1
    echo ''
fi

# Check for iproxy, install if we don't have it
if test ! $(which iproxy); then
    echo "Installing iproxy..."
    brew install libimobiledevice > /dev/null 2>&1
    echo ''
fi

echo 'First, do a checkra1n exploit using checkra1n app which you can download from https://checkra.in'
read -p 'Press enter when you finish'

echo ''

echo 'Continue to the "Choose a Wi-Fi Network" screen but do not connect to a network'
read -p 'Press enter to continue'

echo ''

echo 'Starting iproxy...'

# Run iproxy in the background
iproxy 2222:44 > /dev/null 2>&1 &

sleep 2

while true ; do
  result=$(ssh -p 2222 -o BatchMode=yes -o ConnectTimeout=1 root@localhost echo ok 2>&1 | grep Connection)

  if [ -z "$result" ] ; then

echo '(1/7) Mounting filesystem as read-write'
sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@localhost -p 2222 mount -o rw,union,update / > /dev/null 2>&1

echo '(2/7) Unloading original mobileactivationd'
sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@localhost -p 2222 launchctl unload /System/Library/LaunchDaemons/com.apple.mobileactivationd.plist > /dev/null 2>&1

sleep 2

echo '(3/7) Removing original mobileactivationd'
sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@localhost -p 2222 rm /usr/libexec/mobileactivationd > /dev/null 2>&1

echo '(4/7) Running uicache (this can take a few seconds)'
sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@localhost -p 2222 uicache --all > /dev/null 2>&1

sleep 2

echo '(5/7) Copying patched mobileactivationd'
sshpass -p 'alpine' scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -P 2222 mobileactivationd_12_5_1_patched root@localhost:/usr/libexec/mobileactivationd > /dev/null 2>&1

echo '(6/7) Changing patched mobileactivationd access permissions'
sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@localhost -p 2222 chmod 755 /usr/libexec/mobileactivationd > /dev/null 2>&1

echo '(7/7) Loading patched mobileactivationd'
sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@localhost -p 2222 launchctl load /System/Library/LaunchDaemons/com.apple.mobileactivationd.plist > /dev/null 2>&1

sleep 2

# Kill iproxy
kill %1 > /dev/null 2>&1

echo 'Done!'

echo ''

echo 'Select "Connect to iTunes" option on device to complete bypass and enjoy your new unlocked iDevice :)'
echo ''
read -p 'Press enter to finish'

    break

  fi

  echo 'Waiting for USB connection...'

  sleep 1

done
