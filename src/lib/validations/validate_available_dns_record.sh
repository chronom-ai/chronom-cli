validate_available_dns_record() {
    [[ $(echo "$1" | grep -o "\." | wc -l) -ge 2 ]] || echo "Please enter a valid DNS Record."
}