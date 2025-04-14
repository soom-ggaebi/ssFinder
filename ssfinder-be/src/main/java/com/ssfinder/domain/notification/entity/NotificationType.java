package com.ssfinder.domain.notification.entity;

/**
 * packageName    : com.ssfinder.domain.notification.entity<br>
 * fileName       : NotificationType.java<br>
 * author         : okeio<br>
 * date           : 2025-03-25<br>
 * description    : 알림의 종류를 정의하는 열거형입니다.<br>
 *                  소지품 전달, 채팅, AI 매칭, 리마인더, 전체 알림 유형 등을 포함합니다.<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-25          okeio           최초생성<br>
 * <br>
 */
public enum NotificationType {
    TRANSFER, CHAT, AI_MATCH, ITEM_REMINDER, ALL
}