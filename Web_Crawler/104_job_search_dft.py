import requests
import time
import pandas as pd
import os

def scrub_104_dft_jobs(pages=10):
    url_base = "https://www.104.com.tw/jobs/search/list"
    
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Referer': 'https://www.104.com.tw/jobs/search/'
    }
    
    all_jobs = []
    
    # 排除的年資關鍵字（篩選掉 3 年以上、5 年以上等）
    excluded_exp = ["3年以上", "4年以上", "5年以上",  "6年以上", "7年以上", "8年以上", "9年以上", "10年以上"]

    for page in range(1, pages + 1):
        params = {
            'ro': '0',
            'keyword': 'DFT',
            'area': '6001005000,6001006000', # 桃園 (6001005000) 與 新竹 (6001006000)
            'order': '15',
            'mode': 's',
            'jobsource': '2018indexpg',
            'page': page
        }
        
        print(f"正在爬取第 {page} 頁...")
        response = requests.get(url_base, headers=headers, params=params)
        
        if response.status_code == 200:
            data = response.json()
            jobs = data['data']['list']
            
            for job in jobs:
                job_name = job.get('jobName', '')
                exp_desc = job.get('periodDesc', '')
                
                # --- 篩選邏輯 ---
                # 1. 職位名稱必須包含 DFT
                if 'DFT' not in job_name.upper():
                    continue
                
                # 2. 篩選年資：排除掉 3 年以上的職位
                if any(exp in exp_desc for exp in excluded_exp):
                    continue
                
                job_info = {
                    '公司名稱': job.get('custName', ''),
                    '職位名稱': job_name,
                    '工作地點': job.get('jobAddrNoDesc', '') + job.get('jobAddress', ''),
                    '薪資範圍': job.get('salaryDesc', ''),
                    '經驗要求': exp_desc,
                    '學歷要求': job.get('optionEdu', ''),
                    '連結': f"https:{job['link']['job']}" if 'link' in job and 'job' in job['link'] else ''
                }
                all_jobs.append(job_info)
        else:
            print(f"請求失敗，狀態碼：{response.status_code}")
        
        time.sleep(2)
        
    return pd.DataFrame(all_jobs)

def csv_to_markdown(csv_file, md_file, title):
    if not os.path.exists(csv_file):
        print(f"錯誤：找不到檔案 {csv_file}")
        return

    # 讀取 CSV
    df = pd.read_csv(csv_file, encoding='utf-8-sig')

    if df.empty:
        print("CSV 檔案為空，跳過 Markdown 轉換。")
        return

    # 處理超連結：將「職位名稱」與「連結」合併為 Markdown 格式 [職位名稱](連結)
    # 然後刪除原始的「連結」欄位
    df['職位名稱'] = df.apply(lambda x: f"[{x['職位名稱']}]({x['連結']})", axis=1)
    df_display = df.drop(columns=['連結'])

    # 轉換為 Markdown 表格字串
    md_table = df_display.to_markdown(index=False)

    # 寫入檔案
    with open(md_file, 'w', encoding='utf-8') as f:
        f.write(f"# {title}\n\n")
        f.write(f"更新時間: {pd.Timestamp.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
        f.write(md_table)

    print(f"成功將 {csv_file} 轉換為 {md_file}")

if __name__ == "__main__":
    csv_path = './Web_Crawler/104_DFT_Filtered_Jobs.csv'
    md_path = './Web_Crawler/104_DFT_Filtered_Jobs.md'
    
    # 執行爬蟲
    df = scrub_104_dft_jobs(pages=10) # 建議頁數設多一點，因為過濾後職缺會變少
    df.to_csv(csv_path, index=False, encoding='utf-8-sig')
    print(f"爬取與篩選完成，共取得 {len(df)} 筆職缺，已存入 {csv_path}")

    # 執行轉換
    csv_to_markdown(csv_path, md_path, "104 DFT 職缺篩選結果")
