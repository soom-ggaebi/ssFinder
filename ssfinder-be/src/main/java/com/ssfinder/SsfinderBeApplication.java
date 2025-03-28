package com.ssfinder;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.mongodb.config.EnableMongoAuditing;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

import javax.annotation.PostConstruct;

import java.util.TimeZone;

@SpringBootApplication
@EnableJpaAuditing
@EnableMongoAuditing
public class SsfinderBeApplication {

	public static void main(String[] args) {
		SpringApplication.run(SsfinderBeApplication.class, args);
	}

	@PostConstruct
	public void init() {
		TimeZone.setDefault(TimeZone.getTimeZone("Asia/Seoul"));
	}

}
