# Blame Thad if this breaks

snapshot() {
  if [ -z "$1" ]; then
    echo "Enter tag name: "
    read TAG
  else
    TAG=$1
  fi

  if [ -z "$TAG" ]; then
    echo "Error: Tag name is required."
    return 1
  fi

  git tag "snapshot/${TAG}"
  if [ $? -ne 0 ]; then
    echo "Error: Failed to create tag."
    return 1
  fi

  git push origin "snapshot/${TAG}"
  if [ $? -ne 0 ]; then
    echo "Error: Failed to push tag to origin."
    return 1
  fi

  echo "Tag snapshot/${TAG} created and pushed to origin successfully."
}
