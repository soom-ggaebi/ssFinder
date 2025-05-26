"""
동시성 및 비동기 처리를 위한 유틸리티 모듈
스레드 풀, 작업 큐, 비동기 처리 기능을 제공합니다.
"""
import os
import queue
import concurrent.futures
import threading
import asyncio
from functools import wraps
from typing import Callable, Any
import logging


logger = logging.getLogger(__name__)

class ThreadPoolManager:
    """
    스레드 풀 관리자: 애플리케이션 전체에서 공유할 수 있는 스레드 풀 관리
    """
    _instance = None
    _lock = threading.Lock()
    
    def __new__(cls):
        with cls._lock:
            if cls._instance is None:
                cls._instance = super(ThreadPoolManager, cls).__new__(cls)
                # CPU 코어 수 기반 스레드 풀 생성
                cpu_count = os.cpu_count() or 4
                cls._instance.api_pool = concurrent.futures.ThreadPoolExecutor(
                    max_workers=cpu_count * 2,
                    thread_name_prefix="api_pool"
                )
                cls._instance.processing_pool = concurrent.futures.ThreadPoolExecutor(
                    max_workers=cpu_count * 4,
                    thread_name_prefix="processing_pool"
                )
                cls._instance.io_pool = concurrent.futures.ThreadPoolExecutor(
                    max_workers=cpu_count * 8,
                    thread_name_prefix="io_pool"
                )
                cls._instance.download_pool = concurrent.futures.ThreadPoolExecutor(
                    max_workers=cpu_count * 8,
                    thread_name_prefix="download_pool"
                )
                cls._instance.upload_pool = concurrent.futures.ThreadPoolExecutor(
                    max_workers=cpu_count * 8,
                    thread_name_prefix="upload_pool"
                )
        return cls._instance
    
    def get_api_pool(self):
        """API 호출용 스레드 풀 반환"""
        return self.api_pool
    
    def get_processing_pool(self):
        """데이터 처리용 스레드 풀 반환"""
        return self.processing_pool
    
    def get_io_pool(self):
        """일반 I/O 작업용 스레드 풀 반환"""
        return self.io_pool
    
    def get_download_pool(self):
        """다운로드 작업용 스레드 풀 반환"""
        return self.download_pool
    
    def get_upload_pool(self):
        """업로드 작업용 스레드 풀 반환"""
        return self.upload_pool
    
    def submit_to_api_pool(self, fn, *args, **kwargs):
        """API 호출 작업을 API 스레드 풀에 제출"""
        return self.api_pool.submit(fn, *args, **kwargs)
    
    def submit_to_processing_pool(self, fn, *args, **kwargs):
        """데이터 처리 작업을 처리 스레드 풀에 제출"""
        return self.processing_pool.submit(fn, *args, **kwargs)
    
    def submit_to_io_pool(self, fn, *args, **kwargs):
        """I/O 작업을 I/O 스레드 풀에 제출"""
        return self.io_pool.submit(fn, *args, **kwargs)
    
    def shutdown(self):
        """모든 스레드 풀 종료"""
        self.api_pool.shutdown(wait=True)
        self.processing_pool.shutdown(wait=True)
        self.io_pool.shutdown(wait=True)
        self.download_pool.shutdown(wait=True)
        self.upload_pool.shutdown(wait=True)


class BackpressureQueue:
    """
    백프레셔를 지원하는 작업 큐
    - max_size: 큐의 최대 크기
    - blocking: 큐가 가득 찼을 때 블로킹 여부
    """
    def __init__(self, max_size: int = 1000, blocking: bool = True):
        self.queue = queue.Queue(maxsize=max_size)
        self.blocking = blocking
        
    def put(self, item: Any) -> bool:
        """
        큐에 항목 추가. 가득 찼을 때 blocking=True면 블록, 아니면 False 반환
        """
        try:
            if self.blocking:
                self.queue.put(item, block=True)
                return True
            else:
                return self.queue.put(item, block=False)
        except queue.Full:
            return False
            
    def get(self) -> Any:
        """큐에서 항목 가져오기 (블로킹)"""
        return self.queue.get(block=True)
    
    def task_done(self):
        """작업 완료 표시"""
        self.queue.task_done()
        
    def size(self) -> int:
        """현재 큐 크기 반환"""
        return self.queue.qsize()
    
    def is_empty(self) -> bool:
        """큐가 비어있는지 확인"""
        return self.queue.empty()


def batch_process(batch_size: int = 100):
    """
    요청을 배치로 처리하는 데코레이터
    단일 항목 처리 함수를 받아서 배치 처리 함수로 변환
    
    @batch_process(batch_size=100)
    def process_item(item):
        # 단일 항목 처리 로직
        return result
    """
    def decorator(func: Callable[[Any], Any]):
        batch_queue = []
        lock = threading.Lock()
        
        @wraps(func)
        def wrapper(item):
            nonlocal batch_queue
            
            with lock:
                batch_queue.append(item)
                
                if len(batch_queue) >= batch_size:
                    # 배치 크기에 도달하면 처리
                    items_to_process = batch_queue.copy()
                    batch_queue = []
            
                    # 배치 처리를 ThreadPoolManager의 처리 풀에 제출
                    pool_manager = ThreadPoolManager()
                    futures = [
                        pool_manager.submit_to_processing_pool(func, item) 
                        for item in items_to_process
                    ]
                    return concurrent.futures.wait(futures)
                return None
        
        # 배치 큐에 남은 항목들을 처리하는 함수 추가
        def flush():
            nonlocal batch_queue
            with lock:
                if batch_queue:
                    items_to_process = batch_queue.copy()
                    batch_queue = []
                    
                    pool_manager = ThreadPoolManager()
                    futures = [
                        pool_manager.submit_to_processing_pool(func, item) 
                        for item in items_to_process
                    ]
                    return concurrent.futures.wait(futures)
                return None
                
        wrapper.flush = flush
        return wrapper
    
    return decorator


def run_in_thread_pool(pool_type: str = 'processing'):
    """
    함수를 지정된 스레드 풀에서 실행하는 데코레이터

    @run_in_thread_pool(pool_type='api')
    def fetch_data(url):
        # API 호출 로직
        return data
    """
    def decorator(func: Callable):
        @wraps(func)
        def wrapper(*args, **kwargs):
            logger.info(f"함수 '{func.__name__}' 호출됨")
            pool_manager = ThreadPoolManager()
            
            if pool_type == 'api':
                pool = pool_manager.get_api_pool()
            elif pool_type == 'io':
                pool = pool_manager.get_io_pool()
            elif pool_type == 'download':
                pool = pool_manager.get_download_pool()
            elif pool_type == 'upload':
                pool = pool_manager.get_upload_pool()
            else:  # default to processing
                pool = pool_manager.get_processing_pool()
            
            logger.info(f"선택된 스레드 풀: {pool} (pool_type={pool_type})")
            future = pool.submit(func, *args, **kwargs)
            logger.info(f"'{func.__name__}' 함수가 스레드 풀에 제출되었습니다. 결과를 기다립니다...")
            try:
                result = future.result()
                logger.info(f"'{func.__name__}' 함수 실행 완료. 결과: ")
            except Exception as e:
                logger.error(f"'{func.__name__}' 함수 실행 중 오류 발생: {e}")
                raise
            return result
        return wrapper
    return decorator


# 비동기 처리를 위한 asyncio 이벤트 루프 관리
def get_event_loop():
    """현재 스레드의 이벤트 루프 반환, 없으면 새로 생성"""
    try:
        return asyncio.get_event_loop()
    except RuntimeError:
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        return loop


def run_async(coroutine):
    """동기 코드에서 비동기 코루틴 실행"""
    loop = get_event_loop()
    return loop.run_until_complete(coroutine)