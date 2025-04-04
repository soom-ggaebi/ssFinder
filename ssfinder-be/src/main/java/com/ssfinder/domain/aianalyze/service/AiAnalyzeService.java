package com.ssfinder.domain.aianalyze.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ssfinder.domain.aianalyze.dto.response.AiAnalyzeResponse;
import com.ssfinder.global.common.exception.CustomException;
import com.ssfinder.global.common.exception.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;

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
 * <br>
 */
@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class AiAnalyzeService {
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    @Value("${ai.fastapi.url}")
    private String fastApiUrl;

    public AiAnalyzeResponse analyzeImage(MultipartFile image) {
        try {
            MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();

            // 파일 바이너리 추가
            ByteArrayResource fileResource = new ByteArrayResource(image.getBytes()) {
                @Override
                public String getFilename() {
                    return image.getOriginalFilename();
                }
            };

            body.add("file", fileResource);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.MULTIPART_FORM_DATA);

            HttpEntity<MultiValueMap<String, Object>> requestEntity = new HttpEntity<>(body, headers);

            // FastAPI 서버로 요청 전송
            String requestUrl = fastApiUrl + "/analyze";

            ResponseEntity<String> responseEntity = restTemplate.exchange(
                    requestUrl,
                    HttpMethod.POST,
                    requestEntity,
                    String.class
            );

            if (responseEntity.getStatusCode().is2xxSuccessful()) {
                AiAnalyzeResponse.AiAnalyzeApiResponse apiResponse =
                        objectMapper.readValue(responseEntity.getBody(), AiAnalyzeResponse.AiAnalyzeApiResponse.class);

                return apiResponse.getData();
            } else {
                throw new CustomException(ErrorCode.EXTERNAL_API_ERROR);
            }

        } catch (Exception e) {
            throw new CustomException(ErrorCode.AI_ANALYSIS_FAILED);
        }
    }
}