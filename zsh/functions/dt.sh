dt(){
    case $1 in
      [Tt])
        echo $(grep "test" ~/.dynatrace_token | awk '{print $3}') | tr -d '\n' | pbcopy
        echo "Copied test token to clipboard"
        ;;
      [Pp])
        echo $(grep "prod" ~/.dynatrace_token | awk '{print $3}') | tr -d '\n' | pbcopy
        echo "Copied prod token to clipboard"
        ;;
      *)
        echo "Invalid selection - use 'dt t' for test or 'dt p' for prod."
        ;;
    esac
}