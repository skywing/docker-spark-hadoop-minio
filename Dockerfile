FROM rockylinux:latest

ENV JAVA_HOME /etc/alternatives/jre_1.8.0
ENV HADOOP_HOME /opt/hadoop
ENV HADOOP_CONF_DIR /opt/hadoop/etc/hadoop
ENV LD_LIBRARY_PATH=${HADOOP_HOME}/lib/native
ENV SPARK_HOME /opt/spark
ENV PATH="${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin:${SPARK_HOME}/bin:${SPARK_HOME}/sbin:${PATH}"
ENV HADOOP_VERSION 3.3.1
ENV PYSPARK_DRIVER_PYTHON=jupyter
ENV PYSPARK_DRIVER_PYTHON_OPTS='notebook'
ENV PYSPARK_PYTHON=python3
ENV HDFS_NAMENODE_USER="root"
ENV HDFS_DATANODE_USER="root"
ENV HDFS_SECONDARYNAMENODE_USER="root"
ENV YARN_RESOURCEMANAGER_USER="root"
ENV YARN_NODEMANAGER_USER="root"

RUN yum update -y && \
    yum install -y wget java-1.8.0-openjdk
RUN yum install -y openssh openssh-server openssh-clients
RUN yum install -y python39 python39-pip python39-devel
RUN yum install -y gcc gcc-c++ make
RUN yum install -y openssl-devel libffi-devel libpq-devel

COPY /confs/requirements.txt /
RUN pip3 install --upgrade pip
RUN pip install dask[bag] --upgrade
RUN pip install --upgrade toree
RUN pip3 install -r requirements.txt
# This has be after the requirements.txt. It is how it got bash_kernel installed.
RUN python3 -m bash_kernel.install

RUN wget -P /tmp/ https://dlcdn.apache.org/hadoop/common/hadoop-3.3.1/hadoop-3.3.1-aarch64.tar.gz 
RUN tar xvf /tmp/hadoop-3.3.1-aarch64.tar.gz -C /tmp && \
    mv /tmp/hadoop-3.3.1 ${HADOOP_HOME}

RUN wget -P ${HADOOP_HOME}/share/hadoop/common/lib/ https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.1/hadoop-aws-3.3.1.jar
RUN wget -P ${HADOOP_HOME}/share/hadoop/common/lib/ https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-s3/1.11.1034/aws-java-sdk-s3-1.11.1034.jar
RUN wget -P ${HADOOP_HOME}/share/hadoop/common/lib/ https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-core/1.11.1034/aws-java-sdk-core-1.11.1034.jar
RUN wget -P ${HADOOP_HOME}/share/hadoop/common/lib/ https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-dynamodb/1.11.1034/aws-java-sdk-dynamodb-1.11.1034.jar
RUN wget -P ${HADOOP_HOME}/share/hadoop/common/lib/ https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-kms/1.11.1034/aws-java-sdk-kms-1.11.1034.jar
RUN wget -P ${HADOOP_HOME}/share/hadoop/common/lib/ https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-s3/1.11.1034/aws-java-sdk-s3-1.11.1034.jar
RUN wget -P ${HADOOP_HOME}/share/hadoop/common/lib/ https://repo1.maven.org/maven2/org/apache/httpcomponents/httpclient/4.5.13/httpclient-4.5.13.jar
RUN wget -P ${HADOOP_HOME}/share/hadoop/common/lib/ https://repo1.maven.org/maven2/joda-time/joda-time/2.10.13/joda-time-2.10.13.jar

RUN wget -P /tmp/ https://dlcdn.apache.org/spark/spark-3.2.1/spark-3.2.1-bin-hadoop3.2.tgz
RUN tar xvf /tmp/spark-3.2.1-bin-hadoop3.2.tgz -C /tmp && \
    mv /tmp/spark-3.2.1-bin-hadoop3.2 ${SPARK_HOME}

RUN cp ${SPARK_HOME}/yarn/spark-3.2.1-yarn-shuffle.jar ${HADOOP_HOME}/share/hadoop/common/lib/
RUN echo "export YARN_HEAPSIZE=2000" >> /opt/hadoop/etc/hadoop/yarn-env.sh

RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
        cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
        chmod 600 ~/.ssh/authorized_keys
COPY /confs/config /root/.ssh
RUN chmod 600 /root/.ssh/config

# Require to run OpenSSH server
RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -q -N ""
RUN ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key -q -N ""
RUN ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -q -N ""
RUN ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -q -N ""

COPY /confs/core-site.xml /opt/hadoop/etc/hadoop
COPY /confs/hdfs-site.xml /opt/hadoop/etc/hadoop
COPY /confs/mapred-site.xml /opt/hadoop/etc/hadoop

COPY /confs/yarn-site.xml /opt/hadoop/etc/hadoop
COPY /confs/metastore-site.xml /opt/hadoop/etc/hadoop
COPY /confs/hive-site.xml /opt/hadoop/etc/hadoop

COPY /confs/workers /opt/hadoop/etc/hadoop
COPY /script_files/bootstrap.sh /
COPY /confs/spark-defaults.conf ${SPARK_HOME}/conf
COPY /confs/hive-site-spark.xml ${SPARK_HOME}/conf/hive-site.xml

RUN jupyter toree install --spark_home=${SPARK_HOME}
RUN echo "export JAVA_HOME=${JAVA_HOME}" >> /etc/environment

EXPOSE 9000
EXPOSE 7077
EXPOSE 4040
EXPOSE 8020
EXPOSE 22

RUN mkdir lab
COPY notebooks/*.ipynb /root/lab/
COPY datasets /root/lab/datasets

ENTRYPOINT ["/bin/bash", "bootstrap.sh"]
