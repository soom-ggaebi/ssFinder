package com.ssfinder.domain.aianalyze.controller;

import com.ssfinder.domain.aianalyze.dto.response.AiAnalyzeResponse;
import com.ssfinder.domain.aianalyze.service.AiAnalyzeService;
import com.ssfinder.global.common.response.ApiResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

/**
 * packageName    : com.ssfinder.domain.aianalyze.controller<br>
 * fileName       : AiAnalyzeController*.java<br>
 * author         : sonseohy<br>
 * date           : 2025-04-04<br>
 * description    : 분실물 이미지 AI 분석 처리 컨트롤러<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-04          sonseohy           최초생성<br>
 * <br>
 */
@Slf4j
@RestController
@RequestMapping("/api/aianalyze")
@RequiredArgsConstructor
public class AiAnalyzeController {
    private final AiAnalyzeService aiAnalyzeService;

    @PostMapping(value = "/image", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ApiResponse<AiAnalyzeResponse> analyzeImage(@RequestParam("image") MultipartFile image) {
        AiAnalyzeResponse response = aiAnalyzeService.analyzeImage(image);
        return ApiResponse.ok(response);
    }

}