from datetime import datetime, timedelta
from dateutil.relativedelta import relativedelta

def get_date_range(initial: bool):
    """
    초기 로드(initial=True)일 경우: 오늘 기준 6개월 전부터 전날까지
    그렇지 않으면: 오늘 날짜만 반환합니다.
    반환 형식은 'YYYYMMDD'
    """
    today = datetime.today()
    if initial:
        start_date = today - relativedelta(months=6)
        end_date = today - timedelta(days=1)
    else:
        start_date = today
        end_date = today
    return start_date.strftime("%Y%m%d"), end_date.strftime("%Y%m%d")