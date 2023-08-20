yellow "# Installing kubectl locally"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

green install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl