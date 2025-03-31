package com.ssfinder.global.common.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import net.coobird.thumbnailator.Thumbnails;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import javax.imageio.ImageIO;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.awt.image.BufferedImageOp;
import java.awt.image.ConvolveOp;
import java.awt.image.Kernel;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;

/**
 * packageName    : com.ssfinder.global.service<br>
 * fileName       : ImageProcessingService.java<br>
 * author         : leeyj<br>
 * date           : 2025-03-31<br>
 * description    : 이미지 처리 기능을 제공하는 서비스<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-31          leeyj           최초생성<br>
 * <br>
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ImageProcessingService {

    @Value("${image.processing.resize-width:512}")
    private int imageResizeWidth;

    @Value("${image.processing.resize-height:512}")
    private int imageResizeHeight;

    @Value("${image.processing.quality:90}")
    private float imageQuality;

    @Value("${image.processing.brightness-factor:0.9}")
    private float brightnessFactor; // 1.0 = 원본, 0.9 = 10% 어둡게

    @Value("${image.processing.enabled:true}")
    private boolean imageProcessingEnabled;

    /**
     * 이미지 파일을 처리하여 바이트 배열로 반환
     * @param file 처리할 이미지 파일
     * @return 처리된 이미지 바이트 배열
     * @throws IOException 이미지 처리 중 오류 발생 시
     */
    public byte[] processImage(MultipartFile file) throws IOException {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("처리할 이미지 파일이 없습니다.");
        }

        // 이미지 처리 기능이 비활성화된 경우 원본 반환
        if (!imageProcessingEnabled) {
            return file.getBytes();
        }

        return processImageBytes(file.getBytes());
    }

    /**
     * 이미지 바이트 배열을 처리하여 반환
     * @param imageBytes 처리할 이미지 바이트 배열
     * @return 처리된 이미지 바이트 배열
     * @throws IOException 이미지 처리 중 오류 발생 시
     */
    public byte[] processImageBytes(byte[] imageBytes) throws IOException {
        try {
            // 1. 원본 이미지 로드
            BufferedImage originalImage = ImageIO.read(new ByteArrayInputStream(imageBytes));
            if (originalImage == null) {
                throw new IOException("이미지 포맷이 지원되지 않습니다.");
            }

            // 2. 이미지 처리 (선명도 향상)
            BufferedImage sharpenedImage = applySharpening(originalImage);

            // 3. 밝기 조정
            BufferedImage brightnessAdjusted = adjustBrightness(sharpenedImage, brightnessFactor);

            // 4. 이미지 리사이징 및 JPEG 변환
            ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
            Thumbnails.of(brightnessAdjusted)
                    .size(imageResizeWidth, imageResizeHeight)
                    .outputQuality(imageQuality / 100.0f)
                    .outputFormat("jpg")
                    .toOutputStream(outputStream);

            return outputStream.toByteArray();
        } catch (Exception e) {
            log.error("이미지 처리 중 오류 발생: {}", e.getMessage(), e);

            // 오류 발생 시 기본 리사이징만 적용하여 반환
            ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
            Thumbnails.of(new ByteArrayInputStream(imageBytes))
                    .size(imageResizeWidth, imageResizeHeight)
                    .outputQuality(imageQuality / 100.0f)
                    .outputFormat("jpg")
                    .toOutputStream(outputStream);

            return outputStream.toByteArray();
        }
    }

    /**
     * 이미지 URL에서 이미지를 다운로드하여 처리 후 반환
     * @param imageUrl 이미지 URL
     * @return 처리된 이미지 바이트 배열
     * @throws IOException 이미지 다운로드 또는 처리 중 오류 발생 시
     */
    public byte[] processImageFromUrl(String imageUrl) throws IOException {
        if (imageUrl == null || imageUrl.isEmpty()) {
            throw new IllegalArgumentException("처리할 이미지 URL이 없습니다.");
        }

        java.net.URL url = new java.net.URL(imageUrl);
        try (java.io.InputStream inputStream = url.openStream();
             java.io.ByteArrayOutputStream outputStream = new java.io.ByteArrayOutputStream()) {

            byte[] buffer = new byte[1024];
            int length;
            while ((length = inputStream.read(buffer)) != -1) {
                outputStream.write(buffer, 0, length);
            }

            byte[] imageBytes = outputStream.toByteArray();

            // 이미지 처리 기능이 비활성화된 경우 원본 반환
            if (!imageProcessingEnabled) {
                return imageBytes;
            }

            return processImageBytes(imageBytes);
        }
    }

    /**
     * 이미지에 선명화 필터 적용
     * @param image 원본 이미지
     * @return 선명화된 이미지
     */
    private BufferedImage applySharpening(BufferedImage image) {
        float[] sharpenKernel = {
                0.0f, -0.2f,  0.0f,
                -0.2f,  1.8f, -0.2f,
                0.0f, -0.2f,  0.0f
        };

        Kernel kernel = new Kernel(3, 3, sharpenKernel);
        BufferedImageOp op = new ConvolveOp(kernel, ConvolveOp.EDGE_NO_OP, null);
        return op.filter(image, null);
    }

    /**
     * 이미지 밝기 조정
     * @param image 원본 이미지
     * @param factor 밝기 인자 (1.0 = 원본, <1.0 = 어둡게, >1.0 = 밝게)
     * @return 밝기가 조정된 이미지
     */
    private BufferedImage adjustBrightness(BufferedImage image, float factor) {
        BufferedImage result = new BufferedImage(
                image.getWidth(),
                image.getHeight(),
                BufferedImage.TYPE_INT_RGB);

        Graphics2D g2d = result.createGraphics();
        g2d.drawImage(image, 0, 0, null);

        // 밝기 조정을 위한 RescaleOp 적용
        for (int y = 0; y < result.getHeight(); y++) {
            for (int x = 0; x < result.getWidth(); x++) {
                Color color = new Color(result.getRGB(x, y));

                int red = Math.min(255, Math.max(0, (int)(color.getRed() * factor)));
                int green = Math.min(255, Math.max(0, (int)(color.getGreen() * factor)));
                int blue = Math.min(255, Math.max(0, (int)(color.getBlue() * factor)));

                Color newColor = new Color(red, green, blue);
                result.setRGB(x, y, newColor.getRGB());
            }
        }

        g2d.dispose();
        return result;
    }
}