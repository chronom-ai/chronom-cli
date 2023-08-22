yellow "# Setting up AWS CloudShell with the required dependencies"

yellow "# Installing OpenSSL"

sudo yum install -y openssl

install_eksctl

install_helm

green "# Successfully configured AWS CloudShell with the required dependencies"