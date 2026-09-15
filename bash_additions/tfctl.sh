#!/bin/bash

tfctl() {
    if [ -z "$0" ]; then
        $PYTHON3 $SNAKES/clis/tfctl/tfctl.py
    else
        $PYTHON3 $SNAKES/clis/tfctl/tfctl.py "${@:1}"
    fi
}

tfvars() {
    if [ -z "$0" ]; then
        $PYTHON3 $SNAKES/clis/tfctl/tfvars.py
    else
        $PYTHON3 $SNAKES/clis/tfctl/tfvars.py "${@:1}"
    fi
}

tfwks() {
    if [ -z "$0" ]; then
        $PYTHON3 $SNAKES/clis/tfctl/tfwks.py
    else
        $PYTHON3 $SNAKES/clis/tfctl/tfwks.py "${@:1}"
    fi
}

tfbatch() {
    if [ -z "$0" ]; then
        $PYTHON3 $SNAKES/clis/tfctl/tfbatch.py
    else
        $PYTHON3 $SNAKES/clis/tfctl/tfbatch.py "${@:1}"
    fi
}

tfruns() {
    if [ -z "$0" ]; then
        $PYTHON3 $SNAKES/clis/tfctl/tfruns.py
    else
        $PYTHON3 $SNAKES/clis/tfctl/tfruns.py "${@:1}"
    fi
}

tfvsets() {
    if [ -z "$0" ]; then
        $PYTHON3 $SNAKES/clis/tfctl/tfvsets.py
    else
        $PYTHON3 $SNAKES/clis/tfctl/tfvsets.py "${@:1}"
    fi
}
