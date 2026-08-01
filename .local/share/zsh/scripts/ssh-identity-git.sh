#!/run/current-system/sw/bin/zsh

echo "#!/run/current-system/sw/bin/zsh" > ~/.ssh/config
echo "Host github.com" >> ~/.ssh/config
echo "  HostName github.com" >> ~/.ssh/config
echo "  User git" >> ~/.ssh/config
echo '  IdentityFile ' $1 >> ~/.ssh/config
echo "  IdentitiesOnly yes" >> ~/.ssh/config