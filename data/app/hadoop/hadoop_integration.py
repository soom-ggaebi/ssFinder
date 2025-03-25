import os
import csv

def write_to_hadoop(data, batch_id):
    """
    data: 리스트 형태의 dict (여러 메시지)
    batch_id: 배치 식별자
    """
    os.makedirs("./hadoop_output", exist_ok=True)
    file_path = f"./hadoop_output/batch_{batch_id}.csv"
    file_exists = os.path.isfile(file_path)
    with open(file_path, "a", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=data[0].keys())
        if not file_exists:
            writer.writeheader()
        writer.writerows(data)
    print(f"Batch {batch_id} written to simulated Hadoop at {file_path}.")
