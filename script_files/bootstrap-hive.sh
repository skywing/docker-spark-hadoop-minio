#!/bin/bash

if [ -f /metadatabase-inited ]; then
    echo "Hive metadata database initialized."
else
    echo "Initializing Hive metadata database..."
    $HIVE_HOME/bin/schematool -initSchema -dbType postgres
    touch /metadatabase-inited
    
    echo "Hive metadata database initialization completed."
    mc mb hive/tmp
    mc mb hive/user/hive/warehouse

    echo "Copying Spark local jars to hdfs /spark-jars"
    hadoop fs -mkdir -p /spark-jars
    hadoop fs -copyFromLocal ${SPARK_HOME}/jars/*.jar /spark-jars/
fi

$HIVE_HOME/bin/hiveserver2 start
$HIVE_HOME/bin/hiveserver2 --service metastore
