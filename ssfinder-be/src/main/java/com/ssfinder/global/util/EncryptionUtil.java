package com.ssfinder.global.util;

import com.ssfinder.global.common.exception.CustomException;
import com.ssfinder.global.common.exception.ErrorCode;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.Cipher;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.Objects;

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

    @Value("${encryption.secret-key}")
    private String secretKey;

    @Value("${encryption.iv}")
    private String iv;

    private static final String ALGORITHM = "AES";

    public String encrypt(String plainText) {
        try {
            if (Objects.isNull(plainText) || plainText.isEmpty()) {
                return plainText;
            }

            Cipher cipher = Cipher.getInstance(ALGORITHM);
            SecretKeySpec keySpec = new SecretKeySpec(secretKey.getBytes(), ALGORITHM);
            IvParameterSpec ivSpec = new IvParameterSpec(iv.getBytes());

            cipher.init(Cipher.ENCRYPT_MODE, keySpec, ivSpec);
            byte[] encrypted = cipher.doFinal(plainText.getBytes(StandardCharsets.UTF_8));

            return Base64.getEncoder().encodeToString(encrypted);
        } catch (Exception e) {
            throw new CustomException(ErrorCode.ENCRYPT_FAILED);
        }
    }

    public String decrypt(String encryptedText) {
        try {
            if (Objects.isNull(encryptedText) || encryptedText.isEmpty()) {
                return encryptedText;
            }

            Cipher cipher = Cipher.getInstance(ALGORITHM);
            SecretKeySpec keySpec = new SecretKeySpec(secretKey.getBytes(StandardCharsets.UTF_8), ALGORITHM);
            IvParameterSpec ivSpec = new IvParameterSpec(iv.getBytes(StandardCharsets.UTF_8));

            cipher.init(Cipher.DECRYPT_MODE, keySpec, ivSpec);
            byte[] decodedBytes = Base64.getDecoder().decode(encryptedText);
            byte[] decrypted = cipher.doFinal(decodedBytes);
            return new String(decrypted, StandardCharsets.UTF_8);
        } catch (Exception e) {
            throw new CustomException(ErrorCode.ENCRYPT_FAILED);
        }
    }
}
