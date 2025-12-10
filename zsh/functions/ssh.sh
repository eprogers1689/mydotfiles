login() {
  ssh ansible@$1 -i ~/.ssh/ansible
}

glssh () {
  ssh ubuntu@$1 -i ~/.ssh/gitlab-runners
}