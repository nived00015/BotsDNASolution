*** Settings ***
Documentation       Robot for creating server details
Library             RPA.Browser
Library             RPA.Excel.Files
Library             RPA.core.notebook
Library             String 
Library             RPA.Email.ImapSmtp
Library             RPA.Robocorp.Vault
Library             RPA.FileSystem


*** Variables ***
#${table}
*** Keywords ***
init process
    Set Selenium Timeout  30 seconds 




***Keywords***
Open Browser
    [Arguments]  ${url}
    Open Available Browser  ${url}
    Maximize Browser Window
    Wait Until Page Contains Element   //h1[contains(text(),"Server Creation")] 
    Log  Logged into server creation website....
    

*** Keywords ***
Open Excel and read table  
    [Arguments]  ${file}
    Open Workbook  ${file} 
    ${table}=  Read Worksheet As Table  header=True  trim=True
    Log  Read excel file.
    [Return]  ${table}

*** Keywords ***
Close Server Setup website 
    Close All Browsers
    Log  Closed browser successfully!


Create Server
    [Arguments]  ${row}
    ${os}=  Strip String  ${row}[OS] 
    ${ram}=  Strip String  ${row}[RAM]
    ${HDD}=  Strip String  ${row}[HDD]
    Select From List By Label  //select[@name="os"]  ${os}
    Select From List By Label  //select[@name='Ram']  ${ram}
    Click Element  //label[@for='hdd' and text()='${HDD}']/preceding::input[@type='radio'][1]
    ${str}=  Convert To String  ${row}[Applications]
    ${applications_list}=  Split String  ${str}  ,
    FOR    ${i}    IN    @{applications_list}
        ${i}=  Strip String  ${i}
        Click Element  //label[contains(text(),"${i}")]/preceding::input[@type='checkbox'][1]        
    END
    ${counter}=  Set Variable  ${0}
    ${success}=  Set Variable  ${False}
    Click Button  //input[@value="Create Server"]
    WHILE  ${counter}<3
        TRY    
            Wait Until Element Is Visible  //td[contains(text(),"IP Address")]
            ${ip_address}=  Get Text  //td[contains(text(),"IP Address")]/following::td[1]
            ${username}=  Get Text  //td[contains(text(),"User Name")]/following::td[1]
            ${password}=  Get Text  //td[contains(text(),"Password")]/following::td[1]
            ${success}=  Set Variable  ${True}
            Notebook Print  ${ip_address} ${username} ${password}
            ${counter}=  Set Variable  ${3}
        EXCEPT
            ${counter}=  Set Variable  ${${counter}+${1}}    
        END    
    END
    IF    ${success} == ${False}
        Fail  Failed to obtain the server details after creation.
    Log  Server successfully created and information extracted    
    END
    [Return]  ${ip_address}  ${username}  ${password}

    
*** Keywords ***
Email User
    [Arguments]  ${email}  ${ip_address}  ${username}  ${password}
    ${email_credentials}=  Get Secret  email_credentials
    Authorize Smtp  ${email_credentials}[Email]  ${email_credentials}[Password]  smtp.gmail.com  587
    ${email_body}=  Read File  ${CURDIR}${/}Email_Body.txt  
    ${email_body}=  Replace String  ${email_body}  [ip_address]  ${ip_address}
    ${email_body}=  Replace String  ${email_body}  [username]  ${username}
    ${email_body}=  Replace String  ${email_body}  [password]  ${password}
    Send Message  ${email_credentials}[Email]  ${email}  Server Created-RPA  ${email_body}  html=True




    



*** Tasks ***
Main Tasks
    init process 
    ${server_table}=  Open Excel and read table  ${CURDIR}${/}server-setup-details.xlsx 
    Open Browser  https://botsdna.com/server/
    ${transaction_no}=  Set Variable  ${1}
    FOR    ${row}    IN    @{server_table}
        TRY    
            Log  Transaction ${transaction_no} starts processing    
            Log  server creating.....
            ${ip_address}  ${username}  ${password}=  Create Server  ${row}
            Log  ${ip_address}---${username}---${password}
            Log  Sending Email.....
            Email User  ${row}[EmailID]  ${ip_address}  ${username}  ${password} 
            Go To  https://botsdna.com/server/
            Wait Until Page Contains Element   //h1[contains(text(),"Server Creation")]         
            Log  Transaction ${transaction_no} is Successfull
        EXCEPT  AS  ${error_msg}
            Log  Transaction ${transaction_no} is Failed.
            Log  ${error_msg} 
            Go To  https://botsdna.com/server/
            Wait Until Page Contains Element   //h1[contains(text(),"Server Creation")]
        FINALLY  
            ${transaction_no}=  Set Variable  ${${transaction_no}+${1}}    
        END
    END

    Log  Exiting website
    Close Server Setup website
