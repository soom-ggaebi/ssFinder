package com.ssfinder.global.common.service;

import com.ssfinder.global.util.CustomMultipartFile;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import net.coobird.thumbnailator.Thumbnails;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

import java.io.ByteArrayOutputStream;
import java.io.IOException;

/**
 * packageName    : com.ssfinder.global.common.service<br>
 * fileName       : ImageHandler.java<br>
 * author         : leeyj<br>
 * date           : 2025-04-04<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-04          leeyj           최초생성<br>
 * <br>
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class ImageHandler {

    private final ImageProcessingService imageProcessingService;
    private final S3Service s3Service;

    /**
     * 이미지 처리 및 S3 업로드 로직을 처리합니다.
     *
     * @param image 원본 이미지 파일
     * @param fileType S3 업로드 파일 타입 (found/lost)
     * @return 업로드된 이미지 URL 또는 null
     */
    public String processAndUploadImage(MultipartFile image, String fileType) {
        if (image == null || image.isEmpty()) {
            log.info("업로드할 이미지가 없습니다.");
            return null;
        }

        String originalFilename = image.getOriginalFilename();
        log.info("원본 이미지 파일명: {}", originalFilename);

        try {
            byte[] processedImageBytes = processImageWithFallback(image);
            if (processedImageBytes == null) {
                log.error("이미지 처리 실패, 업로드 취소");
                return null;
            }

            // 파일명 JPG로 변환
            String fixedFilename = ensureJpgExtension(originalFilename);

            // 전처리된 이미지로 MultipartFile 생성
            CustomMultipartFile processedImageFile = new CustomMultipartFile(
                    processedImageBytes,
                    fixedFilename,
                    "image/jpeg"
            );

            // S3에 업로드
            String imageUrl = s3Service.uploadFile(processedImageFile, fileType);
            log.info("이미지 S3 업로드 완료: {}", imageUrl);
            return imageUrl;

        } catch (Exception e) {
            log.error("이미지 처리 또는 업로드 중 오류: {}", e.getMessage(), e);
            return null;
        }
    }

    /**
     * 이미지 처리 단계를 시도하고 실패시 대체 방법을 차례로 시도합니다.
     */
    private byte[] processImageWithFallback(MultipartFile image) {
        // 1. 표준 이미지 처리 시도
        try {
            byte[] processedBytes = imageProcessingService.processImage(image);
            log.info("표준 이미지 처리 성공");
            return processedBytes;
        } catch (Exception e) {
            log.warn("표준 이미지 처리 실패: {}", e.getMessage());
        }

        // 2. Thumbnailator 직접 사용 시도
        try {
            ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
            Thumbnails.of(image.getInputStream())
                    .size(512, 512)
                    .outputFormat("jpg")
                    .outputQuality(0.9)
                    .toOutputStream(outputStream);
            log.info("Thumbnailator 직접 변환 성공");
            return outputStream.toByteArray();
        } catch (Exception e) {
            log.warn("Thumbnailator 변환 실패: {}", e.getMessage());
        }

        // 3. 원본 이미지 바이트 사용 시도
        try {
            byte[] originalBytes = image.getBytes();
            log.info("원본 이미지 바이트 사용");
            return originalBytes;
        } catch (IOException e) {
            log.error("원본 이미지 바이트 읽기 실패: {}", e.getMessage());
        }

        return null;
    }

    /**
     * 파일명을 JPG 확장자로 변환합니다.
     */
    private String ensureJpgExtension(String filename) {
        if (filename == null || filename.isEmpty()) {
            return "image_" + System.currentTimeMillis() + ".jpg";
        }

        int dotIndex = filename.lastIndexOf('.');
        if (dotIndex > 0) {
            return filename.substring(0, dotIndex) + ".jpg";
        } else {
            return filename + ".jpg";
        }
    }
}
