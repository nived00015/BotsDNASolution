###This is BOtsDNA usecase solution using rpa for python and pandas module

### Usecase link: https://botsdna.com/locator/

import rpa as r
import pandas as pd
import os
r.init(turbo_mode=True)
r.timeout(30)
r.url('https://botsdna.com/locator/')
r.exist('//table[@style=""]')
r.table('//table[@style=""]','country_details.csv')
r.close()
w= pd.ExcelWriter('country_output.xlsx')
customer_df= pd.read_csv('country_details.csv')
country_details= customer_df.columns[1:]
os.remove('country_details.csv')
for country in country_details:
    country_df= customer_df[[customer_df.columns[0],country]]
    country_df= country_df[country_df[country]!=0]
    country_df.to_excel(w,sheet_name=country,index=False)
    w.save()
print('The process is completed!!!')

