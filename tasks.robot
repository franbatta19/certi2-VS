*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.PDF
Library             RPA.Desktop
Library             RPA.Tables
Library             RPA.Archive


*** Variables ***
${PDF_RECEIPTS}     ${OUTPUT_DIR}${/}Receipts


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open robot order website
    Download CSV File
    Read CSV File fill, submit and creat PDF
    Create ZIP File


*** Keywords ***
Open robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Dismiss rights message

Dismiss rights message
    Wait Until Page Contains Element    //*[@id="root"]/div/div[2]/div/div/div/div
    Click Element    //*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]

Complete the forms with the data
    [Arguments]    ${linea}
    Select From List By Value    //*[@id="head"]    ${linea}[Head]
    Click Element    id:id-body-${linea}[Body]
    Input Text    css:input[placeholder="Enter the part number for the legs"]    ${linea}[Legs]
    Input Text    id:address    ${linea}[Address]

    # //*[@id="id-body-${linea}[Body]"]

Save preview screenshot
    [Arguments]    ${orderNumber}
    ${screenshot_file}=    Set Variable    ${OUTPUT_DIR}${/}Previews${/}order-${orderNumber}.png
    Click Button    id:preview
    Wait Until Page Contains Element    //*[@id="robot-preview"]/a    5
    Sleep    3s
    Capture Element Screenshot    //*[@id="robot-preview-image"]    ${screenshot_file}
    # Click Element    //*[@id="robot-preview"]/a

Download CSV File
    Download    https://robotsparebinindustries.com/orders.csv    overwrite= True

Read CSV File fill, submit and creat PDF
    ${table}=    Read table from CSV    orders.csv    header=True    delimiters=","

    Log    Found columns: ${table.columns}
    FOR    ${linea}    IN    @{table}
        Log    Datos: ${linea}
        Complete the forms with the data    ${linea}
        Save preview screenshot    ${linea}[Order number]
        Submit Form till succeeds
        Export receipt to PDF    ${linea}
        Embed the robot screenshot to the receipt PDF File
        ...    ${OUTPUT_DIR}${/}Receipts${/}order-${linea}[Order number]-receipt.pdf
        ...    ${OUTPUT_DIR}${/}Previews${/}order-${linea}[Order number].png
        Next Order
        Dismiss rights message
    END

Submit Form
    Click Button    id:order
    Wait Until Page Contains    Thank you for your order!

Submit Form till succeeds
    Wait Until Keyword Succeeds    4x    3 sec    Submit Form

Export receipt to PDF
    [Arguments]    ${linea}
    Wait Until Element Is Visible    id:receipt    10
    ${order_receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${order_receipt_html}    ${OUTPUT_DIR}${/}Receipts${/}order-${linea}[Order number]-receipt.pdf

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${pdf}    ${screenshot}
    ${files}=    Create List    ${pdf}    ${screenshot}
    Open PDF    ${pdf}
    Add Files To Pdf    ${files}    ${pdf}
    Close Pdf    ${pdf}

Next Order
    Click Button    id:order-another

Create ZIP File
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/Receipt_PDFs.zip
    Archive Folder With Zip
    ...    ${PDF_RECEIPTS}
    ...    ${zip_file_name}
