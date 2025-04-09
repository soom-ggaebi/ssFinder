package com.ssfinder.domain.aianalyze.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ssfinder.domain.aianalyze.dto.response.AiAnalyzeResponse;
import com.ssfinder.global.common.exception.CustomException;
import com.ssfinder.global.common.exception.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;

import java.util.Base64;
import java.util.HashMap;
import java.util.Map;

/**
 * packageName    : com.ssfinder.domain.aianalyze.service<br>
 * fileName       : AiAnalyzeService*.java<br>
 * author         : sonseohy<br>
 * date           : 2025-04-04<br>
 * description    : AI 이미지 분석 서비스<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-04          sonseohy           최초생성<br>
 * 2025-04-09          sonseohy           Hugging Face API로 변경<br>
 * <br>
 */
@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class AiAnalyzeService {
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    @Value("${ai.huggingface.url}")
    private String huggingFaceUrl;

    public AiAnalyzeResponse analyzeImage(MultipartFile image) {
        try {
            // Base64로 이미지 인코딩
            String base64Image = Base64.getEncoder().encodeToString(image.getBytes());

            // JSON 요청 본문 생성
            Map<String, String> requestBody = new HashMap<>();
            requestBody.put("image", base64Image);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            HttpEntity<Map<String, String>> requestEntity = new HttpEntity<>(requestBody, headers);

            log.debug("Hugging Face API 호출: {}", huggingFaceUrl);

            // Hugging Face API로 요청 전송
            ResponseEntity<String> responseEntity = restTemplate.exchange(
                    huggingFaceUrl,
                    HttpMethod.POST,
                    requestEntity,
                    String.class
            );

            if (responseEntity.getStatusCode().is2xxSuccessful()) {
                // JSON 응답을 AiAnalyzeApiResponse로 파싱
                AiAnalyzeResponse.AiAnalyzeApiResponse apiResponse =
                        objectMapper.readValue(responseEntity.getBody(), AiAnalyzeResponse.AiAnalyzeApiResponse.class);

                return apiResponse.getData();
            } else {
                // 외부 API 오류 처리
                log.error("Hugging Face API 호출 실패: {}", responseEntity.getStatusCode());
                throw new CustomException(ErrorCode.EXTERNAL_API_ERROR);
            }

        } catch (Exception e) {
            log.error("AI 분석 중 오류 발생", e);
            throw new CustomException(ErrorCode.AI_ANALYSIS_FAILED);
        }
    }
}