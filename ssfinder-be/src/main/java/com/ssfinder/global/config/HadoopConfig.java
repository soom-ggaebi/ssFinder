package com.ssfinder.global.config;

import org.apache.hadoop.fs.FileSystem;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;

import java.net.URI;

@Configuration
public class HadoopConfig {

    @Value("${spring.hdfs.url}")
    private String hdfsUri;

    @Value("${spring.hdfs.user}")
    private String hadoopUser;

    @Bean
    @Primary
    public org.apache.hadoop.conf.Configuration configuration() {
        System.setProperty("HADOOP_USER_NAME", hadoopUser);

        org.apache.hadoop.conf.Configuration conf = new org.apache.hadoop.conf.Configuration();
        conf.set("fs.defaultFS", hdfsUri);

        return conf;
    }

    @Bean
    public FileSystem fileSystem(org.apache.hadoop.conf.Configuration configuration) throws Exception {
        return FileSystem.get(new URI(hdfsUri), configuration, hadoopUser);
    }
}