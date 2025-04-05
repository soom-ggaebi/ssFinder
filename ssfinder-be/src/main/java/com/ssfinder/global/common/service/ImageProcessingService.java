package com.ssfinder.global.common.service;

import com.ssfinder.global.common.exception.CustomException;
import com.ssfinder.global.common.exception.ErrorCode;
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
import java.awt.image.LookupOp;
import java.awt.image.ShortLookupTable;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

/**
 * packageName    : com.ssfinder.global.common.service<br>
 * fileName       : ImageProcessingService.java<br>
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
    private float brightnessFactor;

    @Value("${image.processing.enabled:true}")
    private boolean imageProcessingEnabled;

    // 허용된 이미지 MIME 타입
    private static final Set<String> ALLOWED_CONTENT_TYPES = new HashSet<>(Arrays.asList(
            "image/jpeg", "image/png", "image/gif", "image/bmp"
    ));

    // 허용된 이미지 URL 도메인
    private static final Set<String> ALLOWED_URL_DOMAINS = new HashSet<>(Arrays.asList(
            "localhost.com", "ssfinder.com", "j12c105.p.ssafy.io"
    ));

    private static final long MAX_IMAGE_SIZE_BYTES = 10L * 1024 * 1024;
    private static final long HIGH_RES_PIXEL_THRESHOLD = 4000L * 4000;
    private static final long LOW_RES_PIXEL_THRESHOLD = 1000L * 1000;

    // 이미지 파일을 처리하여 바이트 배열로 반환합니다.
    public byte[] processImage(MultipartFile file) throws IOException, IllegalArgumentException {
        validateImage(file);

        // 이미지 처리 기능이 비활성화되어 있으면 원본 바이트 배열 반환
        if (!imageProcessingEnabled) {
            return file.getBytes();
        }

        try {
            return processImageBytes(file.getBytes());
        } catch (IOException e) {
            log.error("이미지 처리 실패: {}", e.getMessage(), e);
            throw new CustomException(ErrorCode.IMAGE_URL_PROCESS_FAIL);
        }
    }

    //  입력된 이미지 파일의 유효성을 검증합니다.
    private void validateImage(MultipartFile file) throws IllegalArgumentException {
        if (file == null || file.isEmpty()) {
            throw new CustomException(ErrorCode.IMAGE_FILE_NOT_PROVIDED);
        }

        String contentType = file.getContentType();
        if (contentType == null || !ALLOWED_CONTENT_TYPES.contains(contentType.toLowerCase())) {
            throw new CustomException(ErrorCode.UNSUPPORTED_IMAGE_FILE_FORMAT);
        }

        if (file.getSize() > MAX_IMAGE_SIZE_BYTES) {
            throw new CustomException(ErrorCode.IMAGE_SIZE_TOO_LARGE);
        }
    }

    // 이미지 바이트 배열을 처리하여 반환합니다.
    public byte[] processImageBytes(byte[] imageBytes) throws IOException {
        if (imageBytes == null || imageBytes.length == 0) {
            throw new CustomException(ErrorCode.IMAGE_FILE_NOT_PROVIDED);
        }

        try (ByteArrayInputStream inputStream = new ByteArrayInputStream(imageBytes);
             ByteArrayOutputStream outputStream = new ByteArrayOutputStream()) {

            // 1. 원본 이미지 로드
            BufferedImage originalImage = ImageIO.read(inputStream);
            if (originalImage == null) {
                throw new CustomException(ErrorCode.UNSUPPORTED_IMAGE_FORMAT);
            }

            BufferedImage processedImage = originalImage;

            // 2. 해상도가 낮은 이미지에 한해 선명화 필터 적용
            if ((long) originalImage.getWidth() * originalImage.getHeight() < HIGH_RES_PIXEL_THRESHOLD) {
                processedImage = applySharpening(processedImage);
            } else {
                log.info("이미지가 너무 커서 선명화 필터를 건너뜁니다: {}x{}",
                        originalImage.getWidth(), originalImage.getHeight());
            }

            // 3. 최적화된 방식으로 밝기 조정 적용
            processedImage = adjustBrightnessOptimized(processedImage, brightnessFactor);

            // 4. 이미지 리사이징 및 JPEG 변환
            Thumbnails.of(processedImage)
                    .size(imageResizeWidth, imageResizeHeight)
                    .outputQuality(imageQuality / 100.0f)
                    .outputFormat("jpg")
                    .toOutputStream(outputStream);

            return outputStream.toByteArray();

        } catch (Exception e) {
            log.error("이미지 처리 중 오류 발생: {}", e.getMessage(), e);
            // 오류 발생 시 기본 리사이징 처리로 대체
            try (ByteArrayInputStream fallbackInput = new ByteArrayInputStream(imageBytes);
                 ByteArrayOutputStream fallbackOutput = new ByteArrayOutputStream()) {
                Thumbnails.of(fallbackInput)
                        .size(imageResizeWidth, imageResizeHeight)
                        .outputQuality(imageQuality / 100.0f)
                        .outputFormat("jpg")
                        .toOutputStream(fallbackOutput);
                log.info("기본 리사이징으로 이미지 처리 완료");
                return fallbackOutput.toByteArray();
            } catch (IOException ioe) {
                log.error("대체 이미지 처리마저 실패: {}", ioe.getMessage(), ioe);
                throw new CustomException(ErrorCode.IMAGE_PROCESS_FAIL);
            }
        }
    }

    // 이미지 밝기를 최적화된 방식으로 조정합니다.
    private BufferedImage adjustBrightnessOptimized(BufferedImage image, float factor) {
        if ((long) image.getWidth() * image.getHeight() > LOW_RES_PIXEL_THRESHOLD) {
            // 대용량 이미지: LookupOp를 사용하여 빠른 밝기 조정
            short[] brightnessLUT = new short[256];
            for (int i = 0; i < 256; i++) {
                brightnessLUT[i] = (short) Math.min(255, Math.max(0, (int)(i * factor)));
            }
            BufferedImage result = new BufferedImage(image.getWidth(), image.getHeight(), BufferedImage.TYPE_INT_RGB);
            LookupOp lookupOp = new LookupOp(new ShortLookupTable(0, brightnessLUT), null);
            return lookupOp.filter(image, result);
        } else {
            // 소형 이미지: 픽셀별로 직접 밝기 조정
            BufferedImage result = new BufferedImage(image.getWidth(), image.getHeight(), BufferedImage.TYPE_INT_RGB);
            Graphics2D g2d = result.createGraphics();
            g2d.drawImage(image, 0, 0, null);
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

    // 이미지 URL에서 이미지를 다운로드하여 처리 후 바이트 배열로 반환합니다.
    public byte[] processImageFromUrl(String imageUrl) throws IOException, IllegalArgumentException {
        validateImageUrl(imageUrl);

        try (InputStream inputStream = new URL(imageUrl).openStream();
             ByteArrayOutputStream outputStream = new ByteArrayOutputStream()) {

            byte[] buffer = new byte[1024];
            int length;
            while ((length = inputStream.read(buffer)) != -1) {
                outputStream.write(buffer, 0, length);
            }
            byte[] imageBytes = outputStream.toByteArray();

            if (!imageProcessingEnabled) {
                return imageBytes;
            }
            return processImageBytes(imageBytes);
        } catch (IOException e) {
            log.error("이미지 URL 처리 실패: {}, URL: {}", e.getMessage(), imageUrl, e);
            throw new CustomException(ErrorCode.IMAGE_URL_PROCESS_FAIL);
        }
    }

    // 이미지 URL의 유효성을 검증합니다.
    private void validateImageUrl(String imageUrl) throws IllegalArgumentException {
        if (imageUrl == null || imageUrl.isEmpty()) {
            throw new CustomException(ErrorCode.IMAGE_URL_NOT_PROVIDED);
        }
        try {
            URL url = new URL(imageUrl);
            String protocol = url.getProtocol().toLowerCase();
            if (!protocol.equals("http") && !protocol.equals("https")) {
                throw new CustomException(ErrorCode.UNSUPPORTED_URL_PROTOCOL);
            }
            String host = url.getHost().toLowerCase();
            boolean allowed = ALLOWED_URL_DOMAINS.stream()
                    .anyMatch(domain -> host.equals(domain) || host.endsWith("." + domain));
            if (!allowed) {
                throw new CustomException(ErrorCode.UNSUPPORTED_URL_DOMAIN);
            }
        } catch (java.net.MalformedURLException e) {
            throw new CustomException(ErrorCode.MALFORMED_URL);
        }
    }

    // 이미지에 선명화 필터를 적용합니다.
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
}
