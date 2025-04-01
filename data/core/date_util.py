from datetime import datetime, timedelta

def get_date_range_for_api():
    today = datetime.today()
    end_date = today
    start_date = end_date 
    return start_date.strftime("%Y%m%d"), end_date.strftime("%Y%m%d")
