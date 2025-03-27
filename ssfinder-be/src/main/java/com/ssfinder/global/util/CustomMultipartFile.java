package com.ssfinder.global.util;

import org.springframework.core.io.buffer.DataBuffer;
import org.springframework.core.io.buffer.DefaultDataBufferFactory;
import org.springframework.web.multipart.MultipartFile;

import java.io.*;

public class CustomMultipartFile implements MultipartFile {
    private final byte[] fileContent;
    private final String fileName;
    private final String contentType;

    public CustomMultipartFile(byte[] fileContent, String fileName, String contentType) {
        this.fileContent = fileContent;
        this.fileName = fileName;
        this.contentType = contentType;
    }

    @Override
    public String getName() {
        return fileName;
    }

    @Override
    public String getOriginalFilename() {
        return fileName;
    }

    @Override
    public String getContentType() {
        return contentType;
    }

    @Override
    public boolean isEmpty() {
        return fileContent == null || fileContent.length == 0;
    }

    @Override
    public long getSize() {
        return fileContent.length;
    }

    @Override
    public byte[] getBytes() {
        try{
            return fileContent;
        } catch (Exception e) {
            e.printStackTrace();
            return new byte[0];
        }
    }

    @Override
    public InputStream getInputStream() throws IOException {
        return new ByteArrayInputStream(fileContent);
    }

    @Override
    public void transferTo(File dest) throws IOException {
        try (FileOutputStream fos = new FileOutputStream(dest)) {
            fos.write(fileContent);
        }
    }

    public static MultipartFile convertToMultipartFile(DataBuffer dataBuffer, String fileName, String contentType) {
        byte[] bytes = new byte[dataBuffer.readableByteCount()];
        dataBuffer.read(bytes);
        MultipartFile multipartFile = new CustomMultipartFile(bytes, fileName, contentType);
        return multipartFile;
    }
    public static MultipartFile convertToMultipartFile(byte[] data, String fileName, String contentType) {
        DataBuffer dataBuffer = convertByteArrayToDataBuffer(data);
        return convertToMultipartFile(dataBuffer, fileName, contentType);
    }

    public static DataBuffer convertByteArrayToDataBuffer(byte[] bytes) {
        DefaultDataBufferFactory factory = new DefaultDataBufferFactory();
        return factory.wrap(bytes);
    }

}
