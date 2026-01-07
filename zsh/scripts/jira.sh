#!/bin/bash

# Jira CLI Helper Script
# Usage: jira-helper.sh <command> [args...]

# Project list - loaded from config file or default
PROJECT_CONFIG_FILE="$HOME/.jira-projects"

load_projects() {
    if [ -f "$PROJECT_CONFIG_FILE" ]; then
        PROJECTS=$(cat "$PROJECT_CONFIG_FILE")
    else
        # Default project list
        PROJECTS="WS, TRUSTED, DATA, PE, IT, ES, PLAT, AUTO, ID"
        echo "$PROJECTS" > "$PROJECT_CONFIG_FILE"
        echo "Created default project list at $PROJECT_CONFIG_FILE"
    fi
}

# Load projects at startup
load_projects

re='^[0-9]+$'

show_help() {
    echo "Jira CLI Helper"
    echo ""
    echo "Usage: $(basename $0) <command> [args...]"
    echo ""
    echo "Commands:"
    echo "  done <ticket>     - Move ticket to 'Pull to Done'"
    echo "  pull <ticket>     - Move ticket to 'Backlog Pullable' or 'Pull to Develop'"
    echo "  view <ticket>     - View ticket details"
    echo "  tickets           - List pullable tickets for the team"
    echo "  backlog           - List backlog items"
    echo "  mine              - List your active tickets"
    echo "  branch            - Select a ticket and create/checkout git branch"
    echo "  finished          - List tickets you completed in the last 10 days"
    echo "  create            - Interactively create a new ticket"
    echo "  create-ticket     - Create a ticket from command line"
    echo "                      Options:"
    echo "                        -t, --title <title>         Ticket title (required)"
    echo "                        -d, --description <desc>    Ticket description"
    echo "                        -e, --epic <epic-key>       Epic to link (e.g., WS-123)"
    echo "                        -l, --label <label>         Label (default: ws-capability)"
    echo "                      Example: j create-ticket -t 'Fix bug' -d 'Description' -e WS-123"
    echo "  move <ticket> <status> - Move ticket to specified status"
    echo "  flag              - Flag/unflag one of your active tickets"
    echo "  flag-team         - Flag/unflag any active ticket on your team's board"
    echo "  projects          - Show current project list"
    echo "  projects-refresh  - Refresh project list from Jira"
    echo "  projects-edit     - Edit project list manually"
    echo "  help              - Show this help message"
    echo ""
    echo "For other jira commands, arguments are passed directly to jira CLI"
}

process_ticket_id() {
    local input=$1
    if [[ $input =~ $re ]]; then
        echo "WS-$input"
    else
        echo "$input"
    fi
}

cmd_done() {
    if [ -z "$1" ]; then
        echo "Error: Ticket ID is required"
        echo "Usage: j done <ticket>"
        return 1
    fi
    local ticket=$(process_ticket_id "$1")
    jira issue move "$ticket" "Pull to Done"
}

cmd_pull() {
    if [ -z "$1" ]; then
        echo "Error: Ticket ID is required"
        echo "Usage: j pull <ticket>"
        return 1
    fi
    local ticket=$(process_ticket_id "$1")
    jira issue move "$ticket" "Backlog Pullable" &> /dev/null || true
    jira issue move "$ticket" "Pull to Develop"
}

cmd_view() {
    if [ -z "$1" ]; then
        echo "Error: Ticket ID is required"
        echo "Usage: j view <ticket>"
        return 1
    fi
    local ticket=$(process_ticket_id "$1")
    jira issue view "$ticket" --plain "$2"
}

cmd_tickets() {
    jira issue list -q "project in WS AND status = 'Backlog Pullable' AND 'High Availability Team' = 'Web Systems - WS' OR project = 'WS' AND status = 'Backlog Pullable'" --plain --reverse
}

cmd_backlog() {
    jira issue list -t "~Epic" -s "Backlog" -s "Backlog Pullable" --reverse --plain -q '("High Availability Team" = "Web Systems - WS" AND status = Backlog AND NOT project = "Web Systems") OR (project = "Web Systems" AND "Epic Link" is EMPTY AND status = Backlog)'
}

cmd_mine() {
    echo "Fetching your active tickets..."
    echo ""

    # Projects are already properly quoted in the config file
    local active_tickets=$(jira issue list --plain --jql "assignee = currentUser() AND project in ($PROJECTS)" | \
    grep -v Done | \
    grep -v Closed | \
    grep -v Resolved | \
    grep -v Aborted | \
    grep -v Discarded | \
    grep -v "Backlog[[:space:]]*$" | \
    grep -v "^Epic" | \
    grep -v "^TYPE")

    if [ -z "$active_tickets" ]; then
        echo "No active tickets found."
        return
    fi

    # Parse tickets into arrays for selection
    declare -a ticket_keys ticket_lines
    local counter=1

    while IFS= read -r line; do
        if [ -n "$line" ]; then
            local key=$(echo "$line" | grep -oE '[A-Z]+[A-Z0-9_-]*-[0-9]+')
            if [ -n "$key" ]; then
                ticket_keys[$counter]="$key"
                ticket_lines[$counter]="$line"
                counter=$((counter+1))
            fi
        fi
    done <<< "$active_tickets"

    # If only one ticket, auto-copy
    if [ ${#ticket_keys[@]} -eq 1 ]; then
        printf "%s" "${ticket_keys[1]}" | pbcopy
        echo "${ticket_lines[1]}"
        echo ""
        echo "Automatically copied '${ticket_keys[1]}' to clipboard!"
        return
    fi

    # Multiple tickets - show selection menu
    echo "Select a ticket to copy to clipboard:"
    echo ""
    for i in $(seq 1 ${#ticket_keys[@]}); do
        printf "%d) %s\n" "$i" "${ticket_lines[$i]}"
    done
    echo ""
    echo -n "Enter selection (1-${#ticket_keys[@]}): "
    read selection

    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le ${#ticket_keys[@]} ]; then
        local selected_ticket="${ticket_keys[$selection]}"
        printf "%s" "$selected_ticket" | pbcopy
        echo "Copied '$selected_ticket' to clipboard!"
    else
        echo "Invalid selection."
    fi
}

cmd_branch() {
    echo "Fetching your active tickets..."
    echo ""

    # Projects are already properly quoted in the config file
    local active_tickets=$(jira issue list --plain --jql "assignee = currentUser() AND project in ($PROJECTS)" | \
    grep -v Done | \
    grep -v Closed | \
    grep -v Resolved | \
    grep -v Aborted | \
    grep -v Discarded | \
    grep -v "Backlog[[:space:]]*$" | \
    grep -v "^Epic" | \
    grep -v "^TYPE")

    if [ -z "$active_tickets" ]; then
        echo "No active tickets found."
        return
    fi

    # Parse tickets into arrays for selection
    declare -a ticket_keys ticket_lines
    local counter=1

    while IFS= read -r line; do
        if [ -n "$line" ]; then
            local key=$(echo "$line" | grep -oE '[A-Z]+[A-Z0-9_-]*-[0-9]+')
            if [ -n "$key" ]; then
                ticket_keys[$counter]="$key"
                ticket_lines[$counter]="$line"
                counter=$((counter+1))
            fi
        fi
    done <<< "$active_tickets"

    # If only one ticket, auto-select
    local selected_ticket=""
    if [ ${#ticket_keys[@]} -eq 1 ]; then
        selected_ticket="${ticket_keys[1]}"
        echo "${ticket_lines[1]}"
        echo ""
        echo "Automatically selected '${selected_ticket}'"
    else
        # Multiple tickets - show selection menu
        echo "Select a ticket to create/checkout branch:"
        echo ""
        for i in $(seq 1 ${#ticket_keys[@]}); do
            printf "%d) %s\n" "$i" "${ticket_lines[$i]}"
        done
        echo ""
        echo -n "Enter selection (1-${#ticket_keys[@]}): "
        read selection

        if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le ${#ticket_keys[@]} ]; then
            selected_ticket="${ticket_keys[$selection]}"
        else
            echo "Invalid selection."
            return 1
        fi
    fi

    echo ""
    echo "Working with ticket: $selected_ticket"
    echo ""

    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "Error: Not in a git repository"
        return 1
    fi

    # Check if branch already exists (locally or remotely)
    local existing_branch=$(git branch -a | grep -E "^[* ]*$selected_ticket$|^[* ]*remotes/[^/]+/$selected_ticket$" | head -1 | sed 's/^[* ]*//' | sed 's/remotes\/[^/]*\///')

    if [ -n "$existing_branch" ]; then
        echo "Branch '$selected_ticket' already exists!"
        echo ""

        # Check if we're already on this branch
        local current_branch=$(git branch --show-current)
        if [ "$current_branch" = "$selected_ticket" ]; then
            echo "Already on branch '$selected_ticket'"
            echo "Pulling latest changes..."
            git pull
        else
            echo "Checking out to '$selected_ticket'..."
            git checkout "$selected_ticket"

            if [ $? -eq 0 ]; then
                echo "Pulling latest changes..."
                git pull
            fi
        fi
    else
        echo "Creating new branch '$selected_ticket' from master..."
        echo ""

        # Store current branch
        local current_branch=$(git branch --show-current)

        # Checkout master
        echo "Switching to master..."
        git checkout master

        if [ $? -ne 0 ]; then
            echo "Error: Failed to checkout master"
            return 1
        fi

        # Update master
        echo "Updating master..."
        git pull

        if [ $? -ne 0 ]; then
            echo "Warning: Failed to pull latest master"
        fi

        # Create and checkout new branch
        echo "Creating branch '$selected_ticket'..."
        git checkout -b "$selected_ticket"

        if [ $? -eq 0 ]; then
            echo ""
            echo "Successfully created and checked out branch '$selected_ticket' from master!"
        else
            echo "Error: Failed to create branch"
            # Try to go back to original branch
            git checkout "$current_branch" 2>/dev/null
            return 1
        fi
    fi
}

cmd_finished() {
    local ten_days_ago=$(date -j -v-10d +"%Y-%m-%d")

    echo "Finding tickets completed since $ten_days_ago..."
    echo ""

    # Projects are already properly quoted in the config file
    jira issue list --plain --jql "assignee = currentUser() AND project in ($PROJECTS) AND updated >= '$ten_days_ago'" | \
    grep -E "(Done|Closed|Resolved)" | \
    grep -v "^Epic" | \
    grep -v "^TYPE"

    if [ $? -eq 0 ]; then
        echo ""
        local count=$(jira issue list --plain --jql "assignee = currentUser() AND project in ($PROJECTS) AND updated >= '$ten_days_ago'" | grep -E "(Done|Closed|Resolved)" | grep -v "^Epic" | grep -v "^TYPE" | wc -l | tr -d ' ')
        echo "Total completed: $count tickets"
    else
        echo "No completed tickets found in the last 10 days."
    fi
}

cmd_projects() {
    echo "Current project list:"
    echo "$PROJECTS"
    echo ""
    echo "Config file: $PROJECT_CONFIG_FILE"
    echo ""
    echo "Use 'j projects-refresh' to update from Jira"
    echo "Use 'j projects-edit' to edit manually"
}

cmd_projects_refresh() {
    echo "Fetching all projects from Jira..."

    # Get all project keys and format them properly with quotes for JQL
    local raw_projects=$(jira project list | tail -n +2 | awk '{print $1}' | sort)
    local quoted_projects=""

    # Build the quoted project list
    for project in $raw_projects; do
        if [ -z "$quoted_projects" ]; then
            quoted_projects="\"$project\""
        else
            quoted_projects="$quoted_projects, \"$project\""
        fi
    done

    if [ -n "$quoted_projects" ]; then
        echo "$quoted_projects" > "$PROJECT_CONFIG_FILE"
        PROJECTS="$quoted_projects"
        echo ""
        local count=$(echo "$raw_projects" | wc -w)
        echo "Updated project list with $count projects"
        echo "Sample: $(echo "$quoted_projects" | cut -d',' -f1-3)..."
        echo ""
        echo "Saved to $PROJECT_CONFIG_FILE"
        echo "Projects are now properly quoted for JQL queries"
    else
        echo "Failed to fetch projects from Jira"
    fi
}

cmd_projects_edit() {
    echo "Current projects:"
    echo "$PROJECTS"
    echo ""
    echo "Opening $PROJECT_CONFIG_FILE in your default editor..."
    echo "Format: \"PROJECT1\", \"PROJECT2\", \"PROJECT3\""
    echo ""

    # Use the user's preferred editor
    ${EDITOR:-nano} "$PROJECT_CONFIG_FILE"

    # Reload the projects
    load_projects
    echo ""
    echo "Reloaded projects:"
    echo "$PROJECTS"
}

cmd_create() {
    echo "Creating a new ticket..."

    # Get ticket summary
    echo -n "Enter ticket summary: "
    read ticket_summary

    if [ -z "$ticket_summary" ]; then
        echo "Error: Summary cannot be empty"
        return 1
    fi

    # Get ticket description
    echo -n "Enter ticket description (optional): "
    read ticket_description

    # Choose label interactively
    echo ""
    echo "Select a label:"
    echo "1) ws-capability"
    echo "2) ws-service"
    echo "3) ws-internal"
    echo -n "Enter your choice (1-3): "
    read label_choice

    local selected_label
    case $label_choice in
        1) selected_label="ws-capability" ;;
        2) selected_label="ws-service" ;;
        3) selected_label="ws-internal" ;;
        *) echo "Invalid choice. Using default 'ws-capability'"; selected_label="ws-capability" ;;
    esac

    # Ask about epic assignment
    echo ""
    echo -n "Do you want to add this ticket to an epic? (y/N): "
    read add_to_epic

    local selected_epic=""
    if [[ "$add_to_epic" =~ ^[Yy]$ ]]; then
        echo ""
        echo "Fetching available epics..."

        # Get epics that are actively being worked on
        local epics_output=$(jira issue list --type Epic --status "Now" --status "Next" --plain 2>/dev/null)

        # If no epics in Now/Next, try broader active statuses
        if [ $? -ne 0 ] || [ -z "$epics_output" ]; then
            epics_output=$(jira issue list --type Epic --status "Open" --status "In Progress" --status "To Do" --plain 2>/dev/null)
        fi

        # Last resort: all epics except done/closed ones
        if [ $? -ne 0 ] || [ -z "$epics_output" ]; then
            epics_output=$(jira issue list --type Epic --plain 2>/dev/null | grep -v -E "(Done|Closed|Resolved|Completed|Finished)")
        fi

        if [ $? -eq 0 ] && [ -n "$epics_output" ]; then
            # Store epics data for selection
            local epics_data=$(echo "$epics_output" | tail -n +2 | grep -E '[A-Z]+-[0-9]+')

            if [ -n "$epics_data" ]; then
                echo ""
                echo "Available epics:"
                echo "0) None (don't add to epic)"

                local epic_counter=1
                echo "$epics_data" | while IFS= read -r line; do
                    local epic_key=$(echo "$line" | grep -oE '[A-Z]+-[0-9]+')
                    local rest=$(echo "$line" | sed "s/.*${epic_key}[[:space:]]*//")
                    local epic_summary=$(echo "$rest" | sed 's/\t[^\t]*$//' | sed 's/\t//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                    printf "%d) %s - %s\n" "$epic_counter" "$epic_key" "$epic_summary"
                    epic_counter=$((epic_counter+1))
                done

                echo -n "Select an epic (0 to skip): "
                read epic_choice

                if [[ "$epic_choice" =~ ^[1-9][0-9]*$ ]]; then
                    # Get the selected epic key
                    selected_epic=$(echo "$epics_data" | sed -n "${epic_choice}p" | grep -oE '[A-Z]+-[0-9]+')
                    if [ -n "$selected_epic" ]; then
                        echo "Selected epic: $selected_epic"
                    fi
                fi
            else
                echo "No epics found in backlog."
            fi
        else
            echo "Failed to fetch epics or no epics found."
        fi
    fi

    # Create the ticket
    echo ""
    echo "Creating ticket with:"
    echo "  Summary: $ticket_summary"
    echo "  Description: ${ticket_description:-'(empty)'}"
    echo "  Label: $selected_label"
    echo "  Epic: ${selected_epic:-'(none)'}"
    echo ""

    # Build the create command
    local create_args="-t 'Systems Engineering' -s '$ticket_summary' -l '$selected_label'"

    if [ -n "$ticket_description" ]; then
        create_args="$create_args -b '$ticket_description'"
    fi

    if [ -n "$selected_epic" ]; then
        create_args="$create_args -P '$selected_epic'"
    fi

    create_args="$create_args --no-input"

    # Execute the create command and capture output
    local output=$(eval "jira issue create $create_args" 2>&1)
    echo "$output"

    # Extract ticket key from output and copy to clipboard
    local ticket_key=$(echo "$output" | grep -oE '[A-Z]+[A-Z0-9_-]*-[0-9]+' | head -1)
    if [ -n "$ticket_key" ]; then
        printf "%s" "$ticket_key" | pbcopy
        echo ""
        echo "Copied '$ticket_key' to clipboard!"
    fi
}

cmd_create_ticket() {
    local title=""
    local description=""
    local epic=""
    local label="ws-capability"

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--title)
                title="$2"
                shift 2
                ;;
            -d|--description)
                description="$2"
                shift 2
                ;;
            -e|--epic)
                epic=$(process_ticket_id "$2")
                shift 2
                ;;
            -l|--label)
                label="$2"
                shift 2
                ;;
            *)
                echo "Unknown option: $1"
                echo "Use 'j help' to see usage"
                return 1
                ;;
        esac
    done

    # Validate required fields
    if [ -z "$title" ]; then
        echo "Error: Title is required"
        echo "Usage: j create-ticket -t 'Title' [-d 'Description'] [-e EPIC-123] [-l label]"
        return 1
    fi

    # Build the create command
    local create_args="-t 'Systems Engineering' -s '$title' -l '$label'"

    if [ -n "$description" ]; then
        create_args="$create_args -b '$description'"
    fi

    if [ -n "$epic" ]; then
        create_args="$create_args -P '$epic'"
    fi

    create_args="$create_args --no-input"

    # Show what we're creating
    echo "Creating ticket with:"
    echo "  Title: $title"
    echo "  Description: ${description:-'(empty)'}"
    echo "  Label: $label"
    echo "  Epic: ${epic:-'(none)'}"
    echo ""

    # Execute the create command and capture output
    local output=$(eval "jira issue create $create_args" 2>&1)
    echo "$output"

    # Extract ticket key from output and copy to clipboard
    local ticket_key=$(echo "$output" | grep -oE '[A-Z]+[A-Z0-9_-]*-[0-9]+' | head -1)
    if [ -n "$ticket_key" ]; then
        printf "%s" "$ticket_key" | pbcopy
        echo ""
        echo "Copied '$ticket_key' to clipboard!"
    fi
}

cmd_move() {
    if [ -z "$1" ]; then
        echo "Error: Ticket ID is required"
        echo "Usage: j move <ticket> <status>"
        return 1
    fi
    if [ -z "$2" ]; then
        echo "Error: Status is required"
        echo "Usage: j move <ticket> <status>"
        return 1
    fi
    local ticket=$(process_ticket_id "$1")
    jira issue move "$ticket" "$2"
}

cmd_flag_team() {
    echo "Fetching team tickets..."
    echo ""

    # Get in-progress tickets from the team board (development and test/deploy columns)
    local team_tickets=$(jira issue list --plain --columns KEY,ASSIGNEE,SUMMARY --jql "project = WS AND 'High Availability Team' = 'Web Systems - WS' AND status in ('Develop Underway', 'Test & Deploy Underway')" 2>/dev/null | \
    grep -v "^KEY")

    if [ -z "$team_tickets" ]; then
        echo "No active team tickets found."
        return
    fi

    declare -a ticket_keys ticket_lines
    local counter=1

    while IFS= read -r line; do
        if [ -n "$line" ]; then
            local key=$(echo "$line" | grep -oE '[A-Z]+[A-Z0-9_-]*-[0-9]+')
            if [ -n "$key" ]; then
                ticket_keys[$counter]="$key"
                ticket_lines[$counter]="$line"
                counter=$((counter+1))
            fi
        fi
    done <<< "$team_tickets"

    if [ ${#ticket_keys[@]} -eq 0 ]; then
        echo "No tickets found."
        return
    fi

    echo "Select a ticket to flag/unflag:"
    echo ""
    for i in $(seq 1 ${#ticket_keys[@]}); do
        printf "%d) %s\n" "$i" "${ticket_lines[$i]}"
    done
    echo ""
    echo -n "Enter selection (1-${#ticket_keys[@]}): "
    read selection

    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le ${#ticket_keys[@]} ]; then
        local selected_ticket="${ticket_keys[$selection]}"
        echo ""

        # Check current flag status
        local flag_status=$(jira issue view "$selected_ticket" --raw 2>/dev/null | grep -o '"customfield_10002":[^]]*]')

        if [[ "$flag_status" == *"Blocked/Impediment"* ]]; then
            echo "Removing flag from $selected_ticket..."
            curl -s -X PUT \
                -H "Content-Type: application/json" \
                -u "$(whoami)@ramseysolutions.com:$JIRA_API_TOKEN" \
                -d '{"fields": {"customfield_10002": []}}' \
                "https://ramseysolutions.atlassian.net/rest/api/3/issue/$selected_ticket" > /dev/null && echo "Flag removed!" || echo "Failed to remove flag"
        else
            echo "Flagging $selected_ticket..."
            curl -s -X PUT \
                -H "Content-Type: application/json" \
                -u "$(whoami)@ramseysolutions.com:$JIRA_API_TOKEN" \
                -d '{"fields": {"customfield_10002": [{"value": "Blocked/Impediment"}]}}' \
                "https://ramseysolutions.atlassian.net/rest/api/3/issue/$selected_ticket" > /dev/null && echo "Flag added!" || echo "Failed to flag ticket"
        fi
    else
        echo "Invalid selection."
    fi
}

cmd_flag() {
    echo "Fetching your active tickets..."
    echo ""

    local active_tickets=$(jira issue list --plain --jql "assignee = currentUser() AND project in ($PROJECTS)" | \
    grep -v Done | \
    grep -v Closed | \
    grep -v Resolved | \
    grep -v Aborted | \
    grep -v Discarded | \
    grep -v "Backlog[[:space:]]*$" | \
    grep -v "^Epic" | \
    grep -v "^TYPE")

    if [ -z "$active_tickets" ]; then
        echo "No active tickets found."
        return
    fi

    declare -a ticket_keys ticket_lines
    local counter=1

    while IFS= read -r line; do
        if [ -n "$line" ]; then
            local key=$(echo "$line" | grep -oE '[A-Z]+[A-Z0-9_-]*-[0-9]+')
            if [ -n "$key" ]; then
                ticket_keys[$counter]="$key"
                ticket_lines[$counter]="$line"
                counter=$((counter+1))
            fi
        fi
    done <<< "$active_tickets"

    if [ ${#ticket_keys[@]} -eq 0 ]; then
        echo "No tickets found."
        return
    fi

    local selected_ticket=""

    # Auto-select if only one ticket
    if [ ${#ticket_keys[@]} -eq 1 ]; then
        selected_ticket="${ticket_keys[1]}"
        echo "${ticket_lines[1]}"
        echo ""
        echo "Auto-selected: $selected_ticket"
    else
        echo "Select a ticket to flag/unflag:"
        echo ""
        for i in $(seq 1 ${#ticket_keys[@]}); do
            printf "%d) %s\n" "$i" "${ticket_lines[$i]}"
        done
        echo ""
        echo -n "Enter selection (1-${#ticket_keys[@]}): "
        read selection

        if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le ${#ticket_keys[@]} ]; then
            selected_ticket="${ticket_keys[$selection]}"
        else
            echo "Invalid selection."
            return 1
        fi
    fi

    # Check current flag status
    local flag_status=$(jira issue view "$selected_ticket" --raw 2>/dev/null | grep -o '"customfield_10002":[^]]*]')

    if [[ "$flag_status" == *"Blocked/Impediment"* ]]; then
        # Currently flagged, remove it
        echo "Removing flag from $selected_ticket..."
        curl -s -X PUT \
            -H "Content-Type: application/json" \
            -u "$(whoami)@ramseysolutions.com:$JIRA_API_TOKEN" \
            -d '{"fields": {"customfield_10002": []}}' \
            "https://ramseysolutions.atlassian.net/rest/api/3/issue/$selected_ticket" > /dev/null && echo "Flag removed!" || echo "Failed to remove flag"
    else
        # Not flagged, add it
        echo "Flagging $selected_ticket..."
        curl -s -X PUT \
            -H "Content-Type: application/json" \
            -u "$(whoami)@ramseysolutions.com:$JIRA_API_TOKEN" \
            -d '{"fields": {"customfield_10002": [{"value": "Blocked/Impediment"}]}}' \
            "https://ramseysolutions.atlassian.net/rest/api/3/issue/$selected_ticket" > /dev/null && echo "Flag added!" || echo "Failed to flag ticket"
    fi
}

# Main script logic
case "$1" in
    "done") cmd_done "$2" ;;
    "pull") cmd_pull "$2" ;;
    "view") cmd_view "$2" "$3" ;;
    "tickets") cmd_tickets ;;
    "backlog") cmd_backlog ;;
    "mine") cmd_mine ;;
    "branch") cmd_branch ;;
    "finished") cmd_finished ;;
    "create") cmd_create ;;
    "create-ticket") shift; cmd_create_ticket "$@" ;;
    "move") cmd_move "$2" "$3" ;;
    "flag") cmd_flag ;;
    "flag-team") cmd_flag_team ;;
    "projects") cmd_projects ;;
    "projects-refresh") cmd_projects_refresh ;;
    "projects-edit") cmd_projects_edit ;;
    "help"|"-h"|"--help") show_help ;;
    "") show_help ;;
    *)
        # Pass through to jira CLI for any other commands
        jira issue "$@" ;;
esac