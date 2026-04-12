import json
import asyncio
import random
import pandas as pd
import os
from playwright.async_api import async_playwright

async def scrub_digital_frontend_jobs(pages_per_keyword=3):
    all_jobs_raw = []
    search_keywords = ["Digital IC Design", "數位IC設計", "RTL Design", "Edge AI", "NPU Design", "AI Chip", "AI Accelerator", "Neural Network Processor"]
    
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=False)
        context = await browser.new_context(user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36")
        page = await context.new_page()

        def handle_response(response):
            if "api/jobs" in response.url and response.status == 200:
                async def parse_json():
                    try:
                        data = await response.json()
                        if 'data' in data and isinstance(data['data'], list):
                            job_list = data['data']
                            all_jobs_raw.extend(job_list)
                            print(f"  [攔截] 成功添加 {len(job_list)} 筆職缺。")
                    except: pass
                asyncio.create_task(parse_json())
        page.on("response", handle_response)

        for kw in search_keywords:
            print(f">>> 搜尋核心職缺：{kw}")
            await page.goto(f"https://www.104.com.tw/jobs/search/?keyword={kw}&area=6001005000,6001006000&order=15", wait_until="networkidle")
            for i in range(1, pages_per_keyword + 1):
                print(f"  正在處理第 {i} 頁...")
                
                try:
                    await page.wait_for_selector(".job-summary", timeout=10000)
                except Exception as e:
                    print(f"  [錯誤/警告] 針對關鍵字 '{kw}' 的第 {i} 頁逾時找不到職缺列表。")
                    # === 診斷工具：截圖與原始碼檢索 ===
                    await page.screenshot(path=f"debug_screen_dic.png")
                    content = await page.content()
                    with open(f"debug_source_dic.html", "w", encoding="utf-8") as f:
                        f.write(content)
                    print(f"  [偵錯] 已儲存當前畫面至 debug_screen_dic.png 與原始碼至 debug_source_dic.html")
                    break

                await asyncio.sleep(random.uniform(2, 4))
                await page.evaluate("window.scrollTo(0, document.body.scrollHeight)")
                if i < pages_per_keyword:
                    next_btn = page.locator("button.js-next-page").first
                    if await next_btn.is_visible() and await next_btn.is_enabled():
                        await next_btn.click()
                    else: break
        await asyncio.sleep(2)
        await browser.close()

    # --- 篩選 ---
    exclude_keywords = ["Layout", "佈局", "Analog", "類比", "RF", "FAE", "Support", "測試工程師", "軟體", "Software", "演算法", "Algorithm", "行銷", "業務", "行政", "硬體測試", "工讀生", "兼職", "Intern", "實習", "製程", "封裝", "後端", "Backend", "APR", "Physical Design", "製圖", "Drafting", "機構", "Mechanical", "室內設計", "美工", "Graphic", "Marketing"]
    design_keywords = ["數位", "DIGITAL", "RTL", "IC設計", "DESIGN ENGINEER", "ASIC", "SOC", "LOGIC DESIGN"]
    ai_keywords = ["NPU", "AI", "ACCELERATOR", "EDGE", "INFERENCE", "NEURAL", "DEEP LEARNING", "PROCESSOR", "COMPUTE"]
    excluded_exp = ["3年以上", "4年以上", "5年以上", "6年以上", "7年以上", "8年以上", "9年以上", "10年以上"]

    all_filtered_jobs = []
    seen_links = set()
    for job in all_jobs_raw:
        job_link = f"https:{job['link']['job']}" if 'link' in job and 'job' in job['link'] else ''
        if not job_link or job_link in seen_links: continue
        job_name = job.get('jobName', '')
        is_excluded = any(bad.upper() in job_name.upper() for bad in exclude_keywords)
        is_design = any(k.upper() in job_name.upper() for k in design_keywords)
        is_ai_chip = any(k.upper() in job_name.upper() for k in ai_keywords) and ("IC" in job_name.upper() or "CHIP" in job_name.upper() or "ENGINEER" in job_name.upper())
        if not is_excluded and (is_design or is_ai_chip):
            if not any(exp in job.get('periodDesc', '') for exp in excluded_exp):
                all_filtered_jobs.append({'公司名稱': job.get('custName', ''), '職位名稱': job_name, '薪資範圍': job.get('salaryDesc', ''), '經驗要求': job.get('periodDesc', ''), '連結': job_link})
                seen_links.add(job_link)
    return pd.DataFrame(all_filtered_jobs)

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
    csv_path = './Web_Crawler/104_Digital_Edge_IC_Filtered_Jobs.csv'
    md_path = './Web_Crawler/104_Digital_Edge_IC_Filtered_Jobs.md'
    df_final = asyncio.run(scrub_digital_frontend_jobs(pages_per_keyword=3))
    if not df_final.empty:
        df_final.to_csv(csv_path, index=False, encoding='utf-8-sig')
        print(f"完成，共取得 {len(df_final)} 筆高度相關職缺。")
        csv_to_markdown(csv_path, md_path, "104 Digital IC & Edge AI 職缺篩選結果")
    else: print("未抓取到職缺。")
