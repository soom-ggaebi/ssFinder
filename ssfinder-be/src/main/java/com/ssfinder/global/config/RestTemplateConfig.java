package com.ssfinder.global.config;


import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;

/**
 * packageName    : com.ssfinder.global.config<br>
 * fileName       : RestTemplateConfig*.java<br>
 * author         : sonseohy<br>
 * date           : 2025-04-04<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-04          sonseohy           최초생성<br>
 * <br>
 */
@Configuration
public class RestTemplateConfig
{
    @Bean
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }
}