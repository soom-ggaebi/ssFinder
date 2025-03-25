import xml.etree.ElementTree as ET
from datetime import datetime

def parse_total_count(xml_content: str) -> int:
    root = ET.fromstring(xml_content)
    body = root.find('body')
    if body is None:
        return 0
    tc = body.findtext('totalCount')
    return int(tc) if tc else 0

def parse_items(xml_content: str):
    root = ET.fromstring(xml_content)
    body = root.find('body')
    if body is None:
        return []
    items_tag = body.find('items')
    if items_tag is None:
        return []
    results = []
    for item in items_tag.findall('item'):
        atcId = item.findtext('atcId', '').strip()
        clrNm = item.findtext('clrNm', '').strip()
        depPlace = item.findtext('depPlace', '').strip()
        fdFilePathImg = item.findtext('fdFilePathImg', '').strip()
        fdPrdtNm = item.findtext('fdPrdtNm', '').strip()
        fdYmd = item.findtext('fdYmd', '').strip()
        prdtClNm = item.findtext('prdtClNm', '').strip()
        found_at = None
        if fdYmd:
            try:
                found_at = datetime.strptime(fdYmd, '%Y-%m-%d')
            except ValueError:
                pass
        results.append({
            'management_id': atcId,
            'color': clrNm,
            'stored_at': depPlace,
            'image': fdFilePathImg,
            'name': fdPrdtNm,
            'found_at': found_at,
            'prdtClNm': prdtClNm
        })
    return results

def parse_detail(xml_content: str):
    root = ET.fromstring(xml_content)
    body = root.find('body')
    if body is None:
        return None
    item = body.find('item')
    if item is None:
        return None
    csteSteNm = item.findtext('csteSteNm', '').strip()
    fdPlace = item.findtext('fdPlace', '').strip()
    tel = item.findtext('tel', '').strip()
    uniq = item.findtext('uniq', '').strip()
    if csteSteNm == '보관중':
        status = 'STORED'
    elif csteSteNm == '수령':
        status = 'RECEIVED'
    else:
        status = 'TRANSFERRED'
    return {
        'status': status,
        'location': fdPlace,
        'phone': tel,
        'detail': uniq
    }
