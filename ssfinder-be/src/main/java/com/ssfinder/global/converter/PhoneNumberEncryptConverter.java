package com.ssfinder.global.converter;

import com.ssfinder.global.util.EncryptionUtil;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Objects;

/**
 * packageName    : com.ssfinder.global.converter<br>
 * fileName       : PhoneNumberEncryptConverter.java<br>
 * author         : okeio<br>
 * date           : 2025-03-20<br>
 * description    : 전화번호 필드의 암호화 및 복호화를 처리하는 JPA AttributeConverter입니다.<br>
 *                  DB 저장 시 전화번호를 암호화하고, 조회 시 복호화하여 보안을 강화합니다.<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-20        okeio              최초 생성<br>
 * <br>
 */
@Converter
@Component
@RequiredArgsConstructor
public class PhoneNumberEncryptConverter implements AttributeConverter<String, String> {

    private final EncryptionUtil encryptionUtil;

    /**
     * 전화번호를 데이터베이스에 저장하기 위해 암호화합니다.
     *
     * <p>
     * 전화번호가 {@code null}일 경우에는 {@code null}을 반환하고,
     * 그렇지 않으면 {@link EncryptionUtil#encrypt(String)}을 호출하여 암호화된 값을 반환합니다.
     * </p>
     *
     * @param phoneNumber 암호화할 전화번호
     * @return 암호화된 전화번호
     */
    @Override
    public String convertToDatabaseColumn(String phoneNumber) {
        if (Objects.isNull(phoneNumber))
            return null;

        return encryptionUtil.encrypt(phoneNumber);
    }

    /**
     * 데이터베이스에서 조회한 암호화된 전화번호를 복호화하여 반환합니다.
     *
     * <p>
     * 암호화된 전화번호가 {@code null}일 경우에는 {@code null}을 반환하고,
     * 그렇지 않으면 {@link EncryptionUtil#decrypt(String)}을 호출하여 복호화된 값을 반환합니다.
     * </p>
     *
     * @param encryptedPhoneNumber 복호화할 암호화된 전화번호
     * @return 복호화된 전화번호
     */
    @Override
    public String convertToEntityAttribute(String encryptedPhoneNumber) {
        if (Objects.isNull(encryptedPhoneNumber))
            return null;

        return encryptionUtil.decrypt(encryptedPhoneNumber);
    }
}
