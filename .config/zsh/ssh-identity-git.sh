#!/run/current-system/sw/bin/sh

cat > ~/.ssh/config <<EOF
Host github.com
User git
IdentityFile  $1
IdentitiesOnly yes
EOF