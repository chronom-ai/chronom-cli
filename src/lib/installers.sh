install_eksctl() {
    yellow "# Checking eksctl version"
    if command -v eksctl >/dev/null 2>&1; then
        eksctl_version=$(eksctl version)
        required_version="0.150.0"
        
        if [[ "$(printf '%s\n' "$required_version" "$eksctl_version" | sort -V | tail -n 1)" == "$eksctl_version" ]]; then
            green "# eksctl is installed and version is greater than or equal to $required_version"
        else
            blue "# eksctl version is less than $required_version, Installing newer version"
            ARCH=amd64
            PLATFORM=$(uname -s)_$ARCH
            
            curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"
            
            tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp && rm eksctl_$PLATFORM.tar.gz
            
            sudo mv /tmp/eksctl /usr/local/bin
            
            green "# Successfully installed eksctl locally"
        fi
    else
        red "# eksctl is not installed, installing now"
        # for ARM systems, set ARCH to: `arm64`, `armv6` or `armv7`
        ARCH=amd64
        PLATFORM=$(uname -s)_$ARCH
        
        curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"
        
        tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp && rm eksctl_$PLATFORM.tar.gz
        
        sudo mv /tmp/eksctl /usr/local/bin
        
        green "# Successfully installed eksctl locally"
    fi
    
}

install_aws_cli() {
    yellow "# Checking aws CLI version"
    if command -v aws >/dev/null 2>&1; then
        aws_cli_version=$(aws --version 2>&1 | cut -d/ -f2 | cut -d' ' -f1)
        required_version="2.10.0"
        
        if [[ "$(printf '%s\n' "$required_version" "$aws_cli_version" | sort -V | tail -n 1)" == "$aws_cli_version" ]]; then
            green "# aws CLI is installed and version is greater than or equal to $required_version"
        else
            blue "# aws CLI version is less than $required_version, Installing newer version"
            curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
            unzip awscliv2.zip
            sudo ./aws/install
            green "# Successfully installed AWS CLI locally"
        fi
    else
        red "# aws CLI is not installed, installing now"
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        sudo ./aws/install
        green "# Successfully installed AWS CLI locally"
    fi
}

install_helm() {
    yellow "# Checking helm version"
    if command -v helm >/dev/null 2>&1; then
        helm_version=$(helm version --template='{{.Version}}' | cut -c2-)
        required_version="3.10.0"
        
        if [[ "$(printf '%s\n' "$required_version" "$helm_version" | sort -V | tail -n 1)" == "$helm_version" ]]; then
            green "# helm is installed and version is greater than or equal to $required_version"
        else
            blue "# helm version is less than $required_version, Installing newer version"
            curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
            chmod 700 get_helm.sh
            ./get_helm.sh
            green "# Successfully installed helm locally"
            rm get_helm.sh
        fi
    else
        red "# helm is not installed, installing now"
        curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
        chmod 700 get_helm.sh
        ./get_helm.sh
        green "# Successfully installed helm locally"
    fi
}

install_kubectl() {
    yellow "# Checking kubectl version"
    if command -v kubectl >/dev/null 2>&1; then
        kubectl_version=$(kubectl version --client=true --output yaml | grep -w "gitVersion" | awk '{print $2}' | cut -c2-)
        required_version="1.25.0"
        
        if [[ "$(printf '%s\n' "$required_version" "$kubectl_version" | sort -V | tail -n 1)" == "$kubectl_version" ]]; then
            green "# kubectl is installed and version is greater than or equal to $required_version"
        else
            blue "# kubectl version is less than $required_version, Installing newer version"
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
            
            sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
            
            green "# Successfully installed kubectl locally"
        fi
    else
        red "# kubectl is not installed, installing now"
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        
        green "# Successfully installed kubectl locally"
    fi
}