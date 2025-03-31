package com.ssfinder.global.common.service;

import com.ssfinder.global.util.CustomMultipartFile;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.awscore.exception.AwsServiceException;
import software.amazon.awssdk.core.ResponseInputStream;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.*;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLConnection;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class S3Service {

    private final S3Client s3Client;

    @Value("${aws.s3.bucket}")
    private String bucketName;

    @Value("${aws.s3.prefix.found}")
    private String prefixFound;

    @Value("${aws.s3.prefix.lost}")
    private String prefixLost;

    private String filePrefixFound;
    private String filePrefixLost;

    @PostConstruct
    public void init() {
        // S3의 public URL 형식 (리전과 버킷 이름에 따라 조정)
        filePrefixFound = "https://" + bucketName + ".s3.ap-northeast-2.amazonaws.com/" + prefixFound;
        filePrefixLost  = "https://" + bucketName + ".s3.ap-northeast-2.amazonaws.com/" + prefixLost;
    }

    // UUID + 타임스탬프를 이용한 파일명 생성
    private String generateFileName(MultipartFile file) {
        String filenameExtension = StringUtils.getFilenameExtension(file.getOriginalFilename());
        String uuid = UUID.randomUUID().toString();
        return uuid + System.currentTimeMillis() + (filenameExtension != null ? "." + filenameExtension : "");
    }

    // Found 이미지 업로드
    public String uploadFoundFile(MultipartFile file) {
        String fileName = generateFileName(file);
        String key = prefixFound + fileName; // S3 키: 폴더 경로 포함
        PutObjectRequest putObjectRequest = PutObjectRequest.builder()
                .bucket(bucketName)
                .key(key)
                .contentType(file.getContentType())
                // ACL 옵션 제거하여 버킷 정책에 따름
                .build();
        try (InputStream inputStream = file.getInputStream()) {
            PutObjectResponse response = s3Client.putObject(putObjectRequest,
                    software.amazon.awssdk.core.sync.RequestBody.fromInputStream(inputStream, file.getSize()));
            if (response.sdkHttpResponse().isSuccessful()) {
                return filePrefixFound + fileName;
            } else {
                throw new RuntimeException("파일 업로드 실패");
            }
        } catch (IOException e) {
            throw new RuntimeException("파일 IO 에러", e);
        }
    }

    // Lost 이미지 업로드
    public String uploadLostFile(MultipartFile file) {
        String fileName = generateFileName(file);
        String key = prefixLost + fileName;
        PutObjectRequest putObjectRequest = PutObjectRequest.builder()
                .bucket(bucketName)
                .key(key)
                .contentType(file.getContentType())
                .build();
        try (InputStream inputStream = file.getInputStream()) {
            PutObjectResponse response = s3Client.putObject(putObjectRequest,
                    software.amazon.awssdk.core.sync.RequestBody.fromInputStream(inputStream, file.getSize()));
            if (response.sdkHttpResponse().isSuccessful()) {
                return filePrefixLost + fileName;
            } else {
                throw new RuntimeException("파일 업로드 실패");
            }
        } catch (IOException e) {
            throw new RuntimeException("파일 IO 에러", e);
        }
    }

    // 파일 업로드: type 매개변수를 통해 "found" 또는 "lost"에 따라 분기
    public String uploadFile(MultipartFile file, String type) {
        if ("found".equalsIgnoreCase(type)) {
            return uploadFoundFile(file);
        } else if ("lost".equalsIgnoreCase(type)) {
            return uploadLostFile(file);
        } else {
            throw new IllegalArgumentException("Unknown file type: " + type);
        }
    }

    // S3에서 파일 삭제 (fileUrl에서 키 추출)
    public void deleteFile(String fileUrl) {
        String fileKey;
        if (fileUrl.startsWith(filePrefixFound)) {
            fileKey = fileUrl.substring(filePrefixFound.length());
        } else if (fileUrl.startsWith(filePrefixLost)) {
            fileKey = fileUrl.substring(filePrefixLost.length());
        } else {
            fileKey = fileUrl.substring(fileUrl.indexOf("/", 8) + 1);
        }
        DeleteObjectRequest deleteObjectRequest = DeleteObjectRequest.builder()
                .bucket(bucketName)
                .key(fileKey)
                .build();
        try {
            s3Client.deleteObject(deleteObjectRequest);
        } catch (AwsServiceException e) {
            System.err.println("파일 삭제 실패: " + e.getMessage());
            throw new RuntimeException("파일 삭제 실패", e);
        }
    }

    // 기존 파일을 삭제한 후, 새로운 파일 업로드 (파일 유형은 기존 URL에 따라 결정)
    public String updateFile(String existingFileUrl, MultipartFile newFile) {
        deleteFile(existingFileUrl);
        if (existingFileUrl.contains(prefixFound)) {
            return uploadFoundFile(newFile);
        } else if (existingFileUrl.contains(prefixLost)) {
            return uploadLostFile(newFile);
        } else {
            // 기본값: found
            return uploadFoundFile(newFile);
        }
    }

    // S3에서 파일을 다운로드하여 byte 배열로 반환
    public byte[] getFileAsBytes(String fileUrl) {
        String fileKey;
        if (fileUrl.startsWith(filePrefixFound)) {
            fileKey = fileUrl.substring(filePrefixFound.length());
        } else if (fileUrl.startsWith(filePrefixLost)) {
            fileKey = fileUrl.substring(filePrefixLost.length());
        } else {
            fileKey = fileUrl.substring(fileUrl.indexOf("/", 8) + 1);
        }
        GetObjectRequest getObjectRequest = GetObjectRequest.builder()
                .bucket(bucketName)
                .key(fileKey)
                .build();
        try (ResponseInputStream<GetObjectResponse> s3Object = s3Client.getObject(getObjectRequest);
             ByteArrayOutputStream outputStream = new ByteArrayOutputStream()) {
            byte[] buffer = new byte[1024];
            int length;
            while ((length = s3Object.read(buffer)) != -1) {
                outputStream.write(buffer, 0, length);
            }
            return outputStream.toByteArray();
        } catch (IOException e) {
            throw new RuntimeException("파일 다운로드 실패", e);
        }
    }

    // S3 파일을 MultipartFile로 반환 (커스텀 MultipartFile 구현체 사용)
    public MultipartFile getFileAsMultipartFile(String fileUrl, String contentType) {
        byte[] fileBytes = getFileAsBytes(fileUrl);
        String fileKey;
        if (fileUrl.startsWith(filePrefixFound)) {
            fileKey = fileUrl.substring(filePrefixFound.length());
        } else if (fileUrl.startsWith(filePrefixLost)) {
            fileKey = fileUrl.substring(filePrefixLost.length());
        } else {
            fileKey = fileUrl.substring(fileUrl.indexOf("/", 8) + 1);
        }
        String fileName = fileKey.substring(fileKey.lastIndexOf("/") + 1);
        return new CustomMultipartFile(fileBytes, fileName, contentType);
    }

    /**
     * 외부 S3 버킷 또는 외부 링크에서 파일을 다운로드한 후,
     * 우리 S3 버킷의 found 폴더에 업로드하고 해당 URL을 반환하는 메서드.
     */
    public String uploadFileFromExternalLink(String externalFileUrl) {
        try {
            URL url = new URL(externalFileUrl);
            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
            connection.setRequestMethod("GET");
            connection.connect();
            int responseCode = connection.getResponseCode();
            if (responseCode != HttpURLConnection.HTTP_OK) {
                throw new RuntimeException("외부 파일 다운로드 실패, 응답 코드: " + responseCode);
            }
            String contentType = connection.getContentType();
            String originalFileName = null;
            String disposition = connection.getHeaderField("Content-Disposition");
            if (disposition != null && disposition.contains("filename=")) {
                int index = disposition.indexOf("filename=") + 9;
                originalFileName = disposition.substring(index);
                if (originalFileName.startsWith("\"") && originalFileName.endsWith("\"")) {
                    originalFileName = originalFileName.substring(1, originalFileName.length() - 1);
                }
            }
            if (originalFileName == null || originalFileName.isEmpty()) {
                String path = url.getPath();
                originalFileName = path.substring(path.lastIndexOf('/') + 1);
            }
            String filenameExtension = StringUtils.getFilenameExtension(originalFileName);
            String uuid = UUID.randomUUID().toString();
            String newFileName = uuid + System.currentTimeMillis() + (filenameExtension != null ? "." + filenameExtension : "");

            try (InputStream inputStream = connection.getInputStream();
                 ByteArrayOutputStream outputStream = new ByteArrayOutputStream()) {
                byte[] buffer = new byte[1024];
                int length;
                while ((length = inputStream.read(buffer)) != -1) {
                    outputStream.write(buffer, 0, length);
                }
                byte[] fileBytes = outputStream.toByteArray();

                if ("application/octet-stream".equals(contentType)) {
                    String guessedContentType = URLConnection.guessContentTypeFromName(originalFileName);
                    if (guessedContentType != null) {
                        contentType = guessedContentType;
                    }
                }

                // 기본적으로 found 폴더에 업로드 (필요에 따라 lost로 변경 가능)
                String key = prefixFound + newFileName;
                PutObjectRequest putObjectRequest = PutObjectRequest.builder()
                        .bucket(bucketName)
                        .key(key)
                        .contentType(contentType)
                        .build();

                PutObjectResponse response = s3Client.putObject(putObjectRequest,
                        software.amazon.awssdk.core.sync.RequestBody.fromBytes(fileBytes));
                if (response.sdkHttpResponse().isSuccessful()) {
                    return filePrefixFound + newFileName;
                } else {
                    throw new RuntimeException("파일 업로드 실패");
                }
            }
        } catch (IOException e) {
            throw new RuntimeException("외부 파일 처리 중 에러 발생", e);
        }
    }
}
