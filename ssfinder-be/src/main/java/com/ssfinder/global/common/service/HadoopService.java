package com.ssfinder.global.common.service;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FSDataInputStream;
import org.apache.hadoop.fs.FSDataOutputStream;
import org.apache.hadoop.fs.FileStatus;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;

@Service
public class HadoopService {
    private static final Logger logger = LoggerFactory.getLogger(HadoopService.class);

    private final FileSystem fileSystem;
    private final Configuration configuration;

    @Value("${hdfs.prefix.found.img}")
    private String foundImgPrefix;

    @Value("${hdfs.prefix.lost.img}")
    private String lostImgPrefix;

    @Autowired
    public HadoopService(FileSystem fileSystem, Configuration configuration) {
        this.fileSystem = fileSystem;
        this.configuration = configuration;
    }

    /**
     * 이미지 파일을 HDFS에 저장합니다.
     * @param filePath 저장할 경로
     * @param imageData 이미지 바이트 배열
     * @return 성공 여부
     */
    public boolean saveImage(String filePath, byte[] imageData) {
        Path path = new Path(filePath);

        try {
            // 디렉토리 존재 여부 확인 및 생성
            Path parentDir = path.getParent();
            if (!fileSystem.exists(parentDir)) {
                logger.info("HDFS 디렉토리가 존재하지 않아 생성합니다: {}", parentDir);
                fileSystem.mkdirs(parentDir);
            }

            // 파일 존재 시 삭제
            if (fileSystem.exists(path)) {
                fileSystem.delete(path, false);
            }

            // 이미지 저장
            try (FSDataOutputStream outputStream = fileSystem.create(path)) {
                outputStream.write(imageData);
                outputStream.flush();
            }

            logger.info("이미지 저장 완료: {}", filePath);
            return true;
        } catch (IOException e) {
            logger.error("HDFS 이미지 저장 에러: {}", e.getMessage(), e);
            return false;
        }
    }

    /**
     * MultipartFile 형태의 이미지를 HDFS에 저장합니다.
     * @param filePath 저장할 경로
     * @param file MultipartFile 이미지
     * @return 성공 여부
     */
    public boolean saveImageFile(String filePath, MultipartFile file) {
        try {
            return saveImage(filePath, file.getBytes());
        } catch (IOException e) {
            logger.error("MultipartFile 처리 중 오류 발생: {}", e.getMessage(), e);
            return false;
        }
    }

    /**
     * HDFS에서 이미지를 불러옵니다.
     * @param filePath 이미지 경로
     * @return 이미지 바이트 배열
     */
    public byte[] getImage(String filePath) throws IOException {
        Path path = new Path(filePath);

        if (!fileSystem.exists(path)) {
            logger.warn("파일이 존재하지 않습니다: {}", filePath);
            return null;
        }

        try (FSDataInputStream inputStream = fileSystem.open(path)) {
            FileStatus fileStatus = fileSystem.getFileStatus(path);
            byte[] buffer = new byte[(int) fileStatus.getLen()];
            inputStream.readFully(0, buffer);
            return buffer;
        }
    }

    /**
     * HDFS에서 파일을 삭제합니다.
     * @param filePath 삭제할 파일 경로
     * @return 성공 여부
     */
    public boolean deleteFile(String filePath) {
        try {
            Path path = new Path(filePath);
            if (fileSystem.exists(path)) {
                return fileSystem.delete(path, false);
            }
            logger.warn("삭제할 파일이 존재하지 않습니다: {}", filePath);
            return false;
        } catch (IOException e) {
            logger.error("HDFS 파일 삭제 에러: {}", e.getMessage(), e);
            return false;
        }
    }

    /**
     * 분실물 이미지 파일 경로 생성
     * @param id 분실물 ID
     * @return 전체 경로
     */
    public String getLostImagePath(String id) {
        return lostImgPrefix + id + ".jpg";
    }

    /**
     * 습득물 이미지 파일 경로 생성
     * @param id 습득물 ID
     * @return 전체 경로
     */
    public String getFoundImagePath(String id) {
        return foundImgPrefix + id + ".jpg";
    }
}