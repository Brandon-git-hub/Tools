import requests
import time
import pandas as pd
import os

def scrub_digital_frontend_jobs(pages_per_keyword=8):
    url_base = "https://www.104.com.tw/jobs/search/list"
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Referer': 'https://www.104.com.tw/jobs/search/'
    }
    
    all_jobs = []
    seen_links = set()
    
    # 針對數位前端與 Edge AI IC 核心關鍵字
    search_keywords = [
        "Digital IC Design", "數位IC設計", "RTL Design", "Edge AI", "NPU Design", 
        "AI Chip", "AI Accelerator", "Neural Network Processor"
    ]
    
    # --- 排除清單：排除 Layout、類比、FAE、純軟體、純驗證(若只要設計)、後端 ---
    exclude_keywords = [
        "Layout", "佈局", "Analog", "類比", "RF", "FAE", "Support", "測試工程師", 
        "軟體", "Software", "演算法", "Algorithm", "行銷", "業務", "行政", "硬體測試",
        "工讀生", "兼職", "Intern", "實習", "製程", "封裝", "後端", "Backend", "APR", "Physical Design",
        "製圖", "Drafting", "機構", "Mechanical", "室內設計", "美工", "Graphic", "行銷", "Marketing",
        "飯店", "餐飲", "保全", "司機", "作業員", "維修", "數位化", "事務所", "會計", "人資", "法務"
    ]

    # --- 包含清單：確保是數位設計相關 ---
    # 分為兩類：
    # 1. 明確的 IC 設計關鍵字
    design_keywords = ["數位", "DIGITAL", "RTL", "IC設計", "DESIGN ENGINEER", "ASIC", "SOC", "LOGIC DESIGN"]
    # 2. Edge AI 相關關鍵字 (加分項，若職缺名稱只寫 'Digital IC Design' 也會收，但若有 AI 更好)
    ai_keywords = ["NPU", "AI", "ACCELERATOR", "EDGE", "INFERENCE", "NEURAL", "DEEP LEARNING", "PROCESSOR", "COMPUTE"]

    excluded_exp = ["3年以上", "4年以上", "5年以上",  "6年以上", "7年以上", "8年以上", "9年以上", "10年以上"]

    for kw in search_keywords:
        print(f">>> 搜尋核心職缺：{kw}")
        for page in range(1, pages_per_keyword + 1):
            params = {
                'ro': '0', 'keyword': kw, 'area': '6001005000,6001006000',
                'order': '15', 'mode': 's', 'jobsource': '2018indexpg', 'page': page
            }
            try:
                response = requests.get(url_base, headers=headers, params=params)
                if response.status_code != 200: break
                jobs = response.json().get('data', {}).get('list', [])
                if not jobs: break

                for job in jobs:
                    job_link = f"https:{job['link']['job']}"
                    if job_link in seen_links: continue
                    
                    job_name = job.get('jobName', '')
                    exp_desc = job.get('periodDesc', '')
                    
                    # 邏輯過濾
                    is_excluded = any(bad.upper() in job_name.upper() for bad in exclude_keywords)
                    
                    # 必須包含至少一個設計關鍵字
                    is_design = any(k.upper() in job_name.upper() for k in design_keywords)
                    
                    # 或是明確的 AI 晶片相關
                    is_ai_chip = any(k.upper() in job_name.upper() for k in ai_keywords) and ("IC" in job_name.upper() or "CHIP" in job_name.upper() or "ENGINEER" in job_name.upper())

                    if not is_excluded and (is_design or is_ai_chip):
                        if not any(exp in exp_desc for exp in excluded_exp):
                            all_jobs.append({
                                '公司名稱': job.get('custName', ''),
                                '職位名稱': job_name,
                                '薪資範圍': job.get('salaryDesc', ''),
                                '經驗要求': exp_desc,
                                '連結': job_link
                            })
                            seen_links.add(job_link)
            except: continue
            time.sleep(1.2)
        
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
    csv_path = './Web_Crawler/104_Digital_Edge_IC_Filtered_Jobs.csv'
    md_path = './Web_Crawler/104_Digital_Edge_IC_Filtered_Jobs.md'
    
    df_final = scrub_digital_frontend_jobs()
    df_final.to_csv(csv_path, index=False, encoding='utf-8-sig')
    print(f"篩選完成，共取得 {len(df_final)} 筆高度相關職缺，已存入 {csv_path}")

    # 執行轉換
    csv_to_markdown(csv_path, md_path, "104 Digital IC & Edge AI 職缺篩選結果")
