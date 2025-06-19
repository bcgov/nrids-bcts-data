SELECT business_area AS [Business Area], 
Licence, 
iif(Last_Auction_BCTS_Category_Code in ('2', '4'), 'Value Added', '-') AS [Value Added], 
iif(Total_Volume_Salvage_All_Fire_Year_LRM > 0, 'Fire salvage', '-') AS [Includes Fire Salvage], 
Last_Auction_Date AS Auction, 
Format(Last_Auction_No_Sale_Volume, "#,###") AS [Volume (cubic metres)], 
Last_Auction_No_Sale_Rationale AS [No Sale Rationale]
FROM qLicenceIssuedAdvertised_main
WHERE Advertised_in_Report_Period = 'Y'     
and Last_Auction_No_Sale_Rationale is not null     
and Last_Auction_Date         between #05/16/2025#         and #05/31/2025#;



-- Postgres

SELECT 
    business_area AS "Business Area", 
    Licence, 
    CASE 
        WHEN Last_Auction_BCTS_Category_Code IN ('2', '4') THEN 'Value Added' 
        ELSE '-' 
    END AS "Value Added", 
    CASE 
        WHEN Total_Volume_Salvage_All_Fire_Year_LRM > 0 THEN 'Fire salvage' 
        ELSE '-' 
    END AS "Includes Fire Salvage", 
    Last_Auction_Date AS Auction, 
    TO_CHAR(Last_Auction_No_Sale_Volume, 'FM999,999,999') AS "Volume (cubic metres)", 
    Last_Auction_No_Sale_Rationale AS "No Sale Rationale"
FROM 
    qLicenceIssuedAdvertised_main
WHERE 
    Advertised_in_Report_Period = 'Y'     
    AND Last_Auction_No_Sale_Rationale IS NOT NULL     
    AND Last_Auction_Date BETWEEN DATE '2025-05-16' AND DATE '2025-05-31';
