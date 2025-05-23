re='^[0-9]+$'
j () {
	if [[ $2 =~ $re ]]
	then
		TICKET="WS-$2"
	else
		TICKET=$2
	fi
	case $1 in
		(help)
      echo "Usage: j <command> [options]"
      echo "Commands:"
      echo "  done <ticket>             Move a Jira issue to 'Pull to Done' status."
      echo "  pull <ticket>             Move a Jira issue to 'Backlog Pullable' or 'Pull to Develop' status."
      echo "  view <ticket> [options]   View details of a Jira issue."
      echo "  tickets                   List Jira issues in 'Backlog Pullable' status."
      echo "  backlog                   List Jira issues in 'Backlog' or 'Backlog Pullable' status."
      echo "  mine                      List Jira issues assigned to you."
      echo "  minedone                  List Jira issues assigned to you that were resolved in last 30 days."
      echo "  create <ticket> [label] [description] Create a new Jira issue."
      echo "  move <ticket> <status>    Move a Jira issue to a specified status."
      echo "  help                      Display this help message."
      echo "  s <line_number>           Copy Jira issue key from the Nth line of 'mine' to clipboard."
      echo "  ts <line_number>          Copy Jira issue key from the Nth line of 'tickets' command to clipboard."
    ;;
    (--help) j help ;;
		(done) jira issue move $TICKET "Pull to Done" ;;
		(pull) jira issue move $TICKET "Backlog Pullable" &> /dev/null || true
			jira issue move $TICKET "Pull to Develop" ;;
		(view) jira issue view $TICKET --plain $3 ;;
		(tickets) jira issue list -q "project in $RamseyProjectList AND status = 'Backlog Pullable' AND 'High Availability Team' = 'Web Systems - WS' OR project = 'WS' AND status = 'Backlog Pullable'" --plain --reverse ;;
		(backlog) jira issue list -t "~Epic" -s "Backlog" -s "Backlog Pullable" --reverse --plain -q '("High Availability Team" = "Web Systems - WS" AND status = Backlog AND NOT project = "Web Systems") OR (project = "Web Systems" AND "Epic Link" is EMPTY AND status = Backlog)' ;;
		(mine) jira issue list -a $(jira me) --plain -q "project in $RamseyProjectList AND status not in (Done,Aborted,Discarded,Abandoned)" ;;
		(minedone) jira issue list -a $(jira me) --plain -q "project in $RamseyProjectList AND status = 'Done' AND resolved >= -30d" ;;
		(create) jira issue create -t "Systems Engineering" -s $TICKET -l ${3:-'ws-capability'} -b ${4:-" "} --no-input ;;
		(move) jira issue $1 $TICKET $3 ;;
        (s) j mine | grep -Eo '[A-Z]+-[0-9]+' | awk -v line_number=$2 'NR==line_number' | tr -d '\n' | pbcopy ;;
        (ts) j tickets | grep -Eo '[A-Z]+-[0-9]+' | awk -v line_number=$2 'NR==line_number' | tr -d '\n' | pbcopy ;;
		(*) jira issue $@ ;;
	esac
}

# TODO: put this in a file and then source it then write a function to update whenever Chad breaks it...
export RamseyProjectList="('ACCH','AN','AUTO','BS','CE','CIAM','CME','CONPROD','CRM','CRMSD','DATA','DATAREQ','DEBIT','DNA','DT','EMAIL','ENTRE','ES','FPC','FWCRM','FWOPS','GW','HRIS','INNER','INT','IT','ITINFRA','ITOPS','JA','JIRA','LE','MARTECH','MM','MMT','MR', 'MULE','NETWORK','NS','NSD','OPT','PER','PHOTO','PJM','PM','PR','PROC','PRODUCT','PUB','RECRM','RMCRM','RPLUS','RSCOM','RSMOR','SD','SOCIAL','STAFF','STAFF2','STS','TEST','TOURS','TRAIN','TRUSTED','VIDEO','WS','ZDSK')"

