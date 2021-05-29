*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library    RPA.Browser.Selenium
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.Archive
Library    OperatingSystem
Library    RPA.Dialogs
Library    RPA.Robocloud.Secrets

*** Variables ***
${SECRET}    %{JSON_SECRET}

*** Keywords ***
Get orders
    Add text input    name=orders    label=Enter the url to orders file    
    ${response}    Run dialog
    Download    ${response.orders}    overwrite=True          
    ${table}=    Read table from CSV    header=True    path=orders.csv   
    [Return]    ${table}

*** Keywords ***
Open the robot order website
    ${secret}    Get Secret    ${SECRET}
    Open Available Browser    ${secret}[URL]

*** Keywords ***
Close the annoying modal
    Click Button When Visible    xpath://*[@id="root"]/div/div[2]/div/div/div/div/div/button[1] 

*** Keywords ***
Fill the form
    [Arguments]    ${row}
    Log    This is row:${row}, This is Legs ${row}[Legs] This is Legs ${row}[Order number]
    Wait Until Element Is Visible    xpath://*[@id="head"]
    Click Element    xpath://*[@id="head"]
    Click Element    xpath://*[@id="head"]/option[@value='${row}[Head]'] 
    Click Element    css:input[id='id-body-${row}[Body]']
    Press Keys    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs] 
    Press Keys    //*[@id="address"]    ${row}[Address]
    
*** Keywords ***
Preview the robot
    Click Element    xpath://*[@id="preview"]
    Sleep    2s

*** Keywords ***
Submit the order
    FOR    ${i}    IN RANGE    9999999
        Click Element    xpath://*[@id="order"]
        ${order_status}    Run Keyword And Return Status    Element Should Be Visible     css:div[id="receipt"]    
        Exit For Loop If    ${order_status}==True
    END
    
*** Keywords ***
Store the receipt as a PDF file
    [Arguments]    ${order number}
    Wait Until Element Is Visible    css:div[id="receipt"]    
    ${reciept}     Get Element Attribute    css:div[id="receipt"]    outerHTML
    Sleep    2s
    Html To Pdf    ${reciept}   output/receipts/${order number}.pdf
    ${pdf}    Join Path    output    receipts    ${order number}.pdf
    [Return]    ${pdf}   

*** Keywords ***
Take a screenshot of the robot
    [Arguments]    ${order number}
    ${screenshot}    Capture Element Screenshot    xpath://*[@id="robot-preview-image"]    screenshots/${order number}.png
    [Return]    ${screenshot}

*** Keywords ***    
Embed the robot screenshot to the receipt PDF file 
       [Arguments]    ${screenshot}    ${pdf}
       ${files}    Create List    ${screenshot}    ${pdf}
       Add Files To Pdf    ${files}    ${pdf}   

*** Keywords ***   
Go to order another robot
    Click Element    xpath://*[@id="order-another"]

*** Keywords ***   
Create a ZIP file of the receipts
    Archive Folder With Zip    output/receipts    output/receipts.zip
    

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]        
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts