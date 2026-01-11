import requests
import time
import pandas as pd

def scrub_104_dft_jobs(pages=3):
    url_base = "https://www.104.com.tw/jobs/search/list"
    
    # 模擬瀏覽器的 Header，避免被擋
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Referer': 'https://www.104.com.tw/jobs/search/'
    }
    
    all_jobs = []
    
    for page in range(1, pages + 1):
        params = {
            'ro': '0',               # 0:全部, 1:正職
            'keyword': 'DFT',        # 關鍵字
            'order': '15',           # 排序方式 (15:最新)
            'mode': 's',             # 列表模式
            'jobsource': '2018indexpg',
            'page': page
        }
        
        print(f"正在爬取第 {page} 頁...")
        response = requests.get(url_base, headers=headers, params=params)
        
        if response.status_code == 200:
            data = response.json()
            jobs = data['data']['list']
            
            for job in jobs:
                job_info = {
                    '公司名稱': job.get('custName', ''),
                    '職位名稱': job.get('jobName', ''),
                    '工作地點': job.get('jobAddrNoDesc', '') + job.get('jobAddress', ''),
                    '薪資範圍': job.get('salaryDesc', ''),
                    '經驗要求': job.get('periodDesc', ''),
                    '學歷要求': job.get('optionEdu', ''),
                    '連結': f"https:{job['link']['job']}" if 'link' in job and 'job' in job['link'] else ''
                }
                all_jobs.append(job_info)
        else:
            print(f"請求失敗，狀態碼：{response.status_code}")
        
        # 禮貌性延遲，避免被封 IP
        time.sleep(2)
        
    return pd.DataFrame(all_jobs)

# 執行並儲存
df = scrub_104_dft_jobs(pages=5)
df.to_csv('./Web_Crawler/104_DFT_Jobs.csv', index=False, encoding='utf-8-sig')
print("爬取完成，已存入 104_DFT_Jobs.csv")
