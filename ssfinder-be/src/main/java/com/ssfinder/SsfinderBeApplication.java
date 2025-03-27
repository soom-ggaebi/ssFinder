package com.ssfinder;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.mongodb.config.EnableMongoAuditing;

@SpringBootApplication
@EnableMongoAuditing
public class SsfinderBeApplication {

	public static void main(String[] args) {
		SpringApplication.run(SsfinderBeApplication.class, args);
	}

}
