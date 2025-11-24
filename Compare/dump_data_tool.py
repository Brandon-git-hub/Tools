import os
import re
import json
try:
    from tkinter import colorchooser
except Exception:
    colorchooser = None
import pandas as pd
import PySimpleGUI as sg


def read_files_to_df(paths, names):
    df_combined = pd.DataFrame()
    for p, name in zip(paths, names):
        try:
            df = pd.read_csv(p, header=None, sep='\\s+')
            df = df.apply(lambda x: x.str.rstrip() if x.dtype == "object" else x)

            num_cols = len(df.columns)            
            if (num_cols<2): continue # as last 2 column
            
            last_row = df.iloc[-1]  # get last row       
            if (last_row[0] == 'A\\mV'):
                df = df.drop(df.index[-1])

            first_row = df.iloc[0]         
            has_amv_header = (first_row[0] == 'A\\mV')
            if (has_amv_header):                                
                df = df.drop(0, axis=0)             # drop 1st row                                           
                new_colnames = first_row[1:]        # get col name
            else:
                nm, ext = os.path.splitext(name)    # set columns
                new_colnames = [nm]                 # using file name as col anme

            first_col = df.iloc[:, 0]               # copy 1st column           
            df = df.drop(columns=df.columns[0])     # drop 1st column           
            df.columns = new_colnames               # set new column names

            df.index = [int(x, 16) for x in first_col]  # set new index (should be use int-type-list, for ecc fail marker)
            #print(df.head())
            df_combined = pd.concat([df_combined, df], axis=1)            
            #print(df_combined.head())
    
        except FileNotFoundError:
            print(f"Error: The file '{p}' was not found.")
    
    return df_combined


def build_preview_text(df, index_header='A\\mV', filter_low=None, filter_high=None, filter_step=None, indices=None,
                       col_filter_low=None, col_filter_high=None, col_filter_step=None):
    if df is None or df.empty:
        return ''

    all_col_names = list(df.columns)
    num_cols = len(all_col_names)

    # Filter columns if parameters provided
    if col_filter_low is not None and col_filter_high is not None:
        c_start = max(0, col_filter_low)
        c_end = min(col_filter_high, num_cols - 1)
        if c_start > c_end:
            col_indices = []
        else:
            step = col_filter_step if (col_filter_step is not None and col_filter_step > 0) else 1
            col_indices = list(range(c_start, c_end + 1, step))
        col_names = [all_col_names[i] for i in col_indices]
    else:
        col_names = all_col_names

    # prepare string values for each cell
    cols = {}
    for name in col_names:
        cols[name] = [str(x) if x is not None else '' for x in df[name].tolist()]

    # compute column widths (at least as wide as header)
    widths = []
    for name in col_names:
        max_cell = max((len(s) for s in cols[name]), default=0)
        widths.append(max(len(name), max_cell))

    # index column: determine which rows to show based on optional explicit indices
    nrows = len(df)
    if indices is not None:
        # use provided indices directly (assumed to be within 0..nrows-1)
        indices = [i for i in indices if 0 <= i < nrows]
    else:
        # compute based on filter_low/filter_high/filter_step
        if filter_low is not None and filter_high is not None:
            # if step is not provided or <=1 show contiguous range
            if filter_step is None or filter_step <= 1:
                indices = [i for i in range(nrows) if filter_low <= i <= filter_high]
            else:
                # ensure start within bounds
                start = max(0, filter_low)
                end = min(filter_high, nrows - 1)
                if start > end:
                    indices = []
                else:
                    indices = list(range(start, end + 1, filter_step))
        else:
            # no bounds: use full range; apply step if provided
            if filter_step is None or filter_step <= 1:
                indices = list(range(nrows))
            else:
                indices = list(range(0, nrows, filter_step))

    if not indices:
        # nothing to show but still render header
        index_width = max(4, len(str(index_header)))
    else:
        max_index = max(indices)
        index_width = max(4, len(f"{max_index:X}"), len(str(index_header)))

    # header: index column header then file names; right-justify the index header
    header_idx = str(index_header).rjust(index_width)
    header_parts = [header_idx]
    for name, w in zip(col_names, widths):
        header_parts.append(name.ljust(w))
    header = '  '.join(header_parts)

    lines = [header]
    for i in indices:
        #idx = f"{i:04X}"
        idx = f"{df.index[i]:04X}"  # change to output index value
        row_parts = [idx.rjust(index_width)]
        for name, w in zip(col_names, widths):
            cell = cols[name][i] if i < len(cols[name]) else ''
            row_parts.append(cell.ljust(w))
        lines.append('  '.join(row_parts))

    return '\n'.join(lines)


def main():
    #sg.theme('LightGray1')
    sg.set_options(font=('Courier 10'))
    # settings file
    SETTINGS_FILE = os.path.join(os.path.dirname(__file__), 'settings.json')

    def save_settings(settings: dict):
        try:
            with open(SETTINGS_FILE, 'w', encoding='utf-8') as sf:
                json.dump(settings, sf, ensure_ascii=False, indent=2)
        except Exception as e:
            sg.popup(f'儲存設定失敗: {e}', title='Error')

    def load_settings():
        if not os.path.exists(SETTINGS_FILE):
            return {}
        try:
            with open(SETTINGS_FILE, 'r', encoding='utf-8') as sf:
                return json.load(sf)
        except Exception:
            return {}

    file_paths = []  # full paths
    file_names = []  # basenames shown in listbox

    listbox = sg.Listbox(values=file_names, select_mode=sg.SELECT_MODE_EXTENDED,
                         size=(50, 12), key='-FILE_LIST-', enable_events=True, tooltip='')

    buttons_col = sg.Column([
        [sg.Button('Filter', key='-FILTER-', size=(10, 1))],
        [sg.Button('Add', key='-ADD-', size=(10, 1))],
        [sg.Button('Remove', key='-REMOVE-', size=(10, 1))],
        [sg.Button('Load', key='LOAD-', size=(10, 1))],
        [sg.Button('Save', key='-SAVE-', size=(10, 1))],
        [sg.Button('Settings', key='-SAVE_SETTINGS-', size=(10, 1))],
        [sg.Button('Exit', key='-EXIT-', size=(10, 1))]
    ])

    # controls for index header text, filter and highlight (moved to right side)
    idx_controls = sg.Column([
        [sg.Checkbox('Enable Row Filter', key='-IDX_FILTER_ENABLE-'),
         sg.Text('From:'), sg.Input(default_text='', size=(8, 1), key='-IDX_FILTER_LOW-'),
         sg.Text('To:'), sg.Input(default_text='', size=(8, 1), key='-IDX_FILTER_HIGH-'),
         sg.Text('Step:'), sg.Input(default_text='', size=(8,1), key='-IDX_FILTER_STEP-')],
        [sg.Checkbox('Enable Col Filter', key='-COL_FILTER_ENABLE-'),
         sg.Text('From:'), sg.Input(default_text='0', size=(8, 1), key='-COL_FILTER_LOW-'),
         sg.Text('To:'), sg.Input(default_text='', size=(8, 1), key='-COL_FILTER_HIGH-'),
         sg.Text('Step:'), sg.Input(default_text='', size=(8,1), key='-COL_FILTER_STEP-')],
        [sg.Checkbox('Enable Highlight', key='-HL_ENABLE-')],
        [sg.Text('Pattern1:'), sg.Input(default_text='1F_1F_FFFF', size=(14, 1), key='-HL_PATTERN_1-'),
         sg.Text('Color1:'), sg.Input(default_text='#D3D3D3', size=(10,1), key='-HL_COLOR_1-')],
        [sg.Text('Pattern2:'), sg.Input(default_text='', size=(14, 1), key='-HL_PATTERN_2-'),
         sg.Text('Color2:'), sg.Input(default_text='', size=(10,1), key='-HL_COLOR_2-')],
        [sg.Text('Pattern3:'), sg.Input(default_text='', size=(14, 1), key='-HL_PATTERN_3-'),
         sg.Text('Color3:'), sg.Input(default_text='', size=(10,1), key='-HL_COLOR_3-')],
        [sg.Checkbox('ECC fail check', key='-ECC_ENABLE-'), sg.Text('ECC Fail Color:'), sg.Input(default_text='#FFA0A0', size=(10,1), key='-ECC_COLOR-')],
        [sg.Text('(colors: hex like #D3D3D3 or color names)')]
    ])

    # arrange list, controls, and buttons in three side-by-side columns
    layout_main = [
        [sg.Text('Files List:')],
        [
            listbox,
            idx_controls,
            buttons_col
        ]
    ]

    # main layout
    layout = layout_main + [
        [sg.Text('Preview (Courier New):'), sg.Button('Clear', key='-CLEAR-', size=(10, 1))],
        [sg.Multiline('', size=(120, 24), key='-PREVIEW-', font=('Courier New', 11), disabled=False, expand_x=True, expand_y=True, horizontal_scroll=True)]
    ]

    # load initial window size/location if available
    init_loc = (None, None)
    init_size = (None, None)
    loaded_settings = load_settings()
    if loaded_settings:
        loc = loaded_settings.get('window_location')
        sz = loaded_settings.get('window_size')
        if loc and len(loc) == 2:
            init_loc = tuple(loc)
        if sz and len(sz) == 2:
            init_size = tuple(sz)

    window = sg.Window('Dump data tool', layout, finalize=True, resizable=True, location=init_loc, size=init_size)
    # bind right-click on the file list to a custom event suffix
    try:
        window['-FILE_LIST-'].bind('<Button-3>', '+RIGHT')
    except Exception:
        # some PySimpleGUI versions/platforms may not support bind; ignore if fails
        pass
    
    # bind Delete key to remove selected files
    try:
        window['-FILE_LIST-'].bind('<Delete>', '+DELETE')
    except Exception:
        pass
    
    # Create tooltip functionality for file list to show full path
    try:
        import tkinter as tk
        listbox_widget = window['-FILE_LIST-'].Widget
        tooltip_window = None
        tooltip_timer = None
        last_index = None
        
        def show_tooltip(event):
            nonlocal tooltip_window, tooltip_timer, last_index
            try:
                # Get the index of the item under the mouse
                index = listbox_widget.nearest(event.y)
                
                # Only proceed if we have files and cursor is over a valid item
                if 0 <= index < len(file_paths):
                    # Check if this item is selected
                    selected_indices = listbox_widget.curselection()
                    
                    # Only show tooltip if the item is selected
                    if index not in selected_indices:
                        # Not selected, hide any existing tooltip
                        last_index = None
                        hide_tooltip()
                        return
                    
                    # If hovering over same item, don't recreate tooltip
                    if index == last_index and tooltip_window:
                        return
                    
                    last_index = index
                    
                    # Cancel any pending tooltip
                    if tooltip_timer:
                        listbox_widget.after_cancel(tooltip_timer)
                    
                    # Hide existing tooltip
                    hide_tooltip()
                    
                    # Schedule new tooltip to appear after short delay (reduces flickering)
                    def create_tooltip():
                        nonlocal tooltip_window
                        try:
                            tooltip_window = tk.Toplevel(listbox_widget)
                            tooltip_window.wm_overrideredirect(True)
                            tooltip_window.wm_geometry(f"+{event.x_root + 15}+{event.y_root + 10}")
                            
                            label = tk.Label(tooltip_window, text=file_paths[index], 
                                           background="#ffffe0", relief="solid", borderwidth=1,
                                           font=("Arial", 9), padx=5, pady=2)
                            label.pack()
                        except Exception:
                            pass
                    
                    tooltip_timer = listbox_widget.after(500, create_tooltip)  # 500ms delay
                else:
                    # Mouse not over any item
                    last_index = None
                    hide_tooltip()
            except Exception:
                pass
        
        def hide_tooltip(event=None):
            nonlocal tooltip_window, tooltip_timer, last_index
            try:
                if tooltip_timer:
                    listbox_widget.after_cancel(tooltip_timer)
                    tooltip_timer = None
                if tooltip_window:
                    tooltip_window.destroy()
                    tooltip_window = None
                last_index = None
            except Exception:
                pass
        
        listbox_widget.bind('<Motion>', show_tooltip)
        listbox_widget.bind('<Leave>', hide_tooltip)
    except Exception:
        pass
    
    # bind right-click on color inputs to open color chooser
    try:
        window['-HL_COLOR_1-'].bind('<Button-3>', '+COLOR1')
        window['-HL_COLOR_2-'].bind('<Button-3>', '+COLOR2')
        window['-HL_COLOR_3-'].bind('<Button-3>', '+COLOR3')
        window['-ECC_COLOR-'].bind('<Button-3>', '+ECCCOLOR')
    except Exception:
        pass

    # helper: apply highlight tags to the Multiline's underlying tk.Text widget
    def apply_highlight_to_preview(win, df, patterns):
        """patterns: list of (pattern, color) tuples"""
        try:
            text_widget = win['-PREVIEW-'].Widget
        except Exception:
            return

        text = text_widget.get("1.0", "end-1c")

        # Remove old highlights
        for i in range(1, 4):
            text_widget.tag_remove(f'cell_hl{i}', "1.0", "end")

        lines = text.split("\n")

        for idx_pat, (pattern, color) in enumerate(patterns, start=1):
            if not pattern:
                continue

            tag = f'cell_hl{idx_pat}'
            text_widget.tag_config(tag, background=color)

            plen = len(pattern)

            # Search each line in Python - FAST
            for row, line in enumerate(lines, start=1):
                start = 0
                while True:
                    found = line.find(pattern, start)
                    if found == -1:
                        break

                    start_idx = f"{row}.{found}"
                    end_idx   = f"{row}.{found + plen}"

                    text_widget.tag_add(tag, start_idx, end_idx)

                    start = found + plen

    # ECC-specific highlighting: find cells in dataframe where format is aa_bb_cccc and aa != bb
    def apply_ecc_highlight(win, df, color):
        try:
            text_widget = win['-PREVIEW-'].Widget
        except Exception:
            return

        # remove previous ecc tag
        try:
            text_widget.tag_remove('ecc_fail', '1.0', 'end')
        except Exception:
            pass

        try:
            text_widget.tag_config('ecc_fail', background=color)
        except Exception:
            try:
                text_widget.tag_config('ecc_fail', background='#FFA0A0')
            except Exception:
                return

        # iterate dataframe cells and find strings of form aa_bb_... where aa != bb
        nrows = len(df)        
        for i in range(nrows):
            for col in df.columns:
                #val = df.at[i, col]   # df.at[i, col] uses labels, not positions.
                val = df.iloc[i][col]  # fix bug, should be position, so change to iloc 
                if val is None:
                    continue
                s = str(val).strip()
                if not s:
                    continue
                parts = s.split('_')
                if len(parts) < 3:
                    continue
                a, b = parts[0], parts[1]
                if a.upper() != b.upper():
                    # search for exact cell text in preview and tag it
                    start = '1.0'
                    plen = len(s)   # plen = 5 if fix 5                                     
                    while True:
                        try:
                            idx = text_widget.search(s, start, stopindex='end')
                        except Exception:
                            break
                        if not idx:
                            break
                        end = f"{idx}+{plen}c"
                        try:
                            text_widget.tag_add('ecc_fail', idx, end)
                        except Exception:
                            pass
                        start = end
        return

    def collect_settings(win, vals):
        s = {
            'filter_enabled': vals.get('-IDX_FILTER_ENABLE-', False),
            'filter_low': vals.get('-IDX_FILTER_LOW-', '').strip(),
            'filter_high': vals.get('-IDX_FILTER_HIGH-', '').strip(),
            'filter_step': vals.get('-IDX_FILTER_STEP-', '').strip(),
            'col_filter_enabled': vals.get('-COL_FILTER_ENABLE-', False),
            'col_filter_low': vals.get('-COL_FILTER_LOW-', '').strip(),
            'col_filter_high': vals.get('-COL_FILTER_HIGH-', '').strip(),
            'col_filter_step': vals.get('-COL_FILTER_STEP-', '').strip(),
            'hl_enabled': vals.get('-HL_ENABLE-', False),
            'hl_pattern_1': vals.get('-HL_PATTERN_1-', '').strip(),
            'hl_color_1': vals.get('-HL_COLOR_1-', '').strip(),
            'hl_pattern_2': vals.get('-HL_PATTERN_2-', '').strip(),
            'hl_color_2': vals.get('-HL_COLOR_2-', '').strip(),
            'hl_pattern_3': vals.get('-HL_PATTERN_3-', '').strip(),
            'hl_color_3': vals.get('-HL_COLOR_3-', '').strip(),
            'ecc_enabled': vals.get('-ECC_ENABLE-', False),
            'ecc_color': vals.get('-ECC_COLOR-', '').strip()
        }
        try:
            s['window_location'] = win.current_location()
            s['window_size'] = win.size
        except Exception:
            pass
        return s

    # load settings and apply to controls
    loaded = load_settings()
    if loaded:
        try:
            window['-IDX_FILTER_ENABLE-'].update(loaded.get('filter_enabled', False))
            window['-IDX_FILTER_LOW-'].update(loaded.get('filter_low', ''))
            window['-IDX_FILTER_HIGH-'].update(loaded.get('filter_high', ''))
            window['-IDX_FILTER_STEP-'].update(loaded.get('filter_step', ''))
            
            window['-COL_FILTER_ENABLE-'].update(loaded.get('col_filter_enabled', False))
            window['-COL_FILTER_LOW-'].update(loaded.get('col_filter_low', ''))
            window['-COL_FILTER_HIGH-'].update(loaded.get('col_filter_high', ''))
            window['-COL_FILTER_STEP-'].update(loaded.get('col_filter_step', ''))
            window['-HL_ENABLE-'].update(loaded.get('hl_enabled', False))
            # restore up to 3 patterns/colors
            window['-HL_PATTERN_1-'].update(loaded.get('hl_pattern_1', '1F_1F_FFFF'))
            c1 = loaded.get('hl_color_1', '') or ''
            if c1:
                try:
                    c1u = c1.upper()
                except Exception:
                    c1u = c1
                window['-HL_COLOR_1-'].update(c1u)
                try:
                    window['-HL_COLOR_1-'].Widget.config(bg=c1u)
                except Exception:
                    pass
            else:
                window['-HL_COLOR_1-'].update('#D3D3D3')

            window['-HL_PATTERN_2-'].update(loaded.get('hl_pattern_2', ''))
            c2 = loaded.get('hl_color_2', '') or ''
            if c2:
                try:
                    c2u = c2.upper()
                except Exception:
                    c2u = c2
                window['-HL_COLOR_2-'].update(c2u)
                try:
                    window['-HL_COLOR_2-'].Widget.config(bg=c2u)
                except Exception:
                    pass

            window['-HL_PATTERN_3-'].update(loaded.get('hl_pattern_3', ''))
            c3 = loaded.get('hl_color_3', '') or ''
            if c3:
                try:
                    c3u = c3.upper()
                except Exception:
                    c3u = c3
                window['-HL_COLOR_3-'].update(c3u)
                try:
                    window['-HL_COLOR_3-'].Widget.config(bg=c3u)
                except Exception:
                    pass
            else:
                # ensure field exists with empty/default value
                if not c1:
                    window['-HL_COLOR_1-'].update('#D3D3D3')
            # restore ECC settings
            try:
                window['-ECC_ENABLE-'].update(loaded.get('ecc_enabled', False))
                c_ecc = loaded.get('ecc_color', '') or ''
                if c_ecc:
                    try:
                        ceu = c_ecc.upper()
                    except Exception:
                        ceu = c_ecc
                    window['-ECC_COLOR-'].update(ceu)
                    try:
                        window['-ECC_COLOR-'].Widget.config(bg=ceu)
                    except Exception:
                        pass
                else:
                    window['-ECC_COLOR-'].update('#FFA0A0')
            except Exception:
                pass
        except Exception:
            pass

    current_preview = ''
    # store last run dataframe and parameters for filtering
    last_df = None
    last_preview_params = {}

    while True:
        event, values = window.read()
        if event in (sg.WIN_CLOSED, None):
            # auto-save all settings on close
            try:
                all_settings = collect_settings(window, values)
                save_settings(all_settings)
            except Exception:
                pass
            break
            
        if event == '-CLEAR-':
            current_preview = ''
            window['-PREVIEW-'].update(current_preview)
            last_df = None
            last_preview_params = {}
        elif event == '-ADD-':
            files_selected = sg.popup_get_file('Select files to add', multiple_files=True,
                                               file_types=(('Text Files', '*.txt'),), no_window=True)
            if files_selected:
                # normalize different return types from popup_get_file:
                # - a single string with ';' separated paths (Windows)
                # - a tuple/list of strings
                # - a single path string
                paths = []
                if isinstance(files_selected, str):
                    paths = [p for p in files_selected.split(';') if p]
                elif isinstance(files_selected, (list, tuple)):
                    for item in files_selected:
                        if isinstance(item, str):
                            paths.extend([p for p in item.split(';') if p])
                        else:
                            paths.append(item)
                else:
                    paths = [files_selected]
                
                for p in paths:
                    if not p:
                        continue
                    p = os.path.abspath(p)
                    name = os.path.basename(p)
                    # avoid duplicates by full path
                    if p not in file_paths:
                        # Check if this basename already exists
                        display_name = name
                        if name in file_names:
                            # Find a unique serial number
                            counter = 2
                            while f"{name} ({counter})" in file_names:
                                counter += 1
                            display_name = f"{name} ({counter})"
                        
                        file_paths.append(p)
                        file_names.append(display_name)
                window['-FILE_LIST-'].update(file_names)

        # right-click on list -> clear all selections
        elif event == '-FILE_LIST-+RIGHT':
            try:
                window['-FILE_LIST-'].update(set_to_index=[])
            except Exception:
                # fallback: update with same values to clear selection
                window['-FILE_LIST-'].update(values=file_names)
            continue
        
        # handle Delete key press to remove selected files
        elif event == '-FILE_LIST-+DELETE':
            selected = values.get('-FILE_LIST-', [])
            if not selected:
                continue
            # remove all selected basenames
            for name in selected:
                try:
                    idx = file_names.index(name)
                except ValueError:
                    continue
                file_names.pop(idx)
                file_paths.pop(idx)
            window['-FILE_LIST-'].update(file_names)
            # clear preview since selection changed
            current_preview = ''
            window['-PREVIEW-'].update(current_preview)
            continue

        elif event == '-FILTER-':
            if last_df is None:
                sg.popup('尚未有資料。請先按 Load 產生預覽後再使用 Filter。', title='Info')
                continue
            try:
                # read ADDR filter controls (From/To/Step)
                row_filter_enabled = values.get('-IDX_FILTER_ENABLE-', False)
                low_hex = values.get('-IDX_FILTER_LOW-', '').strip()
                high_hex = values.get('-IDX_FILTER_HIGH-', '').strip()
                step_hex = values.get('-IDX_FILTER_STEP-', '').strip()

                # read COL filter controls
                col_filter_enabled = values.get('-COL_FILTER_ENABLE-', False)
                col_low_hex = values.get('-COL_FILTER_LOW-', '').strip()
                col_high_hex = values.get('-COL_FILTER_HIGH-', '').strip()
                col_step_hex = values.get('-COL_FILTER_STEP-', '').strip()

                # Parse Row Filter
                filter_low = None
                filter_high = None
                filter_step = None

                if row_filter_enabled:
                    if not low_hex or not high_hex:
                        raise ValueError('啟用 Row Filter 時，請輸入 Row From 與 To（hex）。')
                    filter_low = int(low_hex.upper(), 16)
                    filter_high = int(high_hex.upper(), 16)
                    if filter_low > filter_high:
                        raise ValueError('Row From 必須小於或等於 To。')
                    if step_hex:
                        filter_step = int(step_hex.upper(), 16)
                        if filter_step <= 0:
                            raise ValueError('Row Step 必須大於 0。')
                        window['-IDX_FILTER_STEP-'].update(f"{filter_step:X}")
                    window['-IDX_FILTER_LOW-'].update(f"{filter_low:X}")
                    window['-IDX_FILTER_HIGH-'].update(f"{filter_high:X}")

                # Parse Col Filter
                c_low = None
                c_high = None
                c_step = None
                
                if col_filter_enabled:
                    if not col_low_hex or not col_high_hex:
                        raise ValueError('啟用 Column Filter 時，請輸入 Col From 與 To（hex）。')
                    
                    c_low = int(col_low_hex.upper(), 16)
                    c_high = int(col_high_hex.upper(), 16)
                    if c_low > c_high:
                        raise ValueError('Col From 必須小於或等於 To。')
                    if col_step_hex:
                        c_step = int(col_step_hex.upper(), 16)
                        if c_step <= 0:
                            raise ValueError('Col Step 必須大於 0。')
                        window['-COL_FILTER_STEP-'].update(f"{c_step:X}")
                    window['-COL_FILTER_LOW-'].update(f"{c_low:X}")
                    window['-COL_FILTER_HIGH-'].update(f"{c_high:X}")

                current_preview = build_preview_text(last_df, index_header=last_preview_params.get('idx_header', 'A\\mV'),
                                                    filter_low=filter_low, filter_high=filter_high, filter_step=filter_step,
                                                    col_filter_low=c_low, col_filter_high=c_high, col_filter_step=c_step)

                window['-PREVIEW-'].update(current_preview)
                # reapply highlight if enabled
                if values.get('-HL_ENABLE-', False):
                    patterns = []
                    p1 = values.get('-HL_PATTERN_1-', '').strip()
                    c1 = values.get('-HL_COLOR_1-', '').strip() or '#D3D3D3'
                    patterns.append((p1, c1))
                    p2 = values.get('-HL_PATTERN_2-', '').strip()
                    c2 = values.get('-HL_COLOR_2-', '').strip() or '#D3D3D3'
                    if p2:
                        patterns.append((p2, c2))
                    p3 = values.get('-HL_PATTERN_3-', '').strip()
                    c3 = values.get('-HL_COLOR_3-', '').strip() or '#D3D3D3'
                    if p3:
                        patterns.append((p3, c3))
                    if patterns:
                        apply_highlight_to_preview(window, last_df, patterns)
                    # apply ECC highlight if enabled
                    try:
                        if values.get('-ECC_ENABLE-', False):
                            ecc_color = values.get('-ECC_COLOR-', '').strip() or '#FFA0A0'
                            apply_ecc_highlight(window, last_df, ecc_color)
                    except Exception:
                        pass
            except Exception as e:
                sg.popup(f'Filter 失敗: {e}', title='Error')
            continue

        # color chooser triggers (right-click on color inputs)
        elif event == '-HL_COLOR_1-+COLOR1' or event == '-HL_COLOR_2-+COLOR2' or event == '-HL_COLOR_3-+COLOR3' or event == '-ECC_COLOR-+ECCCOLOR':
            if colorchooser is None:
                sg.popup('Color chooser not available in this environment.', title='Error')
                continue
            try:
                # open color chooser
                col = colorchooser.askcolor()
                if not col:
                    continue
                hexcol = col[1]
                if not hexcol:
                    continue
                # determine which field triggered
                if event.startswith('-HL_COLOR_1-'):
                    key = '-HL_COLOR_1-'
                elif event.startswith('-HL_COLOR_2-'):
                    key = '-HL_COLOR_2-'
                elif event.startswith('-ECC_COLOR-'):
                    key = '-ECC_COLOR-'
                else:
                    key = '-HL_COLOR_3-'
                # update the input value and try to set background color
                window[key].update(value=hexcol.upper())
                try:
                    window[key].Widget.config(bg=hexcol)
                except Exception:
                    pass
            except Exception:
                pass
            continue

        elif event == '-REMOVE-':
            selected = values.get('-FILE_LIST-', [])
            if not selected:
                continue
            # remove all selected basenames (first matching path)
            for name in selected:
                # find index of first occurrence of this basename
                try:
                    idx = file_names.index(name)
                except ValueError:
                    continue
                file_names.pop(idx)
                file_paths.pop(idx)
            window['-FILE_LIST-'].update(file_names)
            # clear preview since selection changed
            current_preview = ''
            window['-PREVIEW-'].update(current_preview)

        elif event == 'LOAD-':
            if not file_paths:
                sg.popup('請先加入至少一個檔案。', title='Error')
                continue
            try:
                # determine which files to process: selected in list -> process those; otherwise process all
                selected = values.get('-FILE_LIST-', [])
                if selected:
                    # build mapping name->list of indices to handle duplicate basenames
                    name_to_indices = {}
                    for idx, nm in enumerate(file_names):
                        name_to_indices.setdefault(nm, []).append(idx)
                    sel_indices = []
                    for nm in selected:
                        lst = name_to_indices.get(nm, [])
                        if lst:
                            sel_indices.append(lst.pop(0))
                    sel_paths = [file_paths[i] for i in sel_indices]
                    sel_names = [file_names[i] for i in sel_indices]
                    # Debug: show what's being loaded
                    print(f"Loading {len(sel_paths)} selected files: {sel_names}")
                else:
                    sel_paths = list(file_paths)
                    sel_names = list(file_names)
                    # Debug: show what's being loaded
                    print(f"Loading all {len(sel_paths)} files: {sel_names}")


                df = read_files_to_df(sel_paths, sel_names)
                # fixed index header
                idx_header = 'A\\mV'

                # IDX (Row) filter
                filter_enabled = values.get('-IDX_FILTER_ENABLE-', False)
                low_hex = values.get('-IDX_FILTER_LOW-', '').strip()
                high_hex = values.get('-IDX_FILTER_HIGH-', '').strip()
                filter_low = None
                filter_high = None
                filter_step = None

                if filter_enabled:
                    try:
                        if not low_hex or not high_hex:
                            raise ValueError('請輸入 Row 範圍的 From 與 To（hex）。')
                        # normalize to uppercase hex and parse
                        low_hex_upper = low_hex.upper()
                        high_hex_upper = high_hex.upper()
                        filter_low = int(low_hex_upper, 16)
                        filter_high = int(high_hex_upper, 16)
                        if filter_low > filter_high:
                            raise ValueError('Row From 必須小於或等於 To。')
                        # parse optional step (hex)
                        step_hex = values.get('-IDX_FILTER_STEP-', '').strip()
                        if step_hex:
                            try:
                                step_hex_upper = step_hex.upper()
                                filter_step = int(step_hex_upper, 16)
                                if filter_step <= 0:
                                    raise ValueError('Row Step 必須大於 0。')
                                window['-IDX_FILTER_STEP-'].update(f"{filter_step:X}")
                            except Exception as se:
                                raise ValueError(f'Row Step 解析錯誤: {se}')
                        # update UI to show uppercase normalized values
                        window['-IDX_FILTER_LOW-'].update(f"{filter_low:X}")
                        window['-IDX_FILTER_HIGH-'].update(f"{filter_high:X}")
                    except Exception as fe:
                        sg.popup(f'Row 篩選錯誤: {fe}', title='Error')
                        continue

                # COL Filter
                col_filter_enabled = values.get('-COL_FILTER_ENABLE-', False)
                col_low_hex = values.get('-COL_FILTER_LOW-', '').strip()
                col_high_hex = values.get('-COL_FILTER_HIGH-', '').strip()
                col_filter_low = None
                col_filter_high = None
                col_filter_step = None
                
                if col_filter_enabled:
                    try:
                        if not col_low_hex or not col_high_hex:
                            raise ValueError('請輸入 Column 範圍的 From 與 To（hex）。')
                        c_low_upper = col_low_hex.upper()
                        c_high_upper = col_high_hex.upper()
                        col_filter_low = int(c_low_upper, 16)
                        col_filter_high = int(c_high_upper, 16)
                        if col_filter_low > col_filter_high:
                            raise ValueError('Col From 必須小於或等於 To。')
                        
                        col_step_hex = values.get('-COL_FILTER_STEP-', '').strip()
                        if col_step_hex:
                            try:
                                c_step_upper = col_step_hex.upper()
                                col_filter_step = int(c_step_upper, 16)
                                if col_filter_step <= 0:
                                    raise ValueError('Col Step 必須大於 0。')
                                window['-COL_FILTER_STEP-'].update(f"{col_filter_step:X}")
                            except Exception as se:
                                raise ValueError(f'Col Step 解析錯誤: {se}')
                        window['-COL_FILTER_LOW-'].update(f"{col_filter_low:X}")
                        window['-COL_FILTER_HIGH-'].update(f"{col_filter_high:X}")
                    except Exception as fe:
                        sg.popup(f'Column 篩選錯誤: {fe}', title='Error')
                        continue

                current_preview = build_preview_text(df, index_header=idx_header,
                                                    filter_low=filter_low, filter_high=filter_high,
                                                    filter_step=filter_step,
                                                    col_filter_low=col_filter_low, col_filter_high=col_filter_high,
                                                    col_filter_step=col_filter_step)
                window['-PREVIEW-'].update(current_preview)
                # save last run state for filter button
                last_df = df
                last_preview_params = {
                    'idx_header': idx_header,
                    'filter_low': filter_low,
                    'filter_high': filter_high,
                    'filter_step': filter_step if 'filter_step' in locals() else None,
                    'col_filter_low': col_filter_low,
                    'col_filter_high': col_filter_high,
                    'col_filter_step': col_filter_step if 'col_filter_step' in locals() else None
                }

                # apply highlight if enabled: collect up to 3 patterns
                hl_enabled = values.get('-HL_ENABLE-', False)
                if hl_enabled:
                    patterns = []
                    p1 = values.get('-HL_PATTERN_1-', '').strip()
                    c1 = values.get('-HL_COLOR_1-', '').strip() or '#D3D3D3'
                    patterns.append((p1, c1))
                    p2 = values.get('-HL_PATTERN_2-', '').strip()
                    c2 = values.get('-HL_COLOR_2-', '').strip() or '#D3D3D3'
                    if p2:
                        patterns.append((p2, c2))
                    p3 = values.get('-HL_PATTERN_3-', '').strip()
                    c3 = values.get('-HL_COLOR_3-', '').strip() or '#D3D3D3'
                    if p3:
                        patterns.append((p3, c3))
                    if patterns:
                        apply_highlight_to_preview(window, df, patterns)
                    # also reapply highlighting state saved for last preview
                    last_patterns = patterns
                # apply ECC highlighting if enabled
                try:
                    if values.get('-ECC_ENABLE-', False):
                        ecc_color = values.get('-ECC_COLOR-', '').strip() or '#FFA0A0'
                        apply_ecc_highlight(window, df, ecc_color)
                except Exception:
                    pass
                # continue
            except Exception as e:
                sg.popup(f'合併失敗: {e}', title='Error')

        elif event == '-SAVE_SETTINGS-':
            # collect current filter settings and save
            try:
                all_settings = collect_settings(window, values)
                save_settings(all_settings)
                sg.popup('設定已儲存。', title='Saved')
            except Exception as e:
                sg.popup(f'儲存設定失敗: {e}', title='Error')

        elif event == '-EXIT-':
            # auto-save all settings on exit
            try:
                all_settings = collect_settings(window, values)
                save_settings(all_settings)
            except Exception:
                pass
            # close window and exit loop
            window.close()
            break

        elif event == '-SAVE-':
            if not current_preview:
                sg.popup('目前沒有要儲存的預覽內容，請先按 Load。', title='Info')
                continue
            save_path = sg.popup_get_file('Save preview as', save_as=True, no_window=True,
                                         file_types=(('Text Files', '*.txt'),))
            if save_path:
                try:
                    with open(save_path, 'w', encoding='utf-8') as f:
                        f.write(current_preview)
                    sg.popup(f'已儲存到 {save_path}', title='Saved')
                except Exception as e:
                    sg.popup(f'儲存失敗: {e}', title='Error')

    window.close()


if __name__ == '__main__':
    main()
