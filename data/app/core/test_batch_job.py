from pyspark.sql import SparkSession
from config.config import SPARK_MASTER

def test_batch_job():
    spark = None
    try:
        print("✅ SparkSession 생성 시작...")
        spark = SparkSession.builder \
            .appName("TestBatchJob") \
            .master(SPARK_MASTER) \
            .config("spark.executor.memory", "512m") \
            .config("spark.executor.cores", "1") \
            .config("spark.default.parallelism", "2") \
            .config("spark.driver.host", "172.23.0.2") \
            .config("spark.driver.port", "4041") \
            .config("spark.blockManager.port", "4042") \
            .config("spark.driver.bindAddress", "0.0.0.0") \
            .getOrCreate()

        print("✅ SparkSession 생성 완료!")
        print("👉 마스터 주소:", spark.sparkContext.master)
        print("👉 실행중인 앱 이름:", spark.sparkContext.appName)

        print("👉 연결된 Executors:")
        executors = spark.sparkContext._jsc.sc().getExecutorMemoryStatus().keySet()
        executor_iter = executors.iterator()

        while executor_iter.hasNext():
            executor = executor_iter.next()
            print("  🔹", str(executor))


        # 예제 데이터
        summary_data = [("FTEST001", "테스트 물품", "블랙", "테스트경찰서", 
                         "https://s3.amazonaws.com/bucket/sample_processed.jpg", 
                         "2025-03-15 00:00:00", "테스트 > 샘플")]

        detail_data = [("FTEST001", "STORED", "상세 테스트 장소", 
                        "010-1234-5678", "테스트 상세정보 보충")]

        summary_schema = "management_id string, name string, color string, stored_at string, s3_image string, found_at string, prdtClNm string"
        detail_schema = "management_id string, status string, location string, phone string, detail string"

        print("📦 데이터프레임 생성 중...")
        summary_df = spark.createDataFrame(summary_data, schema=summary_schema)
        detail_df = spark.createDataFrame(detail_data, schema=detail_schema)

        print("🔗 데이터프레임 조인 중...")
        final_df = summary_df.join(detail_df, on="management_id", how="left")

        print("📊 데이터 미리보기:")

        print("📈 Row count 실행:")
        print("Row count: ", final_df.count())

        spark.stop()

    except Exception as e:
        print("❌ Spark 작업 중 오류 발생:", str(e))

    finally:
        if spark:
            try:
                spark.stop()
                print("🧹 Spark 세션 정상 종료")
            except Exception as e:
                print("⚠️ Spark 세션 종료 실패:", str(e))

if __name__ == "__main__":
    test_batch_job()
