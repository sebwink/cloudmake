#!/usr/bin/env python3

import os
import sys
import yaml

PROJECT_ROOT = os.path.join(os.path.dirname(__file__), '..')

MODE, TYPES = sys.argv[1:3]
SVC = None
if len(sys.argv) == 4:
    SVC = sys.argv[3]

STACK = os.path.join(PROJECT_ROOT, '.cloudmake/scratch/stack.yml')

with open(STACK) as stack:
    config = yaml.load(stack)

if TYPES == 'all':
    if SVC is None:
        images = [
            svc['image']
            for svc_name, svc in config['services'].items()
        ]
    else:
        images = [
            svc['image']
            for svc_name, svc in config['services'].items()
            if svc_name == SVC
        ]
else:
    if SVC is None:
        images = [
            svc['image']
            for svc_name, svc in config['services'].items()
            if 'build' in svc
        ]
    else:
        images = [
            svc['image']
            for svc_name, svc in config['services'].items()
            if 'build' in svc and svc_name == SVC
        ]

sys.stdout.write('\n'.join(images)+'\n')
