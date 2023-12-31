yellow "# To configure auto complete for chronom-cli, please run the following command:"

bold 'alias chronom-cli="./chronom-cli" && eval "$(./chronom-cli completions)"'

magenta "# Alternatively, you can run the same command with the --update-bashrc flag to automatically update your ~/.bashrc file"

BASHRC=~/.bashrc

if [ -x "./chronom-cli" ]; then
    
    if [ "${args[--update-bashrc]}" ]; then
        yellow "# Updating ~/.bashrc"
        if ! grep -q "alias chronom-cli=\"${PWD}/chronom-cli\"" "$BASHRC"; then
            echo "alias chronom-cli=\"${PWD}/chronom-cli\"" >> "$BASHRC"
        fi
        if ! grep -q "eval \"\$(${PWD}/chronom-cli completions)\"" "$BASHRC"; then
            echo "eval \"\$(${PWD}/chronom-cli completions)\"" >> "$BASHRC"
        fi
        green '# ~/.bashrc updated successfully'
        green '# Please run the following command to reload your ~/.bashrc file'
        green 'source ~/.bashrc'
    fi
else
    red "# Error: chronom-cli not found in current directory"
fi