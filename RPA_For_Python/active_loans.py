from operator import index
from nbformat import read
import rpa as r
import pandas as pd
import os 
import re
import time
import glob 

def clean_up(folder_path):
    files_list= glob.glob(f'{folder_path}{os.sep}*')
    for file in files_list:
        os.remove(file)
    print(f'All files in {folder_path} were deleted!!')

def wait_file(filepath):
    while True:
        file_exists= os.path.isfile(filepath)
        if file_exists is True:
            print(f'{filepath} exists.... ')
            break 
        else:
           time.sleep(3)
folder_path= f'{os.getcwd()}{os.sep}active_loans'
clean_up(folder_path)
r.init()
r.timeout(30)
folder_path= f'{os.getcwd()}{os.sep}active_loans'
r.download_location(folder_path)
r.url('https://botsdna.com/ActiveLoans/')
r.exist('//table')
loans_df= pd.read_excel('input.xlsx',engine='openpyxl')
loans_df[['Bank','Branch','Loan Taken On','Amount','EMI(month)','PAN NUMBER','Status']]=loans_df[['Bank','Branch','Loan Taken On','Amount','EMI(month)','PAN NUMBER','Status']].astype(str)
i=0
for _,row in loans_df.iterrows():
    end_no= str(int(row["AccountNumber"]))[-4:]
    filepath_zip= f'active_loans{os.sep}{str(int(row["AccountNumber"]))}.zip'
    r.click(f'//a[contains(text(),"-{end_no}")]')
    wait_file(filepath_zip)
    r.unzip(filepath_zip,folder_path)
    wait_file(f'{folder_path}{os.sep}{str(int(row["AccountNumber"]))}.txt')
    f1= open(f'{folder_path}{os.sep}{str(int(row["AccountNumber"]))}.txt')
    bank_data= f1.read()
    f1.close()
    loans_df.at[i,'Bank']= re.findall('(?<=Bank:).*',bank_data)[0]
    loans_df.at[i,'Branch']= re.findall('(?<=Branch:).*',bank_data)[0]
    loans_df.at[i,'Loan Taken On']= re.findall('(?<=Loan Taken On:).*',bank_data)[0]
    loans_df.at[i,'Amount']= re.findall('(?<=Amount:).*',bank_data)[0]
    loans_df.at[i,'EMI(month)']= re.findall('(?<=EMI\(month\):).*',bank_data)[0]
    loans_df.at[i,'Status']= r.read(f'//td[2]/a[contains(text(),"{end_no}")]/ancestor::tr/td[1]')
    loans_df.at[i,'PAN NUMBER']= r.read(f'//td[2]/a[contains(text(),"{end_no}")]/ancestor::tr/td[3]')
    i=i+1

loans_df.to_excel('input.xlsx',sheet_name='Loans',index=False)
r.close()  
print('process is completed!!!')  



