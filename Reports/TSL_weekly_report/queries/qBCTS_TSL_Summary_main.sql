SELECT
    official.Business_Area_Region_Category,
    official.Business_Area_Region,
    official.Business_Area_Code,
    official.Business_Area,
    lrm.LICENCE_ID AS Licence_Number,
    lrm.GEOGRAPHIC_LOCATION,
    lrm.field_team AS Field_Team,
    lrm.species AS Species,
    official.Volume_Advertised_m3,
    official.Volume_ReAdvertised_m3,
    official.last_auction_bcts_category_code AS Auctioned_BCTS_Category_Code,
    official.AUCTION_COUNT_ALL_TIME_TO_REPORT_PERIOD_END AS Total_Auction_Count,
    official.Readvertised_Auction,
    official.Last_Auction_Date AS Auction_Closing_Date,
    official.bidder_COUNT AS Number_of_bidders,
    official.No_Bid,
    official.Upset_Rate_Value AS Upset_Rate_or_Upset_Value,
    official.Bonus_Bid_offer AS Bonus_Bid_or_Bonus_Value,
    official.Upset_Rate_Value + official.Bonus_Bid_offer AS Total_Stumpage_or_Total_Stumpage_Value,
    official.no_bid_info
FROM
    qBCTS_TSL_Summary_LRM AS lrm
    LEFT JOIN qBCTS_TSL_Summary_Official AS official
        ON official.forest_file_id = lrm.LICENCE_ID
ORDER BY
    official.Last_Auction_Date DESC;
