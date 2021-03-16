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

echo 'First, do a checkra1n exploit using checkra1n app which you can download from https://checkra.in (you may need to enter your PIN number)'
read -p 'Press enter when you finish'

echo ''

echo 'Continue to the "Activation Lock" screen'
read -p 'Press enter to continue'

echo ''

# Remove known_hosts file
rm ~/.ssh/known_hosts > /dev/null 2>&1

echo 'Starting iproxy'

# Run iproxy in the background
iproxy 2222:44 > /dev/null 2>&1 &

sleep 2

while true ; do
  result=$(ssh -p 2222 -o BatchMode=yes -o ConnectTimeout=1 root@localhost echo ok 2>&1 | grep Connection)

  if [ -z "$result" ] ; then

# Just so the known_hosts warning is above the 8 steps
sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no root@localhost -p 2222 ls > /dev/null 2>&1

echo '(1/8) Mounting filesystem as read-write'
sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no root@localhost -p 2222 mount -o rw,union,update /

echo '(2/8) Unloading original mobileactivationd'
sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no root@localhost -p 2222 launchctl unload /System/Library/LaunchDaemons/com.apple.mobileactivationd.plist

sleep 2

echo '(3/8) Removing original mobileactivationd'
sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no root@localhost -p 2222 rm /usr/libexec/mobileactivationd

echo '(4/8) Running uicache (this can take a few seconds)'
sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no root@localhost -p 2222 uicache --all

sleep 2

echo '(5/8) Copying patched mobileactivationd'
sshpass -p 'alpine' scp -P 2222 mobileactivationd_12_5_1_patched root@localhost:/usr/libexec/mobileactivationd

echo '(6/8) Changing patched mobileactivationd access permissions'
sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no root@localhost -p 2222 chmod 755 /usr/libexec/mobileactivationd

echo '(7/8) Loading patched mobileactivationd'
sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no root@localhost -p 2222 launchctl load /System/Library/LaunchDaemons/com.apple.mobileactivationd.plist

sleep 2

echo '(8/8) Respringing'
sshpass -p 'alpine' ssh -o StrictHostKeyChecking=no root@localhost -p 2222 killall backboardd

sleep 2

# Kill iproxy
kill %1 > /dev/null 2>&1

echo 'Done!'

echo ''

echo 'Enjoy your unlocked iDevice :)'
echo ''
read -p 'Press enter to finish'

    break

  fi

  echo 'Waiting for USB connection...'

  sleep 1

done
