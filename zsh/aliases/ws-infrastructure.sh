# TODO:  convert these to functions, accept args for create_stack.py then call 'assume --un' at the end to cleanup creds
alias kt="assume core-test && python create_stack.py -e test"
alias kq="assume core-qa && python create_stack.py -e qa"
alias kp="assume core-prod && python create_stack.py -e prod"
alias km="assume core-prod && python create_stack.py -e mgt"