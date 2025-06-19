/* Change from Auction date to bidder_COUNT AS [# of Bidders; qlicenceissuedadvertised_main to qLicenceIssued_detail_main BD 2025-05-14*/
SELECT business_area AS [Business Area],
 Licence, 
 iif(Issued_Licence_BCTS_Category_Code in ('2', '4'), 'Value Added', '-') AS [Value Added], 
 iif(Total_Volume_Salvage_All_Fire_Year_LRM > 0, 'Fire salvage', '-') AS [Includes Fire Salvage],
  bidder_COUNT AS [# of Bidders], 
  Issued_Licence_Legal_Effective_Date AS Issued, 
  Format(Issued_licence_volume, "#,###") AS [Volume (cubic metres)],
   Format(Issued_licence_maximum_value, "$#,###") AS [Max Value],
    Issued_licence_client_name AS Client
FROM qLicenceIssuedAdvertised_main
WHERE Issued_in_report_period = 'Y' and Issued_Licence_Legal_Effective_Date     between #05/16/2025#     and #05/31/2025#;
