from pyspark.sql import SparkSession
from config.config import SPARK_MASTER

def test_batch_job():
    spark = SparkSession.builder \
        .appName("TestBatchJob") \
        .master(SPARK_MASTER) \
        .config("spark.executor.memory", "512m") \
        .config("spark.executor.cores", "1") \
        .config("spark.default.parallelism", "2") \
        .config("spark.driver.host", "43.201.252.40") \
        .config("spark.driver.bindAddress", "0.0.0.0") \
        .getOrCreate()

    summary_data = [("FTEST001", "테스트 물품", "블랙", "테스트경찰서", 
                     "https://s3.amazonaws.com/bucket/sample_processed.jpg", 
                     "2025-03-15 00:00:00", "테스트 > 샘플")]

    detail_data = [("FTEST001", "STORED", "상세 테스트 장소", 
                    "010-1234-5678", "테스트 상세정보 보충")]

    summary_schema = "management_id string, name string, color string, stored_at string, s3_image string, found_at string, prdtClNm string"
    detail_schema = "management_id string, status string, location string, phone string, detail string"

    summary_df = spark.createDataFrame(summary_data, schema=summary_schema)
    detail_df = spark.createDataFrame(detail_data, schema=detail_schema)

    final_df = summary_df.join(detail_df, on="management_id", how="left")
    final_df.show(truncate=False)
    
    print("Row count: ", final_df.count())  # 강제 액션
    spark.stop()

if __name__ == "__main__":
    test_batch_job()
