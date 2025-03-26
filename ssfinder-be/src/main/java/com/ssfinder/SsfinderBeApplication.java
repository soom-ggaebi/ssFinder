package com.ssfinder;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.mongodb.config.EnableReactiveMongoAuditing;

@SpringBootApplication
@EnableReactiveMongoAuditing
public class SsfinderBeApplication {

	public static void main(String[] args) {
		SpringApplication.run(SsfinderBeApplication.class, args);
	}

}
