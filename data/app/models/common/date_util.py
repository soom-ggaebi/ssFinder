from datetime import datetime, timedelta

def get_date_range_for_api():
    """
    어제부터 6개월 전까지 날짜를 YYYYMMDD 형식으로 반환
    """
    today = datetime.today()
    end_date = today - timedelta(days=0)
    start_date = end_date - timedelta(days=0)
    return start_date.strftime('%Y%m%d'), end_date.strftime('%Y%m%d')
