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

    @Value("${encryption.password}")
    private String password;

    @Value("${encryption.salt}")
    private String salt;

    public String encrypt(String plainText) {
        TextEncryptor textEncryptor = Encryptors.text(password, salt);
        return textEncryptor.encrypt(plainText);
    }

    public String decrypt(String encryptedText) {
        TextEncryptor textEncryptor = Encryptors.text(password, salt);
        return textEncryptor.decrypt(encryptedText);
    }
}
