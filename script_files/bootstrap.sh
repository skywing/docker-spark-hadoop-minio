#!/bin/bash
hdfs namenode -format
/usr/sbin/sshd
if [ "$HOSTNAME" = node-master ]; then
    start-dfs.sh
    start-yarn.sh
    cd /root/lab
    # jupyter trust Bash-Interface.ipynb
    # jupyter trust Dask-Yarn.ipynb
    # jupyter trust Python-Spark.ipynb
    # jupyter trust Scala-Spark.ipynb
    jupyter notebook --app_dir=/root/lab/ --ip=0.0.0.0 --port=8888 --no-browser --allow-root --NotebookApp.token='' --NotebookApp.password='' &
fi
while :; do :; done & kill -STOP $! && wait $!