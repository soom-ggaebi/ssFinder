package com.ssfinder.global.converter;

import com.ssfinder.global.util.EncryptionUtil;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

/**
 * packageName    : com.ssfinder.global.converter<br>
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
@Converter
@Component
@RequiredArgsConstructor
public class PhoneNumberEncryptConverter implements AttributeConverter<String, String> {

    private final EncryptionUtil encryptionUtil;

    @Override
    public String convertToDatabaseColumn(String phoneNumber) {
        return encryptionUtil.encrypt(phoneNumber);
    }

    @Override
    public String convertToEntityAttribute(String encryptedPhoneNumber) {
        return encryptionUtil.decrypt(encryptedPhoneNumber);
    }
}
