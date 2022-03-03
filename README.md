# Local Docker Development for Hadoop / Hive / Spark / Jupyter Notebook / S3 Compatible Object Storage

This is the next iteration of the [docker hadoop hive local development](https://github.com/skywing/docker-hadoop-hive) to used Spark instead of Tez for data processing, S3 compatible object store instead of hadoop distributed file system (dfs), and simplified compute cluster by using single node YARN with combined resource and node manager, and combine Hive metastore with database into single node instance.

The objective of this development environment setup is to use latest version of Spark for data development, Hive for metastore, and S3 compatible object store for persistent storage. Hive execution engine `hive.execution.engine` in hive-site.xml is set to `mr` and not Spark or Tez due to version incompatibility between Hadoop, Hive, Spark, and Tez. Mapreduce is only used for edge cases to determine how to migrate certain data processing developed in Hive SQL to Spark.

## Use of MINIO - Multi-Cloud Object Storage
[MinIO](https://min.io) offers high-performance, S3 compatible object storage and is software-defined and is 100% open source under GNU AGPL v3. MINIO is compatible with [AWS SDK for Python](https://docs.min.io/docs/how-to-use-aws-sdk-for-python-with-minio-server.html) and there is little to no changes needed for existing Python program with AWS boto3 python package to work with Amazon S3.

## Use of JupyterLab Notebook Development
[JupyterLab](https://jupyter.org) is next-generation web-based user interface for Project Jupyter. It enables you to work wit documents and activities such as Jupter notebooks, text, editors, terminals, and custom components in a flexible, integrated, and extensible manner. Jupyter Notebooks are structured data that represent your code, metadata, content, and outputs. This tool is used for data exploration, model, and code development.

## Docker Build
To build Hadoop & Spark base image
```zsh
docker build -t hadoop-spark-minio:latest --no-cache .
```

To build Hive image
```zsh
docker compose build --no-cache hive-server
```

To build Hive metastore and Postgres database image
```zsh
docker compose build --no-cache metastore-db
```

To start and run the cluster. Hive server will take time to start and initialize, you will need to give 3-5 minutes to up and running before accessing it.
```zsh
docker compose up -d
```

To stop the cluster and clean up
```zsh
docker compose down -v --remove-orphans
```



## Docker Compose
The `docker-compose.yml` contains the following services:
- `node-master` - Main node that run Spark, Yarn, and Hadoop main resources
- `node-worker1` - Worker node for Spark and data node for Hadoop
- `node-worker2` - Worker node for Spark and data node for Hadoop
- `minio-server` - MINIO node to provide S3 compatible object storage
- `hive-server`  - Hive node for Mapreduce and Hive query development
- `metastore-db` - Postgres database for Hive metastore and other use fo data development

## Configuration
- `confs/config` - For SSH client and server setup
- `core-site.xml` - Configuration values for Hadoop and MINIO integration
- `yarn-site.xml` - Configuraiton values for Yarn and Spark integration
- `mapred-site.xml` - Configuration values for YARN and Mapreduce integration
- `hive-site.xml` - Configuration values for Hive and MINIO Integration. Spark configuration values are commented out due to incompatiblity between Hive and Spark version 3.
- `hive-site-spark.xml` - Configuration values for Spark and Hive integration. This file is copied into Spark worker node as `hive-site.xml`.
- `workers` - YARN configuration to add worker/datra node to YARN. It it used by master node to communicate with worker node thru SSH
- `spark-defaults.conf` - Spark configuration values that set spark master to use `yarn` and deployMode to `client` for notebook development 

## Docker Bootstrap Scritps
- `bootstrap.sh` - Main bootstrap script for master and worker nodes
- `bootstrap-hive.sh` - Hive bootstrap script for hive server
- `init-metadata-db.sh` - Hive metadata database setup script

## Docker files
- `Dockerfile` - Base image for Hadoop and Spark with Rocky Linux as OS
- `Dockerfile.hive` - Base image for Hive with Rocky Linux as OS
- `Dockerfile.metastore-db` - Base image for Postgres database

## Test Notebooks
The notebooks folder contains 4 different notebooks that can be used to test and validate cluster environment is setup accordingly.

## Test Datasets
The datasets folder contains the data files used by the test notebooks to validate cluster environment is setup accordingly.

## Exposed UI Interfaces
- Yarn Resource and Node Manager - http://localhost:8088
- Hadoop Namenode - http://localhost:9870
- Hive Server - http://localhost:10002
- Spark Job Tracker - http://localhost:8088
- Yarn Nodes
    - http://localhost:8042
    - http://localhost:7042
    - http://localhost:9042
- MINIO - http://localhost:9001

## MINIO Login, Configuration, and Setup
In order for Hadoop, Hive, and Spark to integrate with MINIO on the backend, MINIO access and secret key are pre-generated and embedded in hive-site.xml. The Web UI login will use the access key as username and secret key as password. The use of SSL in connection is disable for development only.

```xml
.
.
<property>
    <name>fs.s3a.access.key</name>
    <value>PXASMAM2J7UX2OQG8L59</value>
</property>
<property>
    <name>fs.s3a.secret.key</name>
    <value>F75OR9jy9hRRXa0hseOocBiT+81ABXN8lmpBwkt1</value>
</property>
<property>
    <name>fs.s3a.connection.ssl.enabled</name>
    <value>false</value>
</property>
 <property>
    <name>fs.s3a.path.style.access</name>
    <value>true</value>
</property>
<property>
    <name>fs.s3a.impl</name>
    <value>org.apache.hadoop.fs.s3a.S3AFileSystem</value>
</property>
<property>
    <name>fs.s3a.endpoint</name>
    <value>minio-server:9000</value>
</property>
.
.
```

## Hive MinIO CLI Configuration and Hive Warehouse Folder Setup
To run or execute Hive query in Beeline or thru JDBC connection, it will require the temporary `/tmp` and warehouse folder `/user/hive/warehouse` created in MINIO objectstore. The `minio-config.json` configuration is copied to the Hive server folder `/root/.mc/config.json` with credential to connect MINIO server and create require folders. 

The following commands are included in the hive bootstrap.sh that will run when Hive server run for the first time to create the necessary folders.
```zsh
.
mc mb hive/tmp
mc mb hive/user/hive/warehouse
.
```

## Spark Libraries for Hadoop
The following commands are included in the hive bootstrap.sh that will run when Hive server run for the first time to create Spark library jars in the MINIO objectstore.

```zsh
.
hadoop fs -mkdir -p /spark-jars
hadoop fs -copyFromLocal ${SPARK_HOME}/jars/*.jar /spark-jars/
.
```

