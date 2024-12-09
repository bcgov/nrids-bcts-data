**Licence Issued-Advertised-Superquery**

**qLicenceIssuedAdvertised_main** 
- An MS Access SQL query that is used to join the qLicenceIssuedAdvertised_Official (DBP01) query to the qLicenceIssuedAdvertised_LRM (DBP06) query.
- Current runtime 1-5 minutes

**qLicenceIssuedAdvertised_Official**
- Contains date parameters that is manually updated at runtime.
- Sourced from DBP01 (FTA, BCTS Admin)
- Volumes: issued, auctioned, not awarded, category,
- Auction date, issuance dates. 
- Most of the report data comes from this query.
- Everything except:
    - Whether a licence contains fire salvage (Source: qLicenceIssuedAdvertised_LRM)
    - The target volumes (blue bars on Year to Date chart) Source: The target volumes are hard-coded into the spreadsheet and are not contained in a database.
    - The currently in market (yellow bars on Year to Date chart) volumes. Source: qCurrentlyInMarket.


**qLicenceIssuedAdvertised_LRM**
- Source LRM DBP06
- uses FORESTVIEW views:
    - v_licence
    - v_block
    - v_block_activity_all
- Source of Fire salvage (from block activities)

**qCurrentlyInMarket**
- DBP06 query, very slow. (10-20 minutes)
- It uses FORESTVIEW views:
    - v_licence
    - v_block
- as well as a number of FOREST schema tables.
- It contains date parameters that is manually updated at runtime
- The logic in qCurrentlyInMarket is only valid close to or on the report run date. It cannot be used to back-query our data to find out what was posted to BC Bid in the past. This query relies on the Tender Posted licence activity to be set to Done, which is reverted to Planned after an unsuccessful auction, so if the query is run after the activity status has been changed, it will not catch those licences. I envision a dashboard where a user can change and compare reporting periods, for example, to compare the FY25 Q1 to Q2 performance, or to compare the FY25 Q4 to FY24 Q4 performance. Because Currently-In-Market cannot be back-queried, we might want to display ‘currently in market’ in a different dashboard/report than. Alternatively, if we produce snapshot reports, we could look at past Currently In Market values if they are saved.
- There is some nuance in this query that we should talk about before investing lots of work in including it in a dashboard.

- The main information that is important for this report is in the qLicenceIssuedAdvertised_Official (DBP01) query. There would be value in getting this query into the ODS ahead of the components from LRM, for us to work on automating that piece of it, if the LRM components are more complex.

