runner(){
    ssh -i ~/.ssh/gitlab-runners ubuntu@$(aws ec2 describe-instances --instance-ids "$1" --query 'Reservations[*].Instances[*].PrivateIpAddress' --output text)
}

cycle_manager() {
    echo Retrieve the instance ID of the instance currently attached to the ASG...
    instance_id=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $1 --query 'AutoScalingGroups[0].Instances[0].InstanceId' --output text)

    echo Detach the instance $instance_id from the ASG
    AWS_PAGER="" aws autoscaling detach-instances --instance-ids $instance_id --auto-scaling-group-name $1 --no-should-decrement-desired-capacity

    echo Terminate instance $instance_id
    AWS_PAGER="" aws ec2 terminate-instances --instance-ids $instance_id
}

manager(){
    echo Retrieve the instance ID of the instance currently attached to the ASG...
    instance_id=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $1 --query 'AutoScalingGroups[0].Instances[0].InstanceId' --output text)
    runner $instance_id
}

clone() {
 cd ~/projects && \
 git clone $(/Users/ethan.rogers/.pyenv/shims/gitlab -o json project list --owned true --search $1 | jq -r --arg REPO "$1" '.[] | select(.path==$REPO) | .ssh_url_to_repo');
 cd $1
 code .
}