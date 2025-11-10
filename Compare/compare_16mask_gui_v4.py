# -*- coding: utf-8 -*-
"""
compare_16mask_gui_v4.py  — PySimpleGUI, text-only 2D 可視化

需求：
- 讀兩個文字檔（每行格式：ADDR  DATA，如 "0000 1E_1E_D230"）
- 逐位址比對，16 筆為一組，產生 16-bit mask：
    FFFF = 全對；首筆錯 = 7FFF；前兩筆錯 = 3FFF…，bit15 對應組內第一筆
- 以「文字表格」呈現 2D 視覺（列：0x0000、0x0100…；欄：+00、+10…、+F0）
- 只要不是 FFFF 就用紅色（文字色）
- 可儲存 CSV 或 純文字報表
"""
from pathlib import Path
import PySimpleGUI as sg
import pandas as pd

sg.set_options(font=('Courier 12'))
sg.theme('DarkGray2')

# ---------- Parsing ----------
def _open_text(path: Path) -> str:
    for enc in ('utf-8-sig', 'utf-8', 'latin-1'):
        try:
            return path.read_text(encoding=enc)
        except Exception:
            continue
    return path.read_text(errors='ignore')

def parse_file(p: Path):
    """回傳 (addr->data字串 的 dict, 總行數, 成功解析行數, 範例錯行list)"""
    text = _open_text(p)
    d = {}
    total = 0
    matched = 0
    bad = []
    for raw in text.splitlines():
        total += 1
        line = raw.strip()
        if not line:
            continue
        # 去除簡單行尾註解
        for tok in ('//', '#', ';'):
            idx = line.find(tok)
            if idx != -1:
                line = line[:idx].strip()
        if not line:
            continue
        parts = line.split()
        if len(parts) < 2:
            if len(bad) < 3:
                bad.append(raw[:120])
            continue
        addr_token = parts[0]
        if addr_token.lower().startswith('0x'):
            addr_token = addr_token[2:]
        try:
            addr = int(addr_token, 16)
        except Exception:
            if len(bad) < 3:
                bad.append(raw[:120])
            continue
        data = parts[1].upper()
        d[addr] = data
        matched += 1
    return d, total, matched, bad

# ---------- Core ----------
def build_masks(a: dict, b: dict):
    if not a and not b:
        return {}, [], []
    all_addrs = sorted(set(a.keys()) | set(b.keys()))
    first = (min(all_addrs)//16)*16
    last  = ((max(all_addrs)//16)+1)*16 - 1
    masks = {}
    for base in range(first, last+1, 16):
        mask = 0xFFFF
        for i in range(16):
            addr = base + i
            v1 = a.get(addr)
            v2 = b.get(addr)
            is_match = (v1 == v2) and (v1 is not None)
            if not is_match:
                mask &= ~(1 << (15 - i))
        masks[base] = mask
    row_bases = list(range((first // 256) * 256, ((last // 256) + 1) * 256, 256))
    col_offsets = [i*16 for i in range(16)]  # +00..+F0
    return masks, row_bases, col_offsets

def dataframe_from(masks, row_bases, col_offsets):
    rows = []
    for rb in row_bases:
        row = []
        for off in col_offsets:
            base = rb + off
            row.append(f'{masks.get(base, 0xFFFF):04X}')
        rows.append(row)
    df = pd.DataFrame(rows,
                      index=[f'{rb:04X}' for rb in row_bases],
                      columns=[f'+{off:02X}' for off in col_offsets])
    return df

# ---------- Text rendering (colored via Multiline.print) ----------
def render_text_grid(mline: sg.Multiline, df: pd.DataFrame):
    mline.update(value='')  # clear
    # 表頭
    mline.print('     ', end='')
    for c in df.columns:
        mline.print(f'{c:>5}', end='')
    mline.print()  # newline
    # 內容列
    for r_label, row in zip(df.index, df.values):
        mline.print(f'{r_label},', end='')
        for val in row:
            color = 'red' if val != 'FFFF' else None
            mline.print(f'{val:>5}', end='', text_color=color)
        mline.print()  # newline

def export_text(df: pd.DataFrame) -> str:
    lines = []
    header = '     ' + ''.join(f'{c:>5}' for c in df.columns)
    lines.append(header)
    for idx, row in zip(df.index, df.values):
        line = f'{idx},' + ''.join(f'{v:>5}' for v in row)
        lines.append(line)
    return '\n'.join(lines)

# ---------- GUI ----------
def layout():
    left = [
        [sg.Text('File A:'), sg.Input(key='-A-', size=(48,1)), sg.FileBrowse(file_types=(('Text','*.txt'),))],
        [sg.Text('File B:'), sg.Input(key='-B-', size=(48,1)), sg.FileBrowse(file_types=(('Text','*.txt'),))],
        [sg.Button('Run', key='-RUN-'),
         sg.Button('Save CSV', key='-CSV-', disabled=True),
         sg.Button('Save TXT', key='-TXT-', disabled=True),
         sg.Button('Exit')],
        [sg.Multiline('', key='-LOG-', size=(70,8), autoscroll=True, expand_x=True)]
    ]
    right = [[sg.Multiline(
        '',
        key='-GRID-',
        size=(110,35),
        autoscroll=False,
        disabled=True,
        write_only=True,
        font=('Courier New', 12),
        background_color='white',     # ✅ 設定白底
        text_color='black'            # ✅ 保持正常文字顏色
    )]]
    return [[sg.Column(left, vertical_alignment='top'), sg.VSeparator(),
             sg.Column(right, vertical_alignment='top', expand_x=True, expand_y=True)]]

def main():
    # 預填方便測試（若不存在也不影響）
    defaultA = Path('pdk_ecc.txt')
    defaultB = Path('r128_vdd_4500.txt')
    win = sg.Window('compare_16mask_gui_v4 (text-only)', layout(), finalize=True, resizable=True)
    if defaultA.exists(): win['-A-'].update(str(defaultA.resolve()))
    if defaultB.exists(): win['-B-'].update(str(defaultB.resolve()))

    cur_df = None

    while True:
        ev, vals = win.read()
        if ev in (sg.WIN_CLOSED, 'Exit'):
            break
        if ev == '-RUN-':
            ap, bp = vals['-A-'], vals['-B-']
            if not ap or not bp:
                win['-LOG-'].print('Please choose both files.')
                continue
            A, ta, ma, badA = parse_file(Path(ap))
            B, tb, mb, badB = parse_file(Path(bp))
            win['-LOG-'].print(f'Parsed A: {ma}/{ta}; Parsed B: {mb}/{tb}')
            if ma == 0 and mb == 0:
                win['-LOG-'].print('No valid lines. Check format.')
                if badA: win['-LOG-'].print('  A ex: ' + badA[0])
                if badB: win['-LOG-'].print('  B ex: ' + badB[0])
                continue
            masks, rows, cols = build_masks(A, B)
            df = dataframe_from(masks, rows, cols)
            render_text_grid(win['-GRID-'], df)
            win['-CSV-'].update(disabled=False); win['-TXT-'].update(disabled=False)
            cur_df = df
        elif ev == '-CSV-' and cur_df is not None:
            path = sg.popup_get_file('Save CSV', save_as=True, default_extension='csv', file_types=(('CSV','*.csv'),))
            if path:
                cur_df.to_csv(path, encoding='utf-8', index=True)
                win['-LOG-'].print(f'Saved CSV -> {path}')
        elif ev == '-TXT-' and cur_df is not None:
            path = sg.popup_get_file('Save TXT', save_as=True, default_extension='txt', file_types=(('Text','*.txt'),))
            if path:
                Path(path).write_text(export_text(cur_df), encoding='utf-8')
                win['-LOG-'].print(f'Saved TXT -> {path}')

    win.close()

if __name__ == '__main__':
    main()
