validate_eks_cluster_name_length() {
  [[ ${#1} -le 15 ]] || echo "must be less than or equal to 15 characters"
}