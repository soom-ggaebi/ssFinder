package com.ssfinder.domain.founditem.entity;

import lombok.*;
import org.springframework.data.annotation.Id;
import org.springframework.data.elasticsearch.annotations.Document;
import org.springframework.data.elasticsearch.annotations.Field;
import org.springframework.data.elasticsearch.annotations.FieldType;
import org.springframework.data.elasticsearch.annotations.GeoPointField;
import org.springframework.data.elasticsearch.core.geo.GeoPoint;

@Document(indexName = "find-items")
@Getter
@Setter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
@ToString
public class FoundItemDocument {

    @Id
    private String id;

    @Field(type = FieldType.Keyword)
    private String managementId;

    @Field(type = FieldType.Keyword)
    private String color;

    @Field(type = FieldType.Text)
    private String storedAt;

    @Field(type = FieldType.Keyword)
    private String image;

    @Field(type = FieldType.Keyword)
    private String imageHdfs;

    @Field(type = FieldType.Text, analyzer = "standard")
    private String name;

    @Field(type = FieldType.Date)
    private String foundAt;

    @Field(type = FieldType.Keyword)
    private String status;

    @Field(type = FieldType.Text)
    private String location;

    @Field(type = FieldType.Keyword)
    private String phone;

    @Field(type = FieldType.Text)
    private String detail;

    @Field(type = FieldType.Double)
    private Double latitude;

    @Field(type = FieldType.Double)
    private Double longitude;

    @Field(type = FieldType.Keyword)
    private String categoryMajor;

    @Field(type = FieldType.Keyword)
    private String categoryMinor;

    @Field(type = FieldType.Keyword)
    private String mysqlId;

    @GeoPointField
    private GeoPoint locationGeo;

}
