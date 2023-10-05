re='^[0-9]+$'
j(){
  if [[ $2 =~ $re ]] ; then
    TICKET="WS-$2"
  else
    TICKET=$2
  fi
  case $1 in
    done)
      jira issue move $TICKET "Pull to Done"
      ;;
    pull)
      jira issue move $TICKET "Backlog Pullable" &>/dev/null || true
      jira issue move $TICKET "Pull to Develop"
      ;;
    view)
      jira issue view $TICKET --plain $3
      ;;
    tickets)
      jira issue list -q "project in $RamseyProjectList AND status = 'Backlog Pullable' AND 'High Availability Team' = 'Web Systems - WS' OR project = 'WS' AND status = 'Backlog Pullable'" --plain --reverse
      ;;
    backlog)
      jira issue list -t "~Epic" -s "Backlog" -s "Backlog Pullable" --reverse --plain -q '("High Availability Team" = "Web Systems - WS" AND status = Backlog AND NOT project = "Web Systems") OR (project = "Web Systems" AND "Epic Link" is EMPTY AND status = Backlog)'
      ;;
    mine)
      jira issue list -a $(jira me) --plain -q "project in $RamseyProjectList AND status not in (Done,Aborted,Discarded,Abandon)"
      ;;
    create)
      jira issue create -t "Systems Engineering" -s $TICKET -l ${3:-'ws-capability'} -b ${4:-" "} --no-input
      ;;
    move)
      jira issue $1 $TICKET $3
      ;;
    *)
      jira issue $@
  esac
}

export RamseyProjectList="('ACCH','AN','ANREQ','AUTO','BS','CE','CIAM','CME','CONPROD','CONTRACT','CPT','CRM','CRMSD','DATA','DATAREQ','DEBIT','DNA','DT','ELPCRM','EMAIL','ENTRE','ES','ETP','ETP2','FPC','FWCRM','FWOPS','GW','HRIS','ICM','IF','IMREQ','INNER','INT','INTRANET','IT','ITINFRA','ITOPS','JA','JIRA','JSD','JSDAPPR','LE','MARTECH','MM','MMT','MR', 'MULE','NETWORK','NS','NSD','OPT','PER','PHOTO','PHOTOREQ','PIT','PJM','PM','PR','PROC','PRODSETUP','PRODUCT','PTJ','PTM','PUB','PUBLICITY','RA','RECRM','REDA','RESO','RMCRM','RPLUS','RSCOM','RSMOR','SD','SDCC','SOCIAL','STAFF','STAFF2','STS','TBD','TBP','TEST','TOUR','TOUR2','TOURS','TPD','TRAIN','TRUSTED','VIDEO','WS','ZDSK')"
