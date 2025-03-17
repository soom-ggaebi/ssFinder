"""
유틸리티 함수들을 모아놓은 파일
"""

import os
import sys
import time
import functools
import inspect
import json
import re
import datetime
from fastapi import Request
from pydantic import BaseModel


def save_file(file, save_mode: str, file_name: str):
    """
    파일을 저장한 후 저장된 파일의 경로를 반환하는 함수
    """
    file_path = f"./app/files/{time.time_ns()}_{file_name}"
    with open(file_path, save_mode) as f:
        f.write(file)

    return file_path


def delete_file(file_path: str):
    """
    파일을 삭제하는 함수
    """
    os.remove(file_path)


def parse_request(request):
    """
    Request를 파싱하는 함수
    """
    body_str = request.decode("utf-8")  # 문자열 변환
    try:
        parsed_json = json.loads(body_str)  # JSON 변환
        return parsed_json
    except json.JSONDecodeError:
        print("Received Non-JSON Body:", body_str)  # JSON이 아니면 그냥 출력
        return body_str


CUT_MODE = True


def cut_string(string: str, length: int = 20):
    """
    문자열을 자르는 함수
    """

    if len(string) > length and CUT_MODE:
        string = string[:length] + "..."

    return string


PRETTY_PRINT_DICT = True


def pretty_print_dict(d, indent=0, base_space_cnt=2):
    """
    딕셔너리를 보기 좋게 출력하는 헬퍼 함수.
    예)
    {
        a: 4,
        b:
        {
            c: 1,
            d: 2,
        }
    }
    """
    if not PRETTY_PRINT_DICT:
        return str(d)

    base_space = " " * base_space_cnt
    spaces = base_space * indent
    lines = []
    lines.append(spaces + "{")
    for key, value in d.items():
        if isinstance(value, dict):
            lines.append(spaces + f"{base_space}{key}:")
            lines.append(pretty_print_dict(value, indent + 1))
        elif isinstance(value, list):
            lines.append(spaces + f"{base_space}{key}: [")
            for item in value:
                if isinstance(item, dict):
                    lines.append(pretty_print_dict(item, indent + 2))
                else:
                    lines.append(spaces + f"{base_space}{item},")
            lines.append(spaces + f"{base_space}],")
        else:
            print_value = cut_string(str(value))
            lines.append(spaces + f"{base_space}{key}: {print_value},")
    lines.append(spaces + "}")
    return "\n".join(lines)


def print_value(value):
    """
    함수의 파라미터 이름과 인자값을 출력하는 함수
    """
    # 매핑된 인자들을 함수의 파라미터 이름에 맞춰 출력
    if value is None:
        print("None")
        return

    if isinstance(value, BaseModel):
        print(pretty_print_dict(value.model_dump()))
    elif isinstance(value, dict):
        print(pretty_print_dict(value))
    elif hasattr(value, "filename") and hasattr(value, "content_type"):
        # UploadFile 또는 이와 유사한 객체로 간주
        file_info = {
            "filename": getattr(value, "filename", None),
            "content_type": getattr(value, "content_type", None)
        }
        print(pretty_print_dict(file_info))
    else:
        print(cut_string(str(value)))


def logger(func):
    # 함수가 코루틴(비동기 함수)인지 확인
    if inspect.iscoroutinefunction(func):
        @functools.wraps(func)
        async def async_wrapper(*args, **kwargs):
            sig = inspect.signature(func)
            bound = sig.bind(*args, **kwargs)
            bound.apply_defaults()

            print_currunt_time(append_message=f"{func.__name__}() is called.")
            print("input")
            if not bound.arguments:
                print("No input")
            for param_name, value in bound.arguments.items():
                print(f"{param_name}:")
                if isinstance(value, Request):
                    body_byte = await value.body()
                    body = json.loads(body_byte.decode("utf-8"))

                    print(pretty_print_dict(body))
                else:
                    print_value(value)

            print(f"{func.__name__} start ****************************************")
            start_time = time.time_ns()
            # 비동기 함수 호출
            result = await func(*args, **kwargs)
            end_time = time.time_ns()
            elapsed_time_seconds = (end_time - start_time) / 1_000_000_000
            print(f"Time: {elapsed_time_seconds:.2f} seconds")
            print(f"{func.__name__} end ******************************************")

            print("output")
            print_value(result)
            return result
        return async_wrapper
    else:
        @functools.wraps(func)
        def sync_wrapper(*args, **kwargs):
            sig = inspect.signature(func)
            bound = sig.bind(*args, **kwargs)
            bound.apply_defaults()

            print_currunt_time(append_message=f"{func.__name__}() is called.")
            print("input")
            if not bound.arguments:
                print("No input")
            for param_name, value in bound.arguments.items():
                print(f"{param_name}:")
                # 동기 컨텍스트에서 비동기 함수 호출
                print_value(value)

            print(f"{func.__name__} start ****************************************")
            start_time = time.time_ns()
            result = func(*args, **kwargs)
            end_time = time.time_ns()
            elapsed_time_seconds = (end_time - start_time) / 1_000_000_000
            print(f"Time: {elapsed_time_seconds:.2f} seconds")
            print(f"{func.__name__} end ******************************************")

            print("output")
            print_value(result)
            return result
        return sync_wrapper


# ANSI 이스케이프 시퀀스를 제거하기 위한 정규식 패턴
ANSI_ESCAPE = re.compile(r'\x1b\[[0-9;]*m')


class TeeLogger:
    def __init__(self, filename, mode):
        self.terminal = sys.stdout  # 기존 stdout 저장
        self.log_file = open(filename, mode, encoding="utf-8")  # 로그 파일 열기

    def write(self, message):
        # 터미널에는 원래 메시지 출력 (색상 유지)
        self.terminal.write(message)
        # 로그 파일에는 ANSI 색상 코드를 제거한 메시지 출력
        clean_message = ANSI_ESCAPE.sub('', message)
        self.log_file.write(clean_message)

    def flush(self):
        self.terminal.flush()
        self.log_file.flush()

    def isatty(self):
        return self.terminal.isatty()

    def __getattr__(self, attr):
        return getattr(self.terminal, attr)


def log_to_file(file_name: str = f"{time.time_ns()}.log", mode: str = "w"):
    """
    파일에 로그를 출력하는 함수
    """
    sys.stdout = TeeLogger(file_name, mode)


def print_currunt_time(before_message: str = "INFO:\t", format="%Y.%m.%d %p %I:%M:%S", append_message: str = ""):
    """
    현재 시간을 출력하는 함수
    """
    current_time = datetime.datetime.now().strftime(format)
    print(f"{before_message} {current_time} {append_message}")


class LogConfig:
    def __init__(self, active_log_file: bool = False, file_name: str = f"{time.time_ns()}.log", mode: str = "w", string_cut_mode: bool = True, pretty_print_dict_mode: bool = True):
        if active_log_file:
            log_to_file(file_name, mode)
        global CUT_MODE, PRETTY_PRINT_DICT
        CUT_MODE = string_cut_mode
        PRETTY_PRINT_DICT = pretty_print_dict_mode
        print_currunt_time(append_message="Log Start")
