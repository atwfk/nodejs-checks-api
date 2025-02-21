#!/bin/bash

 aws ec2 create-launch-template-version \
    --launch-template-id lt-079c3b57b594f0103 \
    --source-version 1 \
    --launch-template-data "ImageId=ami-ami-055943271915205db"