package com.ssfinder.domain.founditem.entity;

import lombok.*;
import org.springframework.data.annotation.Id;
import org.springframework.data.elasticsearch.annotations.*;
import org.springframework.data.elasticsearch.core.geo.GeoPoint;

@Document(indexName = "found-items")
@Getter
@Setter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
@ToString
public class FoundItemDocument {

    @Id
    private String id;

    @Field(name = "mysql_id", type = FieldType.Keyword)
    private String mysqlId;

    @Field(name = "user_id", type = FieldType.Keyword)
    private String userId;

    @Field(name = "management_id", type = FieldType.Keyword)
    private String managementId;

    @Field(name = "name", type = FieldType.Text, analyzer = "standard")
    private String name;

    @Field(name = "color", type = FieldType.Keyword)
    private String color;

    @Field(name = "found_at", type = FieldType.Date)
    private String foundAt;

    @Field(name = "status", type = FieldType.Keyword)
    private String status;

    @Field(name = "location", type = FieldType.Text)
    private String location;

    @Field(name = "phone", type = FieldType.Keyword)
    private String phone;

    @Field(name = "detail", type = FieldType.Text)
    private String detail;

    @Field(name = "image", type = FieldType.Keyword)
    private String image;

    @Field(name = "image_hdfs", type = FieldType.Keyword)
    private String imageHdfs;

    @Field(name = "stored_at", type = FieldType.Text)
    private String storedAt;

    @Field(name = "latitude", type = FieldType.Double)
    private Double latitude;

    @Field(name = "longitude", type = FieldType.Double)
    private Double longitude;

    @Field(name = "category_major", type = FieldType.Keyword)
    private String categoryMajor;

    @Field(name = "category_minor", type = FieldType.Keyword)
    private String categoryMinor;

    @GeoPointField
    @Field(name = "location_geo")
    private GeoPoint locationGeo;

    @Field(name = "created_at", type = FieldType.Date, format = DateFormat.date_optional_time)
    private String createdAt;

    @Field(name = "updated_at", type = FieldType.Date, format = DateFormat.date_optional_time)
    private String updatedAt;
}
