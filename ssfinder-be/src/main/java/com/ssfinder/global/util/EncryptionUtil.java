package com.ssfinder.global.util;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.encrypt.Encryptors;
import org.springframework.security.crypto.encrypt.TextEncryptor;
import org.springframework.stereotype.Component;

/**
 * packageName    : com.ssfinder.global.util<br>
 * fileName       : EncryptionUtil.java<br>
 * author         : okeio<br>
 * date           : 2025-03-20<br>
 * description    : 문자열 암호화 및 복호화를 처리하는 유틸리티 클래스입니다.<br>
 *                  Spring Security의 {@link Encryptors#text(CharSequence, CharSequence)}를 사용하여 암호화를 수행합니다.<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-20        okeio              최초 생성<br>
 * <br>
 */
@Component
public class EncryptionUtil {

    private final TextEncryptor textEncryptor;

    public EncryptionUtil(
            @Value("${encryption.password}") String password,
            @Value("${encryption.salt}") String salt
    ) {
        this.textEncryptor = Encryptors.text(password, salt);
    }

    /**
     * 평문 문자열을 암호화합니다.
     *
     * <p>Spring Security의 {@code Encryptors.text()}를 통해 생성된 {@link TextEncryptor}를 사용하여
     * 전달된 문자열을 암호화합니다.</p>
     *
     * @param plainText 암호화할 평문 문자열
     * @return 암호화된 문자열
     */
    public String encrypt(String plainText) {
        return textEncryptor.encrypt(plainText);
    }

    /**
     * 암호화된 문자열을 복호화합니다.
     *
     * <p>{@link #encrypt(String)} 메서드로 암호화된 문자열을 다시 평문으로 복호화합니다.</p>
     *
     * @param encryptedText 복호화할 암호문 문자열
     * @return 복호화된 평문 문자열
     */
    public String decrypt(String encryptedText) {
        return textEncryptor.decrypt(encryptedText);
    }
}
