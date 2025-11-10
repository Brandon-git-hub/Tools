import PySimpleGUI as sg

def parse_file(fname):
    """
    將 txt 檔轉成:
    {
        '0000': ('1E','1E','D230'),
        ...
    }
    """
    data = {}
    with open(fname, 'r') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                addr, content = line.split()
                ecc1, ecc2, data16 = content.split('_')
                data[addr.upper()] = (ecc1.upper(), ecc2.upper(), data16.upper())
            except:
                print("Format error:", line)
    return data


def compare_dicts(d1, d2):
    """
    回傳 list of (addr, d1_val, d2_val)
    只列出不同的 address
    """
    addrs = sorted(set(d1.keys()) | set(d2.keys()))
    diff = []

    for addr in addrs:
        v1 = d1.get(addr, ("--","--","------"))
        v2 = d2.get(addr, ("--","--","------"))

        if v1 != v2:
            diff.append((addr, v1, v2))
    return diff


def format_tuple(t):
    return f"{t[0]}_{t[1]}_{t[2]}"


def main():
    sg.theme("DarkBlue3")

    layout = [
        [sg.Text("File 1 (pdk_ecc.txt):"), sg.Input(key="-F1-"), sg.FileBrowse()],
        [sg.Text("File 2 (r128_vdd_4500.txt):"), sg.Input(key="-F2-"), sg.FileBrowse()],
        [sg.Button("Compare", size=(12,1)), sg.Button("Exit")],
        [sg.Text("Differences:")],
        [sg.Table(
            headings=["ADDR", "File1", "File2"],
            values=[],
            key="-TABLE-",
            col_widths=[8,20,20],
            auto_size_columns=False,
            num_rows=25,
            justification='center',
            alternating_row_color='#2D2D2D'
        )],
        [sg.Button("Export CSV", key="-CSV-", disabled=True)]
    ]

    window = sg.Window("ECC Compare Tool", layout, finalize=True)

    diff_data = []

    while True:
        event, values = window.read()
        if event in (sg.WIN_CLOSED, "Exit"):
            break

        if event == "Compare":
            f1 = values["-F1-"]
            f2 = values["-F2-"]

            if not f1 or not f2:
                sg.popup("請選擇兩個 TXT 檔案")
                continue

            d1 = parse_file(f1)
            d2 = parse_file(f2)

            diff = compare_dicts(d1, d2)

            table_values = []
            for addr, v1, v2 in diff:
                table_values.append([
                    addr,
                    format_tuple(v1),
                    format_tuple(v2)
                ])

            diff_data = table_values
            window["-TABLE-"].update(values=table_values)
            window["-CSV-"].update(disabled=(len(table_values)==0))

            sg.popup(f"比較完成，共 {len(table_values)} 筆差異。")

        if event == "-CSV-":
            out = sg.popup_get_file("Save CSV", save_as=True, default_extension=".csv")
            if out:
                with open(out, "w") as f:
                    f.write("ADDR,File1,File2\n")
                    for row in diff_data:
                        f.write(",".join(row) + "\n")
                sg.popup("匯出完成")

    window.close()


if __name__ == "__main__":
    main()
