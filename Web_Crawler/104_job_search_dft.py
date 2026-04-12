import json
import asyncio
import random
import pandas as pd
import os
from playwright.async_api import async_playwright

async def scrub_104_dft_jobs(pages=5):
    all_jobs_raw = []
    
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=False) 
        context = await browser.new_context(
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
        )
        page = await context.new_page()

        def handle_response(response):
            if "api/jobs" in response.url and response.status == 200:
                async def parse_json():
                    try:
                        data = await response.json()
                        if 'data' in data and isinstance(data['data'], list):
                            job_list = data['data']
                            # 使用 set 來過濾重複的 jobNo，避免重複添加
                            new_jobs = [job for job in job_list if job.get('jobNo') not in {j.get('jobNo') for j in all_jobs_raw}]
                            if new_jobs:
                                all_jobs_raw.extend(new_jobs)
                                print(f"  [攔截] 成功添加 {len(new_jobs)} 筆新職缺。")
                    except:
                        pass
                asyncio.create_task(parse_json())

        page.on("response", handle_response)

        print("正在前往 104 (視窗模式)...")
        await page.goto("https://www.104.com.tw/jobs/search/?keyword=DFT&area=6001005000,6001006000&order=15", wait_until="networkidle")
        
        for i in range(1, pages + 1):
            print(f"正在處理第 {i} 頁...")
            try:
                await page.wait_for_selector(".job-summary", timeout=15000)
            except:
                print("  [警告] 找不到職缺內容，可能已達末頁或被阻擋。")
                break

            await page.evaluate("window.scrollTo(0, document.body.scrollHeight)")
            await asyncio.sleep(random.uniform(1, 2)) # 等待滾動效果

            if i < pages:
                next_btn = page.locator("button.js-next-page").first
                if await next_btn.is_visible() and await next_btn.is_enabled():
                    print("  點擊 '下一頁'...")
                    await next_btn.click()
                    # --- 關鍵修復：等待點擊後的網路活動靜止 ---
                    print("  等待頁面資料載入...")
                    await page.wait_for_load_state("networkidle", timeout=10000)
                else:
                    print("  [資訊] 已無 '下一頁' 按鈕，抓取結束。")
                    break

        print("所有頁面處理完畢，等待 3 秒讓最後的 API 完成...")
        await asyncio.sleep(3)
        await browser.close()

    # --- 篩選 ---
    excluded_exp = ["3年以上", "4年以上", "5年以上", "6年以上", "7年以上", "8年以上", "9年以上", "10年以上"]
    filtered_jobs = []
    seen_links = set()
    for job in all_jobs_raw:
        job_link = f"https:{job.get('link', {}).get('job', '')}"
        if not job_link or job_link in seen_links: continue
        job_name = job.get('jobName', '')
        if 'DFT' not in job_name.upper(): continue
        if any(exp in job.get('periodDesc', '') for exp in excluded_exp): continue
        filtered_jobs.append({
            '公司名稱': job.get('custName', ''), '職位名稱': job_name,
            '工作地點': job.get('jobAddrNoDesc', '') + job.get('jobAddress', ''),
            '薪資範圍': job.get('salaryDesc', ''), '經驗要求': job.get('periodDesc', ''),
            '學歷要求': job.get('optionEdu', ''), '連結': job_link
        })
        seen_links.add(job_link)
    return pd.DataFrame(filtered_jobs)

def csv_to_markdown(csv_file, md_file, title):
    if not os.path.exists(csv_file): return
    df = pd.read_csv(csv_file, encoding='utf-8-sig')
    if df.empty: return
    df['職位名稱'] = df.apply(lambda x: f"[{x['職位名稱']}]({x['連結']})", axis=1)
    df_display = df.drop(columns=['連結'])
    md_table = df_display.to_markdown(index=False)
    with open(md_file, 'w', encoding='utf-8') as f:
        f.write(f"# {title}\n\n更新時間: {pd.Timestamp.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n{md_table}")

if __name__ == "__main__":
    csv_path = './Web_Crawler/104_DFT_Filtered_Jobs.csv'
    md_path = './Web_Crawler/104_DFT_Filtered_Jobs.md'
    # 執行測試，抓取 3 頁
    df = asyncio.run(scrub_104_dft_jobs(pages=3))
    if not df.empty:
        df.to_csv(csv_path, index=False, encoding='utf-8-sig')
        print(f"完成，共取得 {len(df)} 筆職缺。")
        csv_to_markdown(csv_path, md_path, "104 DFT 職缺篩選結果")
    else: print("未抓取到職缺。")
