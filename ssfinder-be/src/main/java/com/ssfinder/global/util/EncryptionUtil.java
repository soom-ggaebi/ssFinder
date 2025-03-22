package com.ssfinder.global.util;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.encrypt.Encryptors;
import org.springframework.security.crypto.encrypt.TextEncryptor;
import org.springframework.stereotype.Component;

/**
 * packageName    : com.ssfinder.global.util<br>
 * fileName       : *.java<br>
 * author         : okeio<br>
 * date           : 2025-03-20<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-20          okeio           최초생성<br>
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

    public String encrypt(String plainText) {
        return textEncryptor.encrypt(plainText);
    }

    public String decrypt(String encryptedText) {
        return textEncryptor.decrypt(encryptedText);
    }
}
