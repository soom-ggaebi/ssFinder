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


import java.net.HttpURLConnection;
import java.net.URL;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URLConnection;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class S3Service {
    private final S3Client s3Client;
    @Value("${AWS_S3_BUCKET}")
    private String bucketName;

    private String filePrefix;

    @PostConstruct
    public void init() {
        filePrefix = "https://" + bucketName + ".s3.ap-northeast-2.amazonaws.com/images/";
    }

    /*
     * 파일 업로드 전략
     * UUID + 시간값 + .확장자
     * */
    // S3 파일 업로드

    public String uploadFile(MultipartFile file) {
        String filenameExtension = StringUtils.getFilenameExtension(file.getOriginalFilename());
        String uuid = UUID.randomUUID().toString();

        // UUID + 시간값 + .확장자
        String fileName = uuid + System.currentTimeMillis() + "." +filenameExtension;
        PutObjectRequest putObjectRequest = PutObjectRequest.builder()
                .bucket(bucketName)
                .key(fileName)
                .contentType(file.getContentType())
                .acl(ObjectCannedACL.PUBLIC_READ)
                .build();

        try (InputStream inputStream = file.getInputStream()) {
            PutObjectResponse response = s3Client.putObject(putObjectRequest,
                    software.amazon.awssdk.core.sync.RequestBody.fromInputStream(inputStream, file.getSize()));

            if (response.sdkHttpResponse().isSuccessful()) {
                return filePrefix+fileName;
            } else {
                throw new RuntimeException("파일 업로드 실패");
            }
        } catch (IOException e) {
            throw new RuntimeException("파일 IO 에러");
        }
    }

    // S3 파일 삭제
    public void deleteFile(String fileUrl) {
        // S3에서의 파일 경로 추출 (filePrefix 이후의 경로만 사용)
        String fileKey = fileUrl.split("/")[3];

        DeleteObjectRequest deleteObjectRequest = DeleteObjectRequest.builder()
                .bucket(bucketName)
                .key(fileKey)
                .build();
        try{
            s3Client.deleteObject(deleteObjectRequest);
        } catch (AwsServiceException e) {
            System.err.println("파일 삭제 실패");
            throw new RuntimeException("파일 삭제 실패");
        }
    }

    /*
     * 파일 업데이트 메서드
     * 기존 파일을 삭제하고 새로운 파일을 업로드
     */
    public String updateFile(String existingFileUrl, MultipartFile newFile) throws IOException {
        // 기존 파일 삭제
        deleteFile(existingFileUrl);

        // 새 파일 업로드
        return uploadFile(newFile);
    }

    public byte[] getFileAsBytes(String fileUrl) {
        String fileKey = fileUrl.replace(filePrefix, "");

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

    public MultipartFile getFileAsMultipartFile(String fileUrl, String contentType) {
        byte[] fileBytes = getFileAsBytes(fileUrl);
        String fileKey = fileUrl.replace(filePrefix, "");
        String fileName = fileKey.substring(fileKey.lastIndexOf("/") + 1);

        return new CustomMultipartFile(fileBytes, fileName, contentType);
    }


    /**
     * 외부 S3 버킷의 파일 URL을 받아서 해당 파일을 다운로드 후,
     * 우리 S3 버킷에 업로드하고 우리 서비스의 URL을 반환하는 메서드
     *
     * @param externalFileUrl 외부 S3 버킷의 파일 URL
     * @return 우리 S3 버킷에 업로드된 파일의 URL
     */
    public String uploadFileFromExternalLink(String externalFileUrl) {
        try {
            // URL 생성 및 연결 설정
            URL url = new URL(externalFileUrl);
            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
            connection.setRequestMethod("GET");
            connection.connect();

            int responseCode = connection.getResponseCode();
            if (responseCode != HttpURLConnection.HTTP_OK) {
                throw new RuntimeException("외부 파일 다운로드 실패, 응답 코드: " + responseCode);
            }

            // 컨텐츠 타입 추출
            String contentType = connection.getContentType();

            // Content-Disposition 헤더에 파일명이 있는지 확인 (예: attachment; filename="example.png")
            String originalFileName = null;
            String disposition = connection.getHeaderField("Content-Disposition");
            if (disposition != null && disposition.contains("filename=")) {
                int index = disposition.indexOf("filename=") + 9;
                originalFileName = disposition.substring(index);
                // 양쪽에 따옴표가 붙어있으면 제거
                if (originalFileName.startsWith("\"") && originalFileName.endsWith("\"")) {
                    originalFileName = originalFileName.substring(1, originalFileName.length() - 1);
                }
            }
            // Content-Disposition에 파일명이 없으면 URL의 path에서 추출 (쿼리 파라미터 제외)
            if (originalFileName == null || originalFileName.isEmpty()) {
                String path = url.getPath(); // 예: "/prod/…/1b49f4d11fbf432e93740d3c182a41f4.png"
                originalFileName = path.substring(path.lastIndexOf('/') + 1);
            }

            // 파일 확장자 추출 (예: png)
            String filenameExtension = StringUtils.getFilenameExtension(originalFileName);

            // 새로운 파일명 생성 (uuid + 타임스탬프 + 확장자)
            String uuid = UUID.randomUUID().toString();
            String newFileName = uuid + System.currentTimeMillis() + (filenameExtension != null ? "." + filenameExtension : "");

            // 응답 스트림을 읽어 byte 배열로 변환
            try (InputStream inputStream = connection.getInputStream();
                 ByteArrayOutputStream outputStream = new ByteArrayOutputStream()) {

                byte[] buffer = new byte[1024];
                int length;
                while ((length = inputStream.read(buffer)) != -1) {
                    outputStream.write(buffer, 0, length);
                }
                byte[] fileBytes = outputStream.toByteArray();

                // 컨텐츠 타입이 기본값일 경우 파일명을 기반으로 추정 (예: 이미지 파일이면 image/png 등)
                if ("application/octet-stream".equals(contentType)) {
                    String guessedContentType = URLConnection.guessContentTypeFromName(originalFileName);
                    if (guessedContentType != null) {
                        contentType = guessedContentType;
                    }
                }

                // S3 업로드 요청 생성 및 실행
                PutObjectRequest putObjectRequest = PutObjectRequest.builder()
                        .bucket(bucketName)
                        .key(newFileName)
                        .contentType(contentType)
                        .acl(ObjectCannedACL.PUBLIC_READ)
                        .build();

                PutObjectResponse response = s3Client.putObject(putObjectRequest,
                        software.amazon.awssdk.core.sync.RequestBody.fromBytes(fileBytes));

                if (response.sdkHttpResponse().isSuccessful()) {
                    return filePrefix + newFileName;
                } else {
                    throw new RuntimeException("파일 업로드 실패");
                }
            }
        } catch (IOException e) {
            throw new RuntimeException("외부 파일 처리 중 에러 발생", e);
        }
    }

}
