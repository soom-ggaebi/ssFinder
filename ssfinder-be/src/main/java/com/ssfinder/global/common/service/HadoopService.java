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

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Service
public class HadoopService {
    private static final Logger logger = LoggerFactory.getLogger(HadoopService.class);

    private final FileSystem fileSystem;
    private final Configuration configuration;

    @Value("${hdfs.prefix.found.img}")
    private String foundImgPrefix;

    @Value("${hdfs.prefix.found.csv}")
    private String foundCsvPrefix;

    @Value("${hdfs.prefix.lost.img}")
    private String lostImgPrefix;

    @Value("${hdfs.prefix.lost.csv}")
    private String lostCsvPrefix;

    @Autowired
    public HadoopService(FileSystem fileSystem, Configuration configuration) {
        this.fileSystem = fileSystem;
        this.configuration = configuration;
    }

    /**
     * CSV 파일에 데이터를 추가합니다. 파일이 없으면 새로 생성합니다.
     * @param filePath CSV 파일 경로
     * @param records 추가할 레코드 맵 리스트
     * @param headers CSV 헤더 (파일이 없을 경우 사용)
     * @return 성공 여부
     */
    public boolean appendToCsv(String filePath, List<Map<String, Object>> records, List<String> headers) {
        Path path = new Path(filePath);
        boolean fileExists = false;

        try {
            // 디렉토리 존재 여부 확인 및 생성
            Path parentDir = path.getParent();
            if (!fileSystem.exists(parentDir)) {
                logger.info("HDFS 디렉토리가 존재하지 않아 생성합니다: {}", parentDir);
                fileSystem.mkdirs(parentDir);
            }

            // 파일 존재 여부 확인
            fileExists = fileSystem.exists(path);

            try (FSDataOutputStream outputStream = fileExists ?
                    fileSystem.append(path) : fileSystem.create(path);
                 BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(outputStream, StandardCharsets.UTF_8))) {

                // 헤더 작성 (파일이 존재하지 않는 경우)
                if (!fileExists && headers != null && !headers.isEmpty()) {
                    String headerLine = String.join(",", headers.stream()
                            .map(this::escapeCsvField)
                            .toArray(String[]::new));
                    writer.write(headerLine);
                    writer.newLine();
                }

                // 데이터 행 작성
                for (Map<String, Object> record : records) {
                    List<String> values = new ArrayList<>();
                    for (String header : headers) {
                        Object value = record.getOrDefault(header, "");
                        values.add(escapeCsvField(value));
                    }
                    String line = String.join(",", values);
                    writer.write(line);
                    writer.newLine();
                }

                writer.flush();
                logger.info("HDFS에 {}개 레코드 저장 완료: {}", records.size(), filePath);
                return true;
            }
        } catch (IOException e) {
            logger.error("HDFS CSV 저장 에러: {}", e.getMessage(), e);
            return false;
        }
    }

    /**
     * CSV 파일의 내용을 읽어옵니다.
     * @param filePath CSV 파일 경로
     * @return 레코드 맵 리스트
     */
    public List<Map<String, String>> readCsv(String filePath) throws IOException {
        Path path = new Path(filePath);
        List<Map<String, String>> records = new ArrayList<>();

        if (!fileSystem.exists(path)) {
            logger.warn("파일이 존재하지 않습니다: {}", filePath);
            return records;
        }

        try (FSDataInputStream inputStream = fileSystem.open(path);
             BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream, StandardCharsets.UTF_8))) {

            // 헤더 읽기
            String headerLine = reader.readLine();
            if (headerLine == null) {
                return records;
            }

            // 헤더 분석
            String[] headers = parseCsvLine(headerLine);

            // 데이터 행 읽기
            String line;
            while ((line = reader.readLine()) != null) {
                String[] values = parseCsvLine(line);
                Map<String, String> record = new java.util.HashMap<>();

                for (int i = 0; i < headers.length && i < values.length; i++) {
                    record.put(headers[i], values[i]);
                }

                records.add(record);
            }
        }

        return records;
    }

    /**
     * CSV 파일의 특정 레코드를 삭제합니다.
     * @param filePath CSV 파일 경로
     * @param keyField 삭제할 레코드의 식별 필드 이름
     * @param keyValue 삭제할 레코드의 식별 값
     * @return 성공 여부
     */
    public boolean deleteFromCsv(String filePath, String keyField, String keyValue) throws IOException {
        Path path = new Path(filePath);

        if (!fileSystem.exists(path)) {
            logger.warn("파일이 존재하지 않습니다: {}", filePath);
            return false;
        }

        // 현재 CSV 파일 읽기
        List<Map<String, String>> records = readCsv(filePath);
        if (records.isEmpty()) {
            return false;
        }

        // 헤더 가져오기 (첫 번째 레코드의 키셋 사용)
        List<String> headers = new ArrayList<>(records.get(0).keySet());

        // 레코드 필터링 (삭제할 항목 제외)
        List<Map<String, Object>> filteredRecords = records.stream()
                .filter(record -> !keyValue.equals(record.get(keyField)))
                .map(record -> new java.util.HashMap<String, Object>(record))
                .collect(java.util.stream.Collectors.toList());

        // 기존 파일 삭제
        fileSystem.delete(path, false);

        // 필터링된 레코드로 새 파일 작성
        return appendToCsv(filePath, filteredRecords, headers);
    }

    /**
     * CSV 파일의 특정 레코드를 업데이트합니다.
     * @param filePath CSV 파일 경로
     * @param keyField 업데이트할 레코드의 식별 필드 이름
     * @param keyValue 업데이트할 레코드의 식별 값
     * @param newData 새로운 데이터
     * @return 성공 여부
     */
    public boolean updateCsv(String filePath, String keyField, String keyValue, Map<String, Object> newData) throws IOException {
        Path path = new Path(filePath);

        if (!fileSystem.exists(path)) {
            logger.warn("파일이 존재하지 않습니다: {}", filePath);
            return false;
        }

        // 현재 CSV 파일 읽기
        List<Map<String, String>> records = readCsv(filePath);
        if (records.isEmpty()) {
            return false;
        }

        // 헤더 가져오기
        List<String> headers = new ArrayList<>(records.get(0).keySet());

        // 레코드 업데이트
        List<Map<String, Object>> updatedRecords = new ArrayList<>();
        boolean found = false;

        for (Map<String, String> record : records) {
            if (keyValue.equals(record.get(keyField))) {
                // 레코드 찾음 - 업데이트
                Map<String, Object> updatedRecord = new java.util.HashMap<>(record);
                updatedRecord.putAll(newData);
                updatedRecords.add(updatedRecord);
                found = true;
            } else {
                // 다른 레코드는 그대로 유지
                updatedRecords.add(new java.util.HashMap<>(record));
            }
        }

        if (!found) {
            logger.warn("업데이트할 레코드를 찾을 수 없습니다: {} = {}", keyField, keyValue);
            return false;
        }

        // 기존 파일 삭제
        fileSystem.delete(path, false);

        // 업데이트된 레코드로 새 파일 작성
        return appendToCsv(filePath, updatedRecords, headers);
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

    /**
     * 분실물 CSV 파일 경로 반환
     * @return 분실물 CSV 파일 경로
     */
    public String getLostCsvPath() {
        return lostCsvPrefix + "lost_item.csv";
    }

    /**
     * 습득물 CSV 파일 경로 반환
     * @return 습득물 CSV 파일 경로
     */
    public String getFoundCsvPath() {
        return foundCsvPrefix + "found_item.csv";
    }

    // CSV 유틸리티 메서드
    private String escapeCsvField(Object field) {
        if (field == null) {
            return "";
        }

        String value = field.toString();

        // 줄바꿈 문자 제거
        value = value.replace("\n", " ").replace("\r", " ");

        // 쌍따옴표 처리
        if (value.contains("\"") || value.contains(",") || value.contains("\n")) {
            value = value.replace("\"", "\"\"");
            value = "\"" + value + "\"";
        }

        return value;
    }

    // CSV 라인 파싱 (쌍따옴표 처리)
    private String[] parseCsvLine(String line) {
        List<String> result = new ArrayList<>();
        StringBuilder current = new StringBuilder();
        boolean inQuotes = false;

        for (int i = 0; i < line.length(); i++) {
            char c = line.charAt(i);

            if (c == '\"') {
                // 쌍따옴표 처리
                if (inQuotes && i + 1 < line.length() && line.charAt(i + 1) == '\"') {
                    // 쌍따옴표가 이스케이프된 경우
                    current.append('\"');
                    i++; // 다음 쌍따옴표 건너뛰기
                } else {
                    // 따옴표 토글
                    inQuotes = !inQuotes;
                }
            } else if (c == ',' && !inQuotes) {
                // 필드 구분자(쌍따옴표 밖에 있는 경우)
                result.add(current.toString());
                current = new StringBuilder();
            } else {
                // 일반 문자
                current.append(c);
            }
        }

        // 마지막 필드 추가
        result.add(current.toString());

        return result.toArray(new String[0]);
    }
}